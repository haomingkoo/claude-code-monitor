# ============================================================
# Claude Code Usage Monitor - Windows System Tray
# ============================================================
# A lightweight system tray app that shows Claude Code rate
# limits in real time. No dependencies beyond PowerShell 5.1+
# and .NET Framework (both ship with Windows 10/11).
#
# Usage: Double-click claude-code-monitor.exe
#        Or: powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File claude-code-monitor.ps1
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
# CONFIG
# ============================================================
$script:CacheDir  = Join-Path $env:USERPROFILE ".cache\claude-usage"
$script:CacheFile = Join-Path $script:CacheDir "usage.json"
$script:LogFile   = Join-Path $script:CacheDir "monitor.log"
$script:CacheTTL  = 120          # seconds
$script:PollInterval = 60        # seconds between refresh cycles

if (-not (Test-Path $script:CacheDir)) {
    New-Item -ItemType Directory -Path $script:CacheDir -Force | Out-Null
}

# ============================================================
# LOGGING
# ============================================================
function Write-Log {
    param([string]$Level, [string]$Message)
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$ts [$Level] $Message"
    Add-Content -Path $script:LogFile -Value $line -ErrorAction SilentlyContinue

    # Trim log to 200 lines
    if (Test-Path $script:LogFile) {
        $lines = Get-Content $script:LogFile -ErrorAction SilentlyContinue
        if ($lines -and $lines.Count -gt 200) {
            $lines[-100..-1] | Set-Content $script:LogFile -ErrorAction SilentlyContinue
        }
    }
}

Write-Log "INFO" "Monitor started"

# ============================================================
# AUTH
# ============================================================
function Get-OAuthToken {
    $credFile = Join-Path $env:USERPROFILE ".claude\.credentials.json"
    if (-not (Test-Path $credFile)) {
        Write-Log "ERROR" "Credentials file not found: $credFile"
        return $null
    }
    try {
        $creds = Get-Content $credFile -Raw | ConvertFrom-Json
        $token = $creds.claudeAiOauth.accessToken
        if ([string]::IsNullOrEmpty($token)) {
            Write-Log "ERROR" "accessToken is empty"
            return $null
        }
        $script:SubscriptionType = $creds.claudeAiOauth.subscriptionType
        return $token
    } catch {
        Write-Log "ERROR" "Failed to parse credentials: $_"
        return $null
    }
}

