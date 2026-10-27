# Claude Code status line. Reads session JSON on stdin, prints one line.
# Windows counterpart of statusline.sh.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

try { $j = [Console]::In.ReadToEnd() | ConvertFrom-Json } catch { $j = $null }
if (-not $j) { $j = [pscustomobject]@{} }

function Get-Num($v) { if ($null -eq $v) { 0 } else { [double]$v } }

function Format-Duration($ms) {
    $s = [int][math]::Floor($ms / 1000)
    if ($s -ge 3600) { '{0}h{1:00}m' -f [math]::Floor($s / 3600), [math]::Floor(($s % 3600) / 60) }
    elseif ($s -ge 60) { '{0}m{1:00}s' -f [math]::Floor($s / 60), ($s % 60) }
    else { "${s}s" }
}

$parts = @()

if ($j.model.display_name) { $parts += $j.model.display_name }

# Directory: relative to the project when inside it, otherwise ~-abbreviated.
$cwd = if ($j.workspace.current_dir) { $j.workspace.current_dir } else { $j.cwd }
$project = $j.workspace.project_dir
if ($cwd) {
    if ($project -and $cwd.StartsWith($project, [StringComparison]::OrdinalIgnoreCase)) {
        $dir = (Split-Path -Leaf $project) + $cwd.Substring($project.Length)
    } elseif ($cwd.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) {
        $dir = '~' + $cwd.Substring($HOME.Length)
    } else {
        $dir = $cwd
    }
    $parts += $dir
}

# Git branch, dirty marker and ahead/behind upstream.
if ($cwd -and (Get-Command git -ErrorAction SilentlyContinue)) {
    $branch = git -C $cwd --no-optional-locks symbolic-ref --short -q HEAD 2>$null
    if (-not $branch) { $branch = git -C $cwd --no-optional-locks rev-parse --short HEAD 2>$null }
    if ($branch) {
        if (git -C $cwd --no-optional-locks status --porcelain -uno 2>$null) { $branch += '*' }
        $counts = git -C $cwd --no-optional-locks rev-list --left-right --count '@{upstream}...HEAD' 2>$null
        if ($LASTEXITCODE -eq 0 -and $counts) {
            $behind, $ahead = $counts -split '\s+'
            if ([int]$ahead -gt 0) { $branch += " ↑$ahead" }
            if ([int]$behind -gt 0) { $branch += " ↓$behind" }
        }
        $parts += $branch
    }
}

# Context usage.
$cw = $j.context_window
if ($null -ne $cw.used_percentage) {
    $ctx = 'ctx {0}%' -f [math]::Floor($cw.used_percentage)
    $size = Get-Num $cw.context_window_size
    if ($size -gt 0) {
        $u = $cw.current_usage
        $tokens = (Get-Num $u.input_tokens) + (Get-Num $u.cache_creation_input_tokens) + (Get-Num $u.cache_read_input_tokens)
        $ctx += ' ({0}k/{1}k)' -f [math]::Floor($tokens / 1000), [math]::Floor($size / 1000)
    }
    $parts += $ctx
} else {
    $parts += 'ctx --'
}

$c = $j.cost
$parts += '${0:0.00}' -f (Get-Num $c.total_cost_usd)
$parts += '{0} (api {1})' -f (Format-Duration (Get-Num $c.total_duration_ms)), (Format-Duration (Get-Num $c.total_api_duration_ms))
$parts += '+{0} −{1}' -f (Get-Num $c.total_lines_added), (Get-Num $c.total_lines_removed)

if ($j.output_style.name -and $j.output_style.name -ne 'default') { $parts += "style:$($j.output_style.name)" }

# Kubernetes context, if configured.
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    $k8s = kubectl config current-context 2>$null
    if ($LASTEXITCODE -eq 0 -and $k8s) { $parts += "⎈ $k8s" }
}

$parts -join ' · '
