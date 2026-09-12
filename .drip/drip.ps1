# Copies the next 3 queued notebooks into Notebooks/, updates README, commits, pushes.
# ponytail: plain file queue, no state DB. Swap for a DB if this ever outgrows one text file.
$ErrorActionPreference = 'Stop'
$repo  = Split-Path $PSScriptRoot -Parent
$queue = Join-Path $PSScriptRoot 'queue.txt'
$batch = 3

$lines   = Get-Content $queue
$pending = $lines | Where-Object { $_.Trim() -and -not $_.StartsWith('#') }
if (-not $pending) { Write-Output 'Queue empty, nothing to do.'; exit 0 }

$take = @($pending | Select-Object -First $batch)
$added = @()
foreach ($src in $take) {
    if (-not (Test-Path -LiteralPath $src)) { Write-Warning "Missing: $src"; continue }
    $name = Split-Path $src -Leaf
    $dest = Join-Path $repo "Notebooks\$name"
    if (Test-Path -LiteralPath $dest) { Write-Warning "Already in repo: $name"; continue }
    Copy-Item -LiteralPath $src -Destination $dest
    $added += $name
}

# Drop the taken lines whether copied or skipped, so a bad path never wedges the queue.
Set-Content -Path $queue -Encoding utf8 -Value ($lines | Where-Object { $take -notcontains $_ })

if (-not $added) { Write-Output 'No new notebooks added.'; exit 0 }

$readme = Join-Path $repo 'README.md'
$links = $added | ForEach-Object { "- [$_](Notebooks/$($_ -replace ' ', '%20'))" }
Add-Content -Path $readme -Value $links -Encoding utf8

git -C $repo add -A
git -C $repo commit -m "Added $($added.Count) notebooks"
git -C $repo push
Write-Output "Added: $($added -join ', ')"
