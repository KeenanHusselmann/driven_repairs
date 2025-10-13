# Quick Git Save Functions for Driven Repairs Project
# Add these to your PowerShell profile: C:\Users\keena\Documents\PowerShell\Microsoft.PowerShell_profile.ps1

# Quick save with custom message
function gitsave {
    param([string]$msg = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    
    Write-Host "📝 Staging changes..." -ForegroundColor Cyan
    git add .
    
    Write-Host "💾 Committing: $msg" -ForegroundColor Yellow
    git commit -m $msg
    
    Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Magenta
    git push
    
    Write-Host "✅ All done! Changes are on GitHub." -ForegroundColor Green
}

# Ultra-quick save (just type 'gs')
function gs {
    param([string]$msg = "Quick save: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    gitsave $msg
}

# Save with feature description
function gitfeat {
    param([string]$feature)
    gitsave "feat: $feature"
}

# Save with fix description
function gitfix {
    param([string]$fix)
    gitsave "fix: $fix"
}

# Check git status
function gst {
    git status
}

# View recent commits
function glog {
    git log --oneline --graph --decorate --all -10
}

Write-Host "✅ Git shortcuts loaded! Use: gitsave, gs, gitfeat, gitfix, gst, glog" -ForegroundColor Green
