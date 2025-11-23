# 🚀 Copilot Commit - Quick Reference

## Installation (One-Time Setup)

```bash
./scripts/setup-copilot.sh
./scripts/setup-aliases.sh
source ~/.zshrc
```

## Usage

```bash
commit
```

## Response Options

When Copilot suggests a message:

| Key | Action | Description |
|-----|--------|-------------|
| `Y` or `Enter` | ✅ Accept | Use Copilot's message as-is |
| `e` | ✏️ Edit | Modify Copilot's suggestion |
| `n` | ⏩ Skip | Use traditional generation |

## Example Session

```bash
$ commit

🤖 Generating commit message...
🤖 GitHub Copilot CLI detected! Generating AI commit message...
✨ Copilot suggestion:
   Add player awards section to season page with navigation

Use Copilot's message? [Y/n/edit]: Y

💾 Creating commit...
✅ Commit created successfully!

🚀 Push to remote? [y/N]: y
✅ Successfully pushed!
🎉 Done!
```

## Features

✅ **AI-Powered**: Understands your code changes  
✅ **Context-Aware**: Generates semantic messages  
✅ **Fast**: One command, done  
✅ **Safe**: Excludes sensitive files  
✅ **Flexible**: Accept, edit, or skip  
✅ **Smart Fallback**: Works without Copilot too  

## Tips

💡 **Commit frequently**: Better AI suggestions  
💡 **Review messages**: AI is smart but verify  
💡 **Edit if needed**: Refine the suggestion  
💡 **Stage related changes**: One feature per commit  

## Troubleshooting

### Copilot not detected?
```bash
gh copilot --version
gh extension install github/gh-copilot
```

### Alias not working?
```bash
source ~/.zshrc
# or
./scripts/smart-commit.sh
```

## Documentation

📖 Full docs: `docs/COPILOT_COMMIT_INTEGRATION.md`  
📋 Summary: `COPILOT_COMMIT_SUMMARY.md`

---

**Happy Committing! 🎉**

