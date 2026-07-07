# Pull Shark Badge Automation - hiimanshu0207/badges
# Usage: .\pull-shark.ps1 [-TotalPRs 128] [-StartFrom 1]

param(
    [int] $StartFrom = 1,
    [int] $TotalPRs  = 128,
    [int] $DelayMs   = 1200
)

$GH_REPO = "hiimanshu0207/badges"
$RepoDir = $PSScriptRoot

# Fix PATH so gh CLI is found
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path","User")

function Info    { param($m) Write-Host "  $m"        -ForegroundColor Cyan   }
function Success { param($m) Write-Host "  [OK] $m"   -ForegroundColor Green  }
function Warn    { param($m) Write-Host "  [!!] $m"   -ForegroundColor Yellow }
function Err     { param($m) Write-Host "  [XX] $m"   -ForegroundColor Red    }
function Banner  { param($m) Write-Host "`n=== $m ===" -ForegroundColor Magenta }

function Show-Progress {
    param([int]$Current, [int]$Total)
    $pct    = [math]::Round(($Current / $Total) * 100)
    $filled = [math]::Round($pct / 2)
    $empty  = 50 - $filled
    $bar    = ("#" * $filled) + ("-" * $empty)
    $tier   = if ($Current -ge 128) { "GOLD" } elseif ($Current -ge 16) { "SILVER" } elseif ($Current -ge 2) { "BRONZE" } else { "..." }
    Write-Host "`r  [$bar] $pct% ($Current/$Total) [$tier]" -NoNewline -ForegroundColor Yellow
}

function Check-Badge {
    param([int]$Count)
    if ($Count -eq 2)   { Write-Host ""; Success "BRONZE UNLOCKED! Pull Shark x1 - 2 PRs merged!" }
    if ($Count -eq 16)  { Write-Host ""; Success "SILVER UNLOCKED! Pull Shark x2 - 16 PRs merged!" }
    if ($Count -eq 128) { Write-Host ""; Success "GOLD UNLOCKED!   Pull Shark x3 - 128 PRs! You are a Pull Shark!" }
}

# ── Validate ──────────────────────────────────────────────────
Banner "Pull Shark Automation - $GH_REPO"

try { $v = & gh --version 2>&1 | Select-Object -First 1; Success "gh found: $v" }
catch { Err "gh CLI not found!"; exit 1 }

$authStatus = & gh auth status 2>&1
if ($LASTEXITCODE -ne 0) { Err "Not logged in. Run: gh auth login"; exit 1 }
Success "Authenticated as hiimanshu0207"

$repoCheck = & gh repo view $GH_REPO 2>&1
if ($LASTEXITCODE -ne 0) { Err "Cannot access repo: $GH_REPO"; exit 1 }
Success "Repo OK: https://github.com/$GH_REPO"

# ── Prepare local repo ────────────────────────────────────────
Banner "Preparing local repo..."
Set-Location $RepoDir

if (-not (Test-Path ".git")) { Err "No .git folder in $RepoDir"; exit 1 }

git fetch origin main 2>&1 | Out-Null
git checkout main     2>&1 | Out-Null
git pull origin main  2>&1 | Out-Null
Success "Synced with origin/main"

if (-not (Test-Path "pr-changes")) {
    New-Item -ItemType Directory -Path "pr-changes" | Out-Null
}

# ── PR Loop ───────────────────────────────────────────────────
Banner "Creating & merging $TotalPRs PRs (from #$StartFrom)..."
Info "Repo: https://github.com/$GH_REPO"
Info "Press Ctrl+C to pause. Resume with: .\pull-shark.ps1 -StartFrom <N>"
Write-Host ""

$mergedCount = $StartFrom - 1

for ($i = $StartFrom; $i -le $TotalPRs; $i++) {

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $branch    = "auto-pr-$i-$timestamp"
    $filename  = "pr-changes/pr-$i.md"

    # Create branch
    git checkout main       2>&1 | Out-Null
    git pull origin main    2>&1 | Out-Null
    git checkout -b $branch 2>&1 | Out-Null

    # Make a unique change
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $content = "# PR $i`n`nTimestamp: $ts`nBranch: $branch`nProgress: $i/$TotalPRs`n"
    Set-Content -Path $filename -Value $content -Encoding UTF8

    git add $filename 2>&1 | Out-Null
    git commit -m "chore: pull-shark pr #$i [$ts]" 2>&1 | Out-Null
    git push origin $branch 2>&1 | Out-Null

    # Create PR
    $prResult = & gh pr create `
        --repo  $GH_REPO `
        --title "chore: pull-shark PR #$i of $TotalPRs" `
        --body  "Automated PR #$i for Pull Shark badge. Timestamp: $ts" `
        --base  main `
        --head  $branch 2>&1

    if ($LASTEXITCODE -ne 0) {
        Warn "PR #$i create failed - skipping: $prResult"
        git checkout main 2>&1 | Out-Null
        git branch -D $branch 2>&1 | Out-Null
        continue
    }

    Start-Sleep -Milliseconds $DelayMs

    # Merge PR
    $mergeResult = & gh pr merge $branch `
        --repo          $GH_REPO `
        --merge `
        --delete-branch `
        --yes 2>&1

    if ($LASTEXITCODE -ne 0) {
        Warn "PR #$i merge failed: $mergeResult"
        git checkout main 2>&1 | Out-Null
        continue
    }

    $mergedCount++
    Show-Progress -Current $mergedCount -Total $TotalPRs
    Check-Badge -Count $mergedCount

    git checkout main  2>&1 | Out-Null
    git branch -D $branch 2>&1 | Out-Null

    Start-Sleep -Milliseconds $DelayMs
}

# ── Summary ───────────────────────────────────────────────────
Write-Host ""
Banner "Done! $mergedCount PRs merged into $GH_REPO"
Write-Host ""
Write-Host "  View your badges: https://github.com/hiimanshu0207" -ForegroundColor Cyan
Write-Host ""
if ($mergedCount -ge 2)   { Write-Host "  [BRONZE] Pull Shark x1 - UNLOCKED" -ForegroundColor DarkYellow }
if ($mergedCount -ge 16)  { Write-Host "  [SILVER] Pull Shark x2 - UNLOCKED" -ForegroundColor Gray }
if ($mergedCount -ge 128) { Write-Host "  [GOLD]   Pull Shark x3 - UNLOCKED" -ForegroundColor Yellow }
Write-Host ""
Write-Host "  (Badges may take a few minutes to appear on your GitHub profile)" -ForegroundColor DarkGray
Write-Host ""
