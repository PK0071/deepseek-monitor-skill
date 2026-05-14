param([switch]$Demo)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configIni = Join-Path $scriptDir "config.ini"

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

function Cost-CNY($model, $type, $tokens) {
    $m = [double]$tokens / 1000000.0
    if ($model -match 'v4-pro') {
        switch ($type) {
            'cache_hit'  { return $m * 0.025 }; 'cache_miss' { return $m * 3.00 }
            'output'     { return $m * 6.00  }
        }
    } elseif ($model -match 'v4-flash') {
        switch ($type) {
            'cache_hit'  { return $m * 0.02 }; 'cache_miss' { return $m * 1.00 }
            'output'     { return $m * 2.00 }
        }
    }
    return 0.0
}

function Parse-DayTokens($dayData) {
    $p = @(0L, 0L, 0L); $f = @(0L, 0L, 0L)
    if (-not $dayData) { return $p + $f }
    foreach ($me in $dayData.data) {
        $model = "$($me.model)".ToLower()
        $arr = $null
        if ($model -match 'deepseek-v4-pro') { $arr = $p }
        elseif ($model -match 'deepseek-v4-flash') { $arr = $f }
        if ($arr) {
            foreach ($u in $me.usage) {
                $amt = [long]$u.amount
                switch ($u.type) {
                    'PROMPT_CACHE_HIT_TOKEN'  { $arr[0] += $amt }
                    'PROMPT_CACHE_MISS_TOKEN' { $arr[1] += $amt }
                    'RESPONSE_TOKEN'          { $arr[2] += $amt }
                }
            }
        }
    }
    return $p + $f
}

$script:balance_cny = 0.0; $script:session_start = $null
$script:pro = @(0L, 0L, 0L); $script:flash = @(0L, 0L, 0L)
$script:yest_total = 0L
$script:month_cost = 0.0
$script:status = 'waiting'

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
        $yesterday = (Get-Date).AddDays(-1).ToString('yyyy-MM-dd')
        $days = $r.data.biz_data.days
        $todayDay = $days | Where-Object { $_.date -eq $today }
        $yestDay = $days | Where-Object { $_.date -eq $yesterday }
        $totalData = $r.data.biz_data.total

        $tokens = Parse-DayTokens $todayDay
        $script:pro = $tokens[0..2]; $script:flash = $tokens[3..5]

        $yt = Parse-DayTokens $yestDay
        $script:yest_total = $yt[0] + $yt[1] + $yt[2] + $yt[3] + $yt[4] + $yt[5]

        $month_cost = 0.0
        foreach ($me in $totalData) {
            $model = "$($me.model)".ToLower()
            if ($model -match 'deepseek-v4-pro|deepseek-v4-flash') {
                foreach ($u in $me.usage) {
                    $amt = [long]$u.amount
                    switch ($u.type) {
                        'PROMPT_CACHE_HIT_TOKEN'  { $month_cost += (Cost-CNY $model 'cache_hit' $amt) }
                        'PROMPT_CACHE_MISS_TOKEN' { $month_cost += (Cost-CNY $model 'cache_miss' $amt) }
                        'RESPONSE_TOKEN'          { $month_cost += (Cost-CNY $model 'output' $amt) }
                    }
                }
            }
        }
        $script:month_cost = $month_cost
        $script:status = 'ok'
    } catch { $script:status = 'error' }
}

function Get-Summary {
    $start = $script:session_start; $bal = $script:balance_cny
    if ($null -eq $start) { $start = $bal }
    $today = $script:pro[0]+$script:pro[1]+$script:pro[2] + $script:flash[0]+$script:flash[1]+$script:flash[2]
    $yest = $script:yest_total
    $cmp = ''; $arrow = ''; $arrowColor = '#cdd6f4'
    if ($yest -gt 0) {
        $diff = $today - $yest
        if ($diff -gt 0) {
            $cmp = "  较昨天+{0:P0}" -f ($diff / $yest)
            $arrow = [char]0x2191; $arrowColor = '#f38ba8'
        } elseif ($diff -lt 0) {
            $cmp = "  较昨天{0:P0}" -f ($diff / $yest)
            $arrow = [char]0x2193; $arrowColor = '#a6e3a1'
        }
    }
    return @{
        balance = $bal
        pro_in = $script:pro[1]; pro_out = $script:pro[2]; pro_cache = $script:pro[0]
        flash_in = $script:flash[1]; flash_out = $script:flash[2]; flash_cache = $script:flash[0]
        today_total = $today; yest_total = $yest
        compare = $cmp; arrow = $arrow; arrowColor = $arrowColor
        month_cost = $script:month_cost
    }
}

