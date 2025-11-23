# GitHub Copilot CLI Integration for Smart Commits

## Overview

The `smart-commit.sh` script now integrates with GitHub Copilot CLI to generate intelligent commit messages using AI, based on your staged changes.

## Features

### 🤖 AI-Powered Commit Messages
- Automatically detects if GitHub Copilot CLI is installed
- Generates concise, descriptive commit messages using AI
- Analyzes your staged changes to create contextual messages
- Falls back to traditional rule-based generation if Copilot is unavailable

### ✨ Smart Workflow
1. **Copilot First**: If available, Copilot generates a commit message
2. **Review & Edit**: You can accept, edit, or reject the AI suggestion
3. **Fallback**: Traditional commit message generation if Copilot isn't available or declined
4. **Push Option**: Optionally push changes after committing

## Installation

### Prerequisites

1. **Install GitHub CLI**
   ```bash
   # macOS
   brew install gh
   
   # Or download from: https://cli.github.com/
   ```

2. **Authenticate with GitHub**
   ```bash
   gh auth login
   ```

3. **Install GitHub Copilot CLI Extension**
   ```bash
   gh extension install github/gh-copilot
   ```

4. **Verify Installation**
   ```bash
   gh copilot --version
   ```

### Setup Aliases

Run the setup script to create convenient aliases:

```bash
cd /path/to/team_sync
chmod +x scripts/setup-aliases.sh
./scripts/setup-aliases.sh
source ~/.zshrc  # or source ~/.bashrc
```

## Usage

### Quick Commit with Copilot

```bash
commit
```

### What Happens

1. **Staging**: All changes are staged (except sensitive files)
2. **Copilot Detection**: Checks if `gh copilot` is available
3. **AI Generation**: Copilot analyzes staged changes and suggests a commit message
4. **Review Prompt**: 
   ```
   🤖 GitHub Copilot CLI detected! Generating AI commit message...
   ✨ Copilot suggestion:
      Add player awards section to season page with navigation
   
   Use Copilot's message? [Y/n/edit]:
   ```

5. **Options**:
   - **Y** (or Enter): Use Copilot's message as-is
   - **n**: Decline and use traditional generation
   - **edit**: Edit Copilot's message before committing

6. **Commit & Push**: Create commit and optionally push to remote

### Examples

#### Example 1: Accept Copilot's Suggestion
```bash
$ commit
🤖 Generating commit message...

🤖 GitHub Copilot CLI detected! Generating AI commit message...
✨ Copilot suggestion:
   Add PIN generation button for player management

Use Copilot's message? [Y/n/edit]: Y

💾 Creating commit...
✅ Commit created successfully!
```

#### Example 2: Edit Copilot's Suggestion
```bash
$ commit
🤖 Generating commit message...

✨ Copilot suggestion:
   Update player awards model

Use Copilot's message? [Y/n/edit]: e

Enter your commit message (press Enter when done):
Update player awards model to use seasonId instead of date

💾 Creating commit...
✅ Commit created successfully!
```

#### Example 3: Fallback to Traditional
```bash
$ commit
🤖 Generating commit message...

✨ Copilot suggestion:
   Update files

Use Copilot's message? [Y/n/edit]: n

📝 Generating traditional commit message...
📝 Suggested commit message:
   Update code, docs (+3 ~5 )

Use this message? [Y/n/edit]: Y
```

## How It Works

### Copilot Integration

The script uses `gh copilot suggest` to generate commit messages:

```bash
# Simplified example
gh copilot suggest -t shell
```

The script:
1. Detects `gh` CLI installation
2. Checks for `gh copilot` extension
3. Sends staged changes context to Copilot
4. Parses and presents the AI-generated message
5. Allows user to accept, edit, or decline

### Fallback Behavior

If Copilot is not available or declined, the script uses traditional logic:

- **Action Detection**: Add, Update, Remove, Refactor
- **Component Analysis**: Dart code, scripts, docs, assets, config
- **Pattern Recognition**: UI changes, services, models, tests, fixes
- **Smart Suggestions**: Based on file types and change patterns

## Benefits

### 🎯 Accurate Messages
- AI understands code context
- Generates semantic, meaningful messages
- Better than generic "Update files" messages

### ⚡ Fast Workflow
- One command does everything
- No thinking about commit message wording
- Quick review and commit

### 🔄 Flexible
- Accept AI suggestions instantly
- Edit if needed
- Fall back to traditional if preferred

### 🔒 Safe
- Automatically excludes sensitive files
- Shows what will be committed
- Confirmation before pushing

## Configuration

### Sensitive Files

The script automatically excludes:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Other sensitive configuration files

### Customization

Edit `scripts/smart-commit.sh` to:
- Add more sensitive files to exclude
- Modify the Copilot prompt
- Change commit message format
- Adjust traditional fallback rules

## Troubleshooting

### Copilot Not Detected

**Problem**: Script doesn't detect Copilot
```bash
# Check gh CLI
which gh

# Check Copilot extension
gh extension list

# Install if missing
gh extension install github/gh-copilot
```

### Permission Denied

**Problem**: Script not executable
```bash
chmod +x scripts/smart-commit.sh
```

### Copilot Timeout

**Problem**: Copilot takes too long
- The script will timeout and fall back to traditional generation
- Try again with a stable internet connection

### Alias Not Found

**Problem**: `commit` command not recognized
```bash
# Re-run setup
./scripts/setup-aliases.sh

# Reload shell config
source ~/.zshrc  # or ~/.bashrc

# Or use full path
./scripts/smart-commit.sh
```

## Comparison: Copilot vs Traditional

### Traditional Generation
```
Update code, docs (+3 ~5)
```
- Generic and statistical
- Based on file counts and types
- Less context-aware

### Copilot Generation
```
Add player awards section to season page with navigation
```
- Semantic and descriptive
- Understands code changes
- Captures intent and feature

## Tips

### Best Practices

✅ **Stage related changes together**: Copilot works best with focused changes
✅ **Review AI suggestions**: Always check the message makes sense
✅ **Edit if needed**: Don't hesitate to refine the message
✅ **Commit frequently**: Smaller commits = better messages

❌ **Don't commit everything at once**: Too many unrelated changes confuse AI
❌ **Don't blindly accept**: Review the suggestion
❌ **Don't skip push**: Use the push option to keep remote in sync

### Keyboard Shortcuts

- `Y` or `Enter`: Accept suggestion quickly
- `n`: Decline and use fallback
- `e`: Edit before committing

## Future Enhancements

Possible improvements:
- Multi-line commit messages (body)
- Commit message templates
- Convention enforcement (conventional commits)
- Auto-linking to issues
- Emoji support 🎨
- Custom AI prompts

## Resources

- [GitHub CLI](https://cli.github.com/)
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/github-copilot-in-the-cli)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Status**: ✅ Integrated and Ready
**Date**: November 23, 2025
**Dependencies**: `gh` CLI with `gh-copilot` extension

