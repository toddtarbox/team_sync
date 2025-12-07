# Smart Commit Script

Intelligently commit changes while protecting sensitive configuration files.

## Features

✨ **Smart Features:**
- 🔒 Automatically excludes sensitive files (API keys, certificates)
- 🤖 Generates intelligent commit messages based on changes
- 📊 Shows detailed change statistics
- 🎨 Color-coded output for easy reading
- 🚀 Prompts to push to current branch
- ✏️ Interactive commit message editing

## Usage

```bash
./scripts/smart-commit.sh
```

That's it! The script handles everything interactively.

## Protected Files

The following files are **automatically excluded** from commits:

- `android/app/google-services.json` - Firebase Android config
- `android/app/src/teamSync/google-services.json` - Firebase TeamSync flavor config
- `ios/Runner/GoogleService-Info.plist` - Firebase iOS config
- `ios/Runner/Info.plist` - iOS app configuration

These files contain sensitive API keys and should not be committed to version control.

## How It Works

### 1. Stage Changes
- Adds all modified files
- **Automatically unstages** sensitive configuration files
- Shows what will be committed

### 2. Generate Smart Commit Message
Analyzes your changes and suggests a commit message based on:
- **File types changed** (Dart, scripts, docs, assets, config)
- **Platforms affected** (iOS, Android, web)
- **Change statistics** (+added, ~modified, -deleted files)
- **Code patterns** (Widget changes, Services, Models, Fixes)

### 3. Review & Commit
- Shows suggested message
- Options:
  - **Y** (default) - Use suggested message
  - **N** - Enter custom message
  - **E** - Edit suggested message

### 4. Push (Optional)
- Prompts to push to current branch
- Automatically creates remote branch if needed
- Shows push status

## Example Output

```bash
🚀 Smart Commit Script
================================================
Current branch: feature/new-feature

🔒 Excluding sensitive files:
   - android/app/google-services.json
   - ios/Runner/GoogleService-Info.plist
   - ios/Runner/Info.plist

📦 Staging changes...
✅ Changes staged successfully

📋 Staged files:
   ~ lib/widgets/players_page.dart
   ~ lib/widgets/season_page.dart
   + scripts/smart-commit.sh
   + scripts/SMART_COMMIT.md

🤖 Generating commit message...

📝 Suggested commit message:
   Update code, scripts (+2 ~2)

Use this message? [Y/n/edit]: y

💾 Creating commit...
✅ Commit created successfully!

📊 Commit details:
[Shows git log with stats]

🚀 Push to remote?
   Branch: feature/new-feature
Push changes? [y/N]: y

📤 Pushing to feature/new-feature...
✅ Successfully pushed to origin/feature/new-feature

🎉 Done!
```

## Smart Message Examples

Based on your changes, the script generates messages like:

| Changes | Generated Message |
|---------|------------------|
| Only Dart files modified | `Update code (~5)` |
| New script added | `Add scripts (+1)` |
| Documentation updated | `Update docs (~3)` |
| Multiple types | `Update code, scripts, docs (+2 ~5)` |
| iOS + Android changes | `Update iOS, Android (~4)` |
| Config file changes | `Update config (~1)` |

## Interactive Options

### Commit Message Prompt
```
Use this message? [Y/n/edit]:
```
- **Y** or **Enter** - Accept suggested message
- **N** - Write your own message from scratch
- **E** - Edit the suggested message

### Push Prompt
```
Push changes? [y/N]:
```
- **Y** - Push to remote branch
- **N** or **Enter** - Skip push (commit locally only)

## Common Workflows

### Quick Commit & Push
```bash
./scripts/smart-commit.sh
# Press Enter to accept message
# Press 'y' to push
```

### Custom Message
```bash
./scripts/smart-commit.sh
# Press 'n' when prompted
# Enter your custom message
# Choose whether to push
```

### Commit Without Push
```bash
./scripts/smart-commit.sh
# Accept or customize message
# Press 'n' or Enter when asked to push
```

## Safety Features

### 🔒 Protected Files
Sensitive files are **always excluded**, even if:
- You run `git add .` before the script
- The files were previously staged
- The files have been modified

### ⚠️ Change Detection
The script checks if:
- There are any changes to commit
- Only sensitive files were modified (and skips commit)
- You're in a git repository

### 📊 Visual Feedback
- Color-coded file status:
  - 🟢 `+` Added files
  - 🟡 `~` Modified files
  - 🔴 `-` Deleted files
  - 🔵 `→` Renamed files

## Error Handling

The script handles:
- No git repository
- No changes to commit
- Only sensitive files modified
- Empty commit messages
- Failed commits
- Failed pushes
- Non-existent remote branches

## Tips

### Alias for Quick Access
Add to your `~/.zshrc` or `~/.bashrc`:
```bash
alias commit='./scripts/smart-commit.sh'
```

Then just run:
```bash
commit
```

### Review Before Committing
The script shows all staged files before committing. Review them to ensure you're committing what you expect.

### Manual Push Later
If you skip the push prompt, you can push manually later:
```bash
git push origin <branch-name>
```

## What Gets Excluded

### Always Excluded
- `android/app/google-services.json`
- `android/app/src/teamSync/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `ios/Runner/Info.plist`

### Also Respects
- `.gitignore` patterns
- Git's own ignore rules

## Troubleshooting

### "Not a git repository"
Make sure you're in the project root directory.

### "No changes to commit"
All your changes might be:
- Already committed
- Only in sensitive files (which are excluded)
- Ignored by `.gitignore`

### "Push failed"
- Check your network connection
- Ensure you have push access to the remote
- Verify the remote branch exists or create it manually

## Related Scripts

- `bump-and-build.sh` - Version bump and build
- `quick-build.sh` - Interactive build menu
- `build-team-sync.sh` - Platform-specific builds

