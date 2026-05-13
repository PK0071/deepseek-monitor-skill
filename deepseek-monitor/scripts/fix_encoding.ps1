$file = Join-Path $PSScriptRoot "TokenMonitor.ps1"
$text = @'
<#
DeepSeek Usage Monitor - 与后台数据完全一致
Source: platform.deepseek.com API
#>

param([switch]$Demo)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configIni = Join-Path $scriptDir "config.ini"

# Read config
$cfg = @{ api_key = ''; platform_token = '' }
if (Test-Path $configIni) {
    foreach ($line in Get-Content $configIni -Encoding UTF8) {
        if ($line -match '^\s*api_key\s*=\s*(.+)\s*$') {
            $v = $Matches[1].Trim()
            if ($v -ne 'YOUR_API_KEY_HERE') { $cfg.api_key = $v }
        }
        if ($line -match '^\s*platform_token\s*=\s*(.+)\s*$') {
            $v = $Matches[1].Trim()
            if ($v -ne 'YOUR_PLATFORM_TOKEN_HERE') { $cfg.platform_token = $v }
        }
    }
}

# State
$script:balance_cny = 0.0
$script:session_start = $null
$script:in = 0L; $script:out = 0L; $script:cache = 0L; $script:total_m = 0L
$script:status = 'waiting'