function Fmt($n) {
    if ($n -ge 100000000) { $big = ("{0:F1}亿" -f ($n / 100000000.0)).PadLeft(8) }
    else { $big = ("{0:F1}万" -f ($n / 10000.0)).PadLeft(8) }
    $prec = ("{0:N0}" -f $n).PadLeft(14)
    return "$big $prec"
}
function FmtBig($n) {
    if ($n -ge 100000000) { return ("{0:F1}亿" -f ($n / 100000000.0)).PadLeft(8) }
    return ("{0:F1}万" -f ($n / 10000.0)).PadLeft(8)
}

# === UI ===
Add-Type -AssemblyName PresentationFramework, WindowsBase, System.Windows.Forms

$w = New-Object System.Windows.Window
$w.Title = "DeepSeek"; $w.WindowStyle = "None"; $w.AllowsTransparency = $true
$w.Topmost = $true; $w.Background = "#E51e1e2e"; $w.SizeToContent = [System.Windows.SizeToContent]::WidthAndHeight
$w.WindowStartupLocation = "CenterScreen"

$g = New-Object System.Windows.Controls.Grid
$g.Margin = "10,6,10,6"
# Columns: label(100) | value(190)
$c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = 80
$c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = '*'
$g.ColumnDefinitions.Add($c1); $g.ColumnDefinitions.Add($c2)

# Rows: title, div, date, bal, cost, gap, pro_label, pro_cache, pro_miss, pro_out, gap, flash_label, flash_cache, flash_miss, flash_out, gap, today, yest
$rh = @(18,6,16,17,17, 4, 17,17,17,17, 4, 17,17,17,17, 4, 17,17)
foreach ($h in $rh) {
    $rd = New-Object System.Windows.Controls.RowDefinition
    $rd.Height = [System.Windows.GridLength]::new($h)
    $g.RowDefinitions.Add($rd)
}

function Lbl($text, $fg, $size, $bold, $row) {
    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $text; $t.Foreground = $fg; $t.FontFamily = "Consolas"
    $t.FontSize = $size; if ($bold) { $t.FontWeight = "Bold" }
    $t.HorizontalAlignment = "Left"
    $t.Margin = "2,0,2,0"
    [System.Windows.Controls.Grid]::SetRow($t, $row)
    [System.Windows.Controls.Grid]::SetColumn($t, 0)
    $g.AddChild($t); return $t
}
function Val($text, $fg, $size, $bold, $row) {
    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $text; $t.Foreground = $fg; $t.FontFamily = "Consolas"
    $t.FontSize = $size; if ($bold) { $t.FontWeight = "Bold" }
    $t.HorizontalAlignment = "Left"
    $t.Margin = "0,0,0,0"
    [System.Windows.Controls.Grid]::SetRow($t, $row)
    [System.Windows.Controls.Grid]::SetColumn($t, 1)
    $g.AddChild($t); return $t
}
function Val2($text, $fg, $size, $row) {
    Val $text $fg $size $true $row
}
function Center($text, $fg, $size, $row) {
    $t = New-Object System.Windows.Controls.TextBlock
    $t.Text = $text; $t.Foreground = $fg; $t.FontFamily = "Consolas"
    $t.FontSize = $size
    $t.HorizontalAlignment = "Center"
    [System.Windows.Controls.Grid]::SetRow($t, $row)
    [System.Windows.Controls.Grid]::SetColumnSpan($t, 2)
    $g.AddChild($t); return $t
}

# Row 0: Title
$tb = New-Object System.Windows.Controls.Grid
[System.Windows.Controls.Grid]::SetRow($tb, 0)
[System.Windows.Controls.Grid]::SetColumnSpan($tb, 2)
@("20","*","20") | % { $c = New-Object System.Windows.Controls.ColumnDefinition; $c.Width = $_; $tb.ColumnDefinitions.Add($c) }
$tt = New-Object System.Windows.Controls.TextBlock
$tt.Text = "DeepSeek 用量监控"; $tt.Foreground = "#cdd6f4"
$tt.FontFamily = "Consolas"; $tt.FontSize = 9; $tt.FontWeight = "Bold"
$tt.HorizontalAlignment = "Center"
[System.Windows.Controls.Grid]::SetColumn($tt, 1); $tb.AddChild($tt) | Out-Null
$xx = New-Object System.Windows.Controls.TextBlock
$xx.Text = "x"; $xx.Foreground = "#f38ba8"; $xx.FontFamily = "Consolas"
$xx.FontSize = 11; $xx.FontWeight = "Bold"; $xx.HorizontalAlignment = "Right"
$xx.VerticalAlignment = "Center"; $xx.Cursor = "Hand"; $xx.ToolTip = "Close"
[System.Windows.Controls.Grid]::SetColumn($xx, 2); $xx.Add_MouseLeftButtonDown({ $w.Close() }); $tb.AddChild($xx) | Out-Null
$g.AddChild($tb) | Out-Null

