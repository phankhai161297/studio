param(
    [string]$Tag = "xxx",
    [string]$Note = "",
    [switch]$DryRun
)

Push-Location $PSScriptRoot
try {
    $currentBranch = (git branch --show-current)
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to detect current Git branch."
        exit 1
    }
    $currentBranch = "$currentBranch".Trim()
    if ($currentBranch -ne "main") {
        Write-Error "Current branch is '$currentBranch'. Please switch to 'main' first."
        exit 1
    }

    $timestamp = Get-Date -Format "HH:mm:ss dd-MM-yyyy"
    $cleanTag = if ([string]::IsNullOrWhiteSpace($Tag)) { "xxx" } else { $Tag.Trim() }
    $commitMessage = if ([string]::IsNullOrWhiteSpace($Note)) {
        "[$cleanTag] Release $timestamp"
    } else {
        "[$cleanTag] Release $($Note.Trim()) $timestamp"
    }

    $changes = @(git status --porcelain)
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to check Git status."
        exit 1
    }

    if ($changes.Count -eq 0) {
        $ahead = git rev-list --count "origin/main..HEAD" 2>$null
        if ($LASTEXITCODE -eq 0 -and [int]$ahead -gt 0) {
            Write-Host "No new file changes. Pushing $ahead local commit(s) to origin/main..." -ForegroundColor Yellow
            if ($DryRun) {
                Write-Host "[DryRun] Would run: git push -u origin main" -ForegroundColor Yellow
                return
            }
            git push -u origin main
            if ($LASTEXITCODE -ne 0) {
                Write-Error "git push failed."
                exit 1
            }
            Write-Host "Successfully pushed to origin/main." -ForegroundColor Green
            return
        }

        Write-Host "Nothing to commit or push." -ForegroundColor Yellow
        return
    }

    Write-Host "Branch : main" -ForegroundColor Cyan
    Write-Host "Commit : $commitMessage" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "[DryRun] Files that would be staged:" -ForegroundColor Yellow
        foreach ($line in $changes) {
            Write-Host "  $line"
        }
        return
    }

    git add -A
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git add failed."
        exit 1
    }

    git commit -m $commitMessage
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git commit failed."
        exit 1
    }

    git push -u origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git push failed."
        exit 1
    }

    Write-Host "Successfully pushed to origin/main." -ForegroundColor Green
}
finally {
    Pop-Location
}