# Fetch balance
function Fetch-Balance {
    if (-not $cfg.api_key) { return }
    try {
        $r = Invoke-RestMethod "https://api.deepseek.com/user/balance" `
            -Headers @{ Authorization = "Bearer $($cfg.api_key)" } -TimeoutSec 10
        if ($r.is_available -and $r.balance_infos) {
            $cny = 0.0
            foreach ($bi in $r.balance_infos) {
                if ($bi.currency -eq 'CNY') { $cny += [double]$bi.total_balance }
            }
            $script:balance_cny = $cny
            if ($null -eq $script:session_start) { $script:session_start = $cny }
            $script:status = 'ok'
        }
    } catch { $script:status = 'error' }
}

# Fetch usage from platform dashboard
function Fetch-Usage {
    if (-not $cfg.platform_token) { $script:status = 'error'; return }
    $m = (Get-Date).Month; $y = (Get-Date).Year
    $url = "https://platform.deepseek.com/api/v0/usage/amount?month=$m&year=$y"
    try {
        $r = Invoke-RestMethod $url -Method Get -Headers @{
            authorization = "Bearer $($cfg.platform_token)"
            accept = "*/*"
            referer = "https://platform.deepseek.com/usage"
            "x-app-version" = "1.0.0"
        } -TimeoutSec 10

        $today = Get-Date -Format 'yyyy-MM-dd'
        $day = $r.data.biz_data.days | Where-Object { $_.date -eq $today }
        $totalData = $r.data.biz_data.total

        $in = 0L; $out = 0L; $cache = 0L; $total_in = 0L; $total_out = 0L; $total_cache = 0L

        # Today
        if ($day) {
            foreach ($me in $day.data) {
                $model = "$($me.model)".ToLower()
                if ($model -match 'deepseek-v4-pro|deepseek-v4-flash') {
                    foreach ($u in $me.usage) {
                        $amt = [long]$u.amount
                        switch ($u.type) {
                            'PROMPT_CACHE_HIT_TOKEN'  { $cache += $amt }
                            'PROMPT_CACHE_MISS_TOKEN' { $in += $amt }
                            'RESPONSE_TOKEN'          { $out += $amt }
                        }
                    }
                }
            }
        }

        # Monthly total
        foreach ($me in $totalData) {
            $model = "$($me.model)".ToLower()
            if ($model -match 'deepseek-v4-pro|deepseek-v4-flash') {
                foreach ($u in $me.usage) {
                    $amt = [long]$u.amount
                    switch ($u.type) {
                        'PROMPT_CACHE_HIT_TOKEN'  { $total_cache += $amt }
                        'PROMPT_CACHE_MISS_TOKEN' { $total_in += $amt }
                        'RESPONSE_TOKEN'          { $total_out += $amt }
                    }
                }
            }
        }

        $script:in = $in; $script:out = $out; $script:cache = $cache
        $script:total_m = $total_in + $total_out
        $script:status = 'ok'
    } catch { $script:status = 'error' }
}

function Get-Summary {
    $start = $script:session_start
    $bal = $script:balance_cny
    if ($null -eq $start) { $start = $bal }
    $spent = if ($start -gt $bal) { $start - $bal } else { 0.0 }
    return @{
        balance = $bal
        spent   = $spent
        today_in    = $script:in
        today_out   = $script:out
        today_cache = $script:cache
        today_total = $script:in + $script:out + $script:cache
        month_total = $script:total_m
    }
}

# === UI ===
Add-Type -AssemblyName PresentationFramework, WindowsBase, System.Windows.Forms

$w = New-Object System.Windows.Window
$w.Title = "DeepSeek"; $w.WindowStyle = "None"; $w.AllowsTransparency = $true
$w.Topmost = $true; $w.Background = "#E51e1e2e"; $w.Width = 280; $w.Height = 170
$w.WindowStartupLocation = "CenterScreen"

$g = New-Object System.Windows.Controls.Grid
$g.Margin = "12,8,12,8"
@("Auto","10","Auto","Auto","Auto","Auto","Auto") | ForEach-Object {
    $rd = New-Object System.Windows.Controls.RowDefinition
    $rd.Height = $_; $rd.MinHeight = if ($_ -eq "10") { 10 } else { 18 }
    $g.RowDefinitions.Add($rd)
}

function TB($text, $fg, $size, $bold, $ha, $row) {
    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $text; $t.Foreground = $fg; $t.FontFamily = "Consolas"
    $t.FontSize = $size; if ($bold) { $t.FontWeight = "Bold" }
    $t.HorizontalAlignment = $ha
    if ($row -ge 0) { [System.Windows.Controls.Grid]::SetRow($t, $row) }
    $g.AddChild($t); return $t
}

# Title bar
$tb = New-Object System.Windows.Controls.Grid
[System.Windows.Controls.Grid]::SetRow($tb, 0)
@("20","*","20") | ForEach-Object {
    $c = New-Object System.Windows.Controls.ColumnDefinition; $c.Width = $_; $tb.ColumnDefinitions.Add($c)
}
$tt = New-Object System.Windows.Controls.TextBlock
$tt.Text = "DeepSeek 用量监控"; $tt.Foreground = "#cdd6f4"
$tt.FontFamily = "Consolas"; $tt.FontSize = 9; $tt.FontWeight = "Bold"
$tt.HorizontalAlignment = "Center"
[System.Windows.Controls.Grid]::SetColumn($tt, 1); $tb.AddChild($tt) | Out-Null

$xx = New-Object System.Windows.Controls.TextBlock
$xx.Text = "x"; $xx.Foreground = "#f38ba8"; $xx.FontFamily = "Consolas"
$xx.FontSize = 11; $xx.FontWeight = "Bold"; $xx.HorizontalAlignment = "Right"
$xx.VerticalAlignment = "Center"; $xx.Cursor = "Hand"; $xx.ToolTip = "Close"
[System.Windows.Controls.Grid]::SetColumn($xx, 2)
$xx.Add_MouseLeftButtonDown({ $w.Close() }); $tb.AddChild($xx) | Out-Null
$g.AddChild($tb) | Out-Null

# Divider
$d = New-Object System.Windows.Shapes.Rectangle
$d.Height = 1; $d.Fill = "#45475a"; [System.Windows.Controls.Grid]::SetRow($d, 1); $g.AddChild($d)

# Data rows
function AR($row, $label, $color, $def) {
    TB $label $color 10 $false "Left" $row | Out-Null
    $v = TB $def $color 10 $true "Right" $row; return $v
}
$lblBal   = AR 2 "Balance:"      "#a6e3a1" "0.00 CNY"
$lblIn    = AR 3 "In(miss):"     "#89b4fa" "0"
$lblOut   = AR 4 "Out:"          "#cba6f7" "0"
$lblCache = AR 5 "In(hit):"      "#f9e2af" "0"
$lblTotal = AR 6 "Today:"        "#cdd6f4" "0"

$w.Content = $g

# Drag, menu, keys
$w.Add_MouseLeftButtonDown({ $w.DragMove() })
$mnu = New-Object System.Windows.Controls.ContextMenu
$mr = New-Object System.Windows.Controls.MenuItem; $mr.Header = "Refresh"
$mr.Add_Click({ Refresh-All; Update-Display }); $mnu.Items.Add($mr) | Out-Null
$mt = New-Object System.Windows.Controls.MenuItem; $mt.Header = "Always on Top"
$mt.IsCheckable = $true; $mt.IsChecked = $true
$mt.Add_Click({ $w.Topmost = $mt.IsChecked }); $mnu.Items.Add($mt) | Out-Null
$mnu.Items.Add((New-Object System.Windows.Controls.Separator)) | Out-Null
$mx = New-Object System.Windows.Controls.MenuItem; $mx.Header = "Exit"
$mx.Add_Click({ $w.Close() }); $mnu.Items.Add($mx) | Out-Null
$w.ContextMenu = $mnu
$w.Add_KeyDown({ param($s,$e) if ($e.Key -eq 'Escape') { $w.Close() } })

function Update-Display {
    $s = Get-Summary
    $lblBal.Text   = "{0:F2} CNY" -f $s.balance
    $lblIn.Text    = "{0:N0}" -f $s.today_in
    $lblOut.Text   = "{0:N0}" -f $s.today_out
    $lblCache.Text = "{0:N0}" -f $s.today_cache
    $lblTotal.Text = "{0:N0}" -f $s.today_total
}

function Refresh-All { Fetch-Balance; Fetch-Usage }

$timer = New-Object System.Timers.Timer
$timer.Interval = 30000; $timer.AutoReset = $true
$timer.add_Elapsed({
    Refresh-All
    try { $w.Dispatcher.Invoke({ Update-Display }) } catch {}
})

if ($Demo) {
    # Demo data from 2026-05-13 dashboard
    $script:balance_cny = 82.50; $script:session_start = 100.00
    $script:in = 144096L; $script:out = 79059L; $script:cache = 9437312L
    $script:total_m = ($script:in + $script:out + $script:cache); $script:status = 'ok'
}

Refresh-All; Update-Display
$w.Add_Closing({ $timer.Stop() }); $timer.Start()
$null = $w.ShowDialog()
'@

[System.IO.File]::WriteAllText($file, $text, [System.Text.UTF8Encoding]::new($true))
Write-Host "Saved TokenMonitor.ps1 with UTF-8 BOM"