# Row 1: Divider
$d = New-Object System.Windows.Shapes.Rectangle
$d.Height = 1; $d.Fill = "#45475a"
[System.Windows.Controls.Grid]::SetRow($d, 1); [System.Windows.Controls.Grid]::SetColumnSpan($d, 2)
$g.AddChild($d)

# Row 2: Date
$lblDate = Center (Get-Date -Format 'yyyy-MM-dd') "#a0a0b0" 10 2

# Rows 3-4: Balance + Cost
Lbl "余额:"     "#a6e3a1" 10 $false 3; $lblBal  = Val2 "0.00 CNY" "#a6e3a1" 10 3
Lbl "本月消费:" "#f38ba8" 10 $false 4; $lblCost = Val2 "0.00 CNY" "#f38ba8" 10 4

# Row 6: v4-pro section header
Lbl "v4-pro" "#89b4fa" 10 $true 6

# Rows 7-9: pro data
Lbl "  输入(命中):"   "#f9e2af" 9 $false 7;  $proCache = Val2 "0" "#f9e2af" 9 7
Lbl "  输入(未命中):" "#89b4fa" 9 $false 8;  $proIn    = Val2 "0" "#89b4fa" 9 8
Lbl "  输出:"         "#cba6f7" 9 $false 9;  $proOut   = Val2 "0" "#cba6f7" 9 9

# Row 11: v4-flash section header
Lbl "v4-flash" "#a6e3a1" 10 $true 11

# Rows 12-14: flash data
Lbl "  输入(命中):"   "#f9e2af" 9 $false 12; $flashCache = Val2 "0" "#f9e2af" 9 12
Lbl "  输入(未命中):" "#89b4fa" 9 $false 13; $flashIn    = Val2 "0" "#89b4fa" 9 13
Lbl "  输出:"         "#cba6f7" 9 $false 14; $flashOut   = Val2 "0" "#cba6f7" 9 14

# Rows 16-17: Today + Yesterday
Lbl "今日合计:" "#cdd6f4" 10 $false 16; $lblTodayVal = Val2 "0" "#cdd6f4" 10 16
Lbl "昨日合计:" "#a0a0b0" 9  $false 17; $lblYestVal  = Val  "0" "#a0a0b0" 9  $false 17

# Arrow: tint applied to today value foreground
$script:todayValColor = "#cdd6f4"

$w.Content = $g
$w.Add_MouseLeftButtonDown({ $w.DragMove() })

$mnu = New-Object System.Windows.Controls.ContextMenu
$mr = New-Object System.Windows.Controls.MenuItem; $mr.Header = "Refresh"
$mr.Add_Click({ Refresh-All }); $mnu.Items.Add($mr) | Out-Null
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
    $lblBal.Text    = "{0:F2} CNY" -f $s.balance
    $lblCost.Text   = "{0:F2} CNY" -f $s.month_cost
    $proCache.Text  = Fmt $s.pro_cache
    $proIn.Text     = Fmt $s.pro_in
    $proOut.Text    = Fmt $s.pro_out
    $flashCache.Text = Fmt $s.flash_cache
    $flashIn.Text   = Fmt $s.flash_in
    $flashOut.Text  = Fmt $s.flash_out
    $lblTodayVal.Text = (FmtBig $s.today_total) + $s.compare + ' ' + $s.arrow
    $lblTodayVal.Foreground = $s.arrowColor
    $lblYestVal.Text  = FmtBig $s.yest_total
}

function Refresh-All { Fetch-Balance; Fetch-Usage; Update-Display }

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds(60)
$timer.Add_Tick({ Refresh-All })

if ($Demo) {
    $script:balance_cny = 82.50; $script:session_start = 100.00
    $script:pro = @(9437312L, 144096L, 79059L)
    $script:flash = @(2078080L, 110074L, 16319L)
    $script:yest_total = 15000000L
    $script:month_cost = 6.54; $script:status = 'ok'
}

Refresh-All
$w.Add_Closing({ $timer.Stop() }); $timer.Start()
$null = $w.ShowDialog()
