# Quick Git Workflow Guide

## Option 1: GitDoc Extension (Automatic)
Install the GitDoc extension for automatic commits on save.

### Install GitDoc
1. Open VS Code Extensions (Ctrl+Shift+X)
2. Search for "GitDoc"
3. Install "GitDoc" by vsls-contrib
4. Enable it with: `GitDoc: Enable` from Command Palette (Ctrl+Shift+P)

### GitDoc Settings
Add to `.vscode/settings.json`:
```json
{
  "gitdoc.enabled": true,
  "gitdoc.commitMessageFormat": "Auto-save: ${file}",
  "gitdoc.autoCommitDelay": 1000,
  "gitdoc.autoPush": "onCommit"
}
```

---

## Option 2: PowerShell Alias (Fast Manual)
Create quick commands for common Git operations.

### Add to PowerShell Profile
Edit: `C:\Users\keena\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

```powershell
# Quick Git Aliases
function gitpush {
    param([string]$message = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    git add .
    git commit -m $message
    git push
}

function gitquick { gitpush "Quick save" }
function gitsave { gitpush }
```

### Usage
```powershell
# Commit and push with custom message
gitpush "Added URL shortening feature"

# Quick commit with auto-generated message
gitquick

# Commit with timestamp
gitsave
```

---

## Option 3: VS Code Tasks (One-Click Git)
Create a task to commit and push with one click.

### Create `.vscode/tasks.json`
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Git: Quick Commit & Push",
      "type": "shell",
      "command": "git add . && git commit -m 'Quick save: ${input:commitMessage}' && git push",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Git: Auto Commit & Push",
      "type": "shell",
      "command": "git add . && git commit -m 'Auto-save: $(date +\"%Y-%m-%d %H:%M\")' && git push",
      "problemMatcher": []
    }
  ],
  "inputs": [
    {
      "id": "commitMessage",
      "type": "promptString",
      "description": "Commit message",
      "default": "Update code"
    }
  ]
}
```

### Usage
- Press `Ctrl+Shift+P`
- Type "Tasks: Run Task"
- Select "Git: Quick Commit & Push" or "Git: Auto Commit & Push"

### Create Keyboard Shortcut
Add to `keybindings.json` (Ctrl+K Ctrl+S):
```json
{
  "key": "ctrl+shift+g ctrl+p",
  "command": "workbench.action.tasks.runTask",
  "args": "Git: Auto Commit & Push"
}
```

---

## Option 4: Git Hooks (Automated Actions)
Automatically run commands on certain Git events.

### Create `.git/hooks/post-commit`
```bash
#!/bin/bash
# Auto-push after every commit
git push origin main
```

Make it executable:
```bash
chmod +x .git/hooks/post-commit
```

### Usage
Now `git commit` will automatically push!

---

## ⚠️ Important Considerations

### When NOT to Auto-Commit
- ❌ Working with a team (creates noise)
- ❌ Large files or many changes (slows down)
- ❌ Experimental code (pollutes history)
- ❌ Sensitive data might be committed

### When Auto-Commit is OK
- ✅ Solo projects
- ✅ Documentation/notes
- ✅ Rapid prototyping
- ✅ Personal backup purposes

### Best Practice
**Manual commits are better for:**
- Meaningful commit messages
- Logical grouping of changes
- Clean git history
- Code review

**Auto-commits are good for:**
- Personal backups
- Work-in-progress tracking
- Quick experiments

---

## 🎯 My Recommendation

For your Driven Repairs project, I recommend **Option 2 (PowerShell Aliases)**:

1. **Why:** Fast but still allows meaningful commit messages
2. **Control:** You decide when to commit (not after every file save)
3. **Clean History:** Better for future reference and collaboration
4. **Flexibility:** Easy to customize

### Quick Setup
```powershell
# Open PowerShell profile
notepad $PROFILE

# Add these functions
function gitsave {
    param([string]$msg = "Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm')")
    git add .
    git commit -m $msg
    git push
    Write-Host "✅ Changes committed and pushed!" -ForegroundColor Green
}

# Save and reload
. $PROFILE
```

### Then just run:
```powershell
gitsave "Added ticket details dialog"
# or
gitsave
```

---

## 📝 Commit Message Best Practices

### Good Commit Messages
```
✅ "Add URL shortening system with database v4"
✅ "Fix customer selection dialog variable scoping"
✅ "Remove information banner from feedback dialog"
✅ "Implement ticket details dialog with full info display"
```

### Poor Commit Messages
```
❌ "update"
❌ "fix"
❌ "changes"
❌ "wip"
```

### Conventional Commits Format
```
feat: Add URL shortening system
fix: Customer selection button not enabling
docs: Update URL shortening documentation
refactor: Clean up feedback dialog UI
```

---

## 🚀 Quick Command Reference

### Manual Git (What you currently do)
```bash
git add .
git commit -m "Your message"
git push
```

### With PowerShell Alias (After setup)
```powershell
gitsave "Your message"
```

### With GitDoc (Automatic)
Just save your file (Ctrl+S) - done!

---

Choose the option that fits your workflow best! 🎉