# ============================================================
# FETCH USAGE (WITH CACHE)
# ============================================================
function Get-Usage {
    # Check cache freshness
    if (Test-Path $script:CacheFile) {
        $cacheAge = ((Get-Date) - (Get-Item $script:CacheFile).LastWriteTime).TotalSeconds
        if ($cacheAge -lt $script:CacheTTL) {
            Write-Log "INFO" "Using cache (age: $([int]$cacheAge)s)"
            $script:FetchStatus = "cached ($([int]$cacheAge)s ago)"
            return (Get-Content $script:CacheFile -Raw | ConvertFrom-Json)
        }
    }

    $token = Get-OAuthToken
    if (-not $token) {
        $script:FetchStatus = "no auth"
        return $null
    }

    try {
        $headers = @{
            "Accept"           = "application/json"
            "Content-Type"     = "application/json"
            "Authorization"    = "Bearer $token"
            "anthropic-beta"   = "oauth-2025-04-20"
        }
        $response = Invoke-WebRequest -Uri "https://api.anthropic.com/api/oauth/usage" `
            -Headers $headers -Method Get -TimeoutSec 10 -UseBasicParsing

        if ($response.StatusCode -eq 200) {
            $response.Content | Set-Content $script:CacheFile -Force
            $script:FetchStatus = "live"
            Write-Log "INFO" "API call success"
            return ($response.Content | ConvertFrom-Json)
        }
    } catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode -eq 429) {
            Write-Log "WARN" "Rate limited (429) - using stale cache"
            $script:FetchStatus = "rate limited - stale data"
        } else {
            Write-Log "ERROR" "API error (HTTP $statusCode): $_"
            $script:FetchStatus = "error (HTTP $statusCode) - stale data"
        }

        # Fall back to stale cache
        if (Test-Path $script:CacheFile) {
            return (Get-Content $script:CacheFile -Raw | ConvertFrom-Json)
        }
        return $null
    }
}

# ============================================================
# ICON RENDERING
# ============================================================
# We need to properly destroy old icons to avoid GDI handle leaks.
# Store the Win32 handle so we can call DestroyIcon on it.
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class IconHelper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyIcon(IntPtr hIcon);
}
"@ -ErrorAction SilentlyContinue

$script:CurrentIconHandle = [IntPtr]::Zero

function New-TrayIcon {
    param([int]$Percent, [string]$ColorTier)

    $bmp = New-Object System.Drawing.Bitmap(16, 16)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)

    $color = switch ($ColorTier) {
        "green"  { [System.Drawing.Color]::FromArgb(46, 204, 113) }
        "orange" { [System.Drawing.Color]::FromArgb(230, 126, 34) }
        "red"    { [System.Drawing.Color]::FromArgb(231, 76, 60) }
        default  { [System.Drawing.Color]::Gray }
    }

    # Draw a progress ring — arc length reflects remaining %
    # Background track (dim)
    $bgPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(60, 60, 60), 2)
    $g.DrawEllipse($bgPen, 2, 2, 12, 12)
    $bgPen.Dispose()

    # Foreground arc — starts at top (-90 deg), sweeps clockwise by percent
    if ($Percent -gt 0) {
        $sweepAngle = [int](360 * $Percent / 100)
        $pen = New-Object System.Drawing.Pen($color, 2)
        $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
        $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
        $g.DrawArc($pen, 2, 2, 12, 12, -90, $sweepAngle)
        $pen.Dispose()
    }

    $g.Dispose()

    # Destroy the previous icon handle to prevent GDI leak
    if ($script:CurrentIconHandle -ne [IntPtr]::Zero) {
        [IconHelper]::DestroyIcon($script:CurrentIconHandle) | Out-Null
        $script:CurrentIconHandle = [IntPtr]::Zero
    }

    $hIcon = $bmp.GetHicon()
    $script:CurrentIconHandle = $hIcon
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    $bmp.Dispose()
    return $icon
}

# ============================================================
# HELPERS
# ============================================================
function Get-ColorTier {
    param([double]$Remaining)
    if ($Remaining -le 20) { return "red" }
    elseif ($Remaining -le 50) { return "orange" }
    else { return "green" }
}

function Get-StatusEmoji {
    param([string]$Tier)
    switch ($Tier) {
        "green"  { return [char]::ConvertFromUtf32(0x1F7E2) }
        "orange" { return [char]::ConvertFromUtf32(0x1F7E1) }
        "red"    { return [char]::ConvertFromUtf32(0x1F534) }
    }
}

function Format-ResetTime {
    param([string]$ResetTs)
    if ([string]::IsNullOrEmpty($ResetTs) -or $ResetTs -eq "null") { return "" }
    try {
        $resetTime = [DateTimeOffset]::Parse($ResetTs).UtcDateTime
        $diff = $resetTime - [DateTime]::UtcNow
        if ($diff.TotalSeconds -le 0) { return "" }
        if ($diff.Days -gt 0) { return "$($diff.Days)d $($diff.Hours)h" }
        elseif ($diff.Hours -gt 0) { return "$($diff.Hours)h $($diff.Minutes)m" }
        else { return "$($diff.Minutes)m" }
    } catch { return "" }
}

function Format-ProgressBar {
    param([int]$Percent)
    $width = 20
    $filled = [Math]::Floor($Percent * $width / 100)
    $empty = $width - $filled
    return ("$([char]0x25A0)" * $filled) + ("$([char]0x25A1)" * $empty)
}

# ============================================================
# DISPLAY UPDATE
# ============================================================
function Update-Display {
    try {
        $usage = Get-Usage
        if (-not $usage) {
            $script:NotifyIcon.Text = "Claude Code: No data"
            Set-TrayIcon -Percent 0 -ColorTier "red"
            Update-ContextMenu $null
            return
        }

        # Parse usage data
        $fiveHrUsed   = [double]($usage.five_hour.utilization)
        $fiveHrReset  = $usage.five_hour.resets_at
        $sevenDayUsed = [double]($usage.seven_day.utilization)
        $sevenDayReset = $usage.seven_day.resets_at

        $fiveHrLeft   = [Math]::Round(100 - $fiveHrUsed, 1)
        $sevenDayLeft = [Math]::Round(100 - $sevenDayUsed, 1)

        $fiveColor = Get-ColorTier $fiveHrLeft
        $sevenColor = Get-ColorTier $sevenDayLeft

        # Opus (optional)
        $opusLeft = $null
        $opusReset = $null
        $opusColor = $null
        if ($usage.seven_day_opus -and $usage.seven_day_opus.utilization) {
            $opusUsed = [double]($usage.seven_day_opus.utilization)
            $opusLeft = [Math]::Round(100 - $opusUsed, 1)
            $opusReset = $usage.seven_day_opus.resets_at
            $opusColor = Get-ColorTier $opusLeft
        }

        # Update tray icon (based on 5-hour session)
        Set-TrayIcon -Percent ([int]$fiveHrLeft) -ColorTier $fiveColor

        # Tooltip (max 63 chars)
        $tooltip = "5h: $([int]$fiveHrLeft)% | 7d: $([int]$sevenDayLeft)%"
        if ($opusLeft -ne $null) { $tooltip += " | Opus: $([int]$opusLeft)%" }
        $script:NotifyIcon.Text = $tooltip

        Write-Log "INFO" "5h: ${fiveHrLeft}% | 7d: ${sevenDayLeft}% | src: $($script:FetchStatus)"

        # Update context menu
        Update-ContextMenu @{
            FiveHrLeft    = $fiveHrLeft
            FiveColor     = $fiveColor
            FiveReset     = $fiveHrReset
            SevenDayLeft  = $sevenDayLeft
            SevenColor    = $sevenColor
            SevenReset    = $sevenDayReset
            OpusLeft      = $opusLeft
            OpusColor     = $opusColor
            OpusReset     = $opusReset
        }
    } catch {
        Write-Log "ERROR" "Update-Display failed: $_"
    }
}

# Wrapper to safely set tray icon with proper disposal
function Set-TrayIcon {
    param([int]$Percent, [string]$ColorTier)
    $newIcon = New-TrayIcon -Percent $Percent -ColorTier $ColorTier
    $script:NotifyIcon.Icon = $newIcon
}

# ============================================================
# CONTEXT MENU (right-click details)
# ============================================================
# Pre-create reusable fonts to avoid GDI leaks
$script:FontBold    = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$script:FontMono    = New-Object System.Drawing.Font("Consolas", 9)

function Update-ContextMenu {
    param($Data)

    # Dispose old menu before creating new one
    if ($script:NotifyIcon.ContextMenuStrip) {
        $script:NotifyIcon.ContextMenuStrip.Dispose()
    }

    $menu = New-Object System.Windows.Forms.ContextMenuStrip
    $menu.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System

    $subType = if ($script:SubscriptionType) { $script:SubscriptionType } else { "unknown" }
    $header = $menu.Items.Add("Claude Code ($subType)")
    $header.Enabled = $false
    $header.Font = $script:FontBold
    $menu.Items.Add("-") | Out-Null

    if ($Data) {
        # 5-Hour Session
        $fiveEmoji = Get-StatusEmoji $Data.FiveColor
        $menu.Items.Add("$fiveEmoji  5-Hour Session").Enabled = $false
        $bar5 = Format-ProgressBar ([int]$Data.FiveHrLeft)
        $barItem5 = $menu.Items.Add("  $bar5")
        $barItem5.Enabled = $false
        $barItem5.Font = $script:FontMono
        $menu.Items.Add("  $([int]$Data.FiveHrLeft)% remaining").Enabled = $false
        $resetStr5 = Format-ResetTime $Data.FiveReset
        if ($resetStr5) { $menu.Items.Add("  Refills in $resetStr5").Enabled = $false }

        $menu.Items.Add("-") | Out-Null

        # 7-Day Window
        $sevenEmoji = Get-StatusEmoji $Data.SevenColor
        $menu.Items.Add("$sevenEmoji  7-Day Window").Enabled = $false
        $bar7 = Format-ProgressBar ([int]$Data.SevenDayLeft)
        $barItem7 = $menu.Items.Add("  $bar7")
        $barItem7.Enabled = $false
        $barItem7.Font = $script:FontMono
        $menu.Items.Add("  $([int]$Data.SevenDayLeft)% remaining").Enabled = $false
        $resetStr7 = Format-ResetTime $Data.SevenReset
        if ($resetStr7) { $menu.Items.Add("  Refills in $resetStr7").Enabled = $false }

        # Opus (if available)
        if ($Data.OpusLeft -ne $null) {
            $menu.Items.Add("-") | Out-Null
            $opusEmoji = Get-StatusEmoji $Data.OpusColor
            $menu.Items.Add("$opusEmoji  7-Day Opus").Enabled = $false
            $barO = Format-ProgressBar ([int]$Data.OpusLeft)
            $barItemO = $menu.Items.Add("  $barO")
            $barItemO.Enabled = $false
            $barItemO.Font = $script:FontMono
            $menu.Items.Add("  $([int]$Data.OpusLeft)% remaining").Enabled = $false
            $resetStrO = Format-ResetTime $Data.OpusReset
            if ($resetStrO) { $menu.Items.Add("  Refills in $resetStrO").Enabled = $false }
        }

        $menu.Items.Add("-") | Out-Null
        $srcItem = $menu.Items.Add("Source: $($script:FetchStatus)")
        $srcItem.Enabled = $false
    } else {
        $menu.Items.Add("No data available").Enabled = $false
    }

    $menu.Items.Add("-") | Out-Null

    # Refresh button
    $refreshItem = $menu.Items.Add("Refresh Now")
    $refreshItem.Add_Click({
        $script:CacheTTL = 0
        Update-Display
        $script:CacheTTL = 120
    })

    # Open log
    $logItem = $menu.Items.Add("Open Log")
    $logItem.Add_Click({
        if (Test-Path $script:LogFile) {
            Start-Process notepad.exe $script:LogFile
        }
    })

    $menu.Items.Add("-") | Out-Null

    # Exit
    $exitItem = $menu.Items.Add("Exit")
    $exitItem.Add_Click({
        $script:Timer.Stop()
        $script:Timer.Dispose()
        $script:NotifyIcon.Visible = $false
        $script:NotifyIcon.Dispose()
        $script:FontBold.Dispose()
        $script:FontMono.Dispose()
        if ($script:CurrentIconHandle -ne [IntPtr]::Zero) {
            [IconHelper]::DestroyIcon($script:CurrentIconHandle) | Out-Null
        }
        [System.Windows.Forms.Application]::Exit()
    })

    $script:NotifyIcon.ContextMenuStrip = $menu
}

# ============================================================
# MAIN - SYSTEM TRAY SETUP
# ============================================================

# Prevent multiple instances
$mutexName = "ClaudeCodeMonitor_SingleInstance"
$script:Mutex = New-Object System.Threading.Mutex($false, $mutexName)
if (-not $script:Mutex.WaitOne(0, $false)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Claude Code Monitor is already running.`nCheck your system tray.",
        "Claude Code Monitor",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    exit
}

# Create NotifyIcon
$script:NotifyIcon = New-Object System.Windows.Forms.NotifyIcon
$script:NotifyIcon.Text = "Claude Code Monitor - Loading..."
$script:NotifyIcon.Icon = New-TrayIcon -Percent 0 -ColorTier "green"
$script:NotifyIcon.Visible = $true
$script:SubscriptionType = ""
$script:FetchStatus = ""

# Initial fetch
Update-Display

# Timer for periodic refresh
$script:Timer = New-Object System.Windows.Forms.Timer
$script:Timer.Interval = $script:PollInterval * 1000
$script:Timer.Add_Tick({ Update-Display })
$script:Timer.Start()

# Run the message loop
[System.Windows.Forms.Application]::Run()

# Cleanup (runs after Application.Exit)
try {
    $script:Mutex.ReleaseMutex()
} catch {}
$script:Mutex.Dispose()
