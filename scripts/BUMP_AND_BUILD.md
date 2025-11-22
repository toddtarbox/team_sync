# Bump and Build Script

Automatically bump the version/build number in `pubspec.yaml` and kick off Android and iOS builds simultaneously.

## Usage

```bash
./scripts/bump-and-build.sh [major|minor|patch|build-only]
```

### Bump Types

- **major** - Bump major version (e.g., 1.7.9 → 2.0.0+77)
- **minor** - Bump minor version (e.g., 1.7.9 → 1.8.0+77)
- **patch** - Bump patch version (e.g., 1.7.9 → 1.7.10+77) **[DEFAULT]**
- **build-only** - Only increment build number (e.g., 1.7.9+76 → 1.7.9+77)

### Examples

```bash
# Bump patch version (default) - most common for bug fixes
./scripts/bump-and-build.sh

# Bump minor version - for new features
./scripts/bump-and-build.sh minor

# Bump major version - for breaking changes
./scripts/bump-and-build.sh major

# Only bump build number - for rebuild with no code changes
./scripts/bump-and-build.sh build-only
```

## What the Script Does

1. **Reads current version** from `pubspec.yaml`
2. **Bumps version** according to specified type
3. **Increments build number** automatically
4. **Prompts for confirmation** before making changes
5. **Updates pubspec.yaml** with new version
6. **Optionally creates git commit** for the version bump
7. **Kicks off Android and iOS builds simultaneously** in parallel
8. **Logs build output** to `build/logs/` directory
9. **Shows summary** of build results

## Build Outputs

After successful builds, you'll find:

- **Android**: `build/app/outputs/bundle/teamSyncRelease/`
- **iOS**: `build/ios/ipa/`
- **Build logs**: `build/logs/android_TIMESTAMP.log` and `build/logs/ios_TIMESTAMP.log`

## Requirements

- Flutter SDK installed and in PATH
- For iOS builds: Xcode with proper code signing configured
- For Android builds: Android SDK configured

## Version Numbering

Follows semantic versioning:
- **MAJOR.MINOR.PATCH+BUILD**
- Example: `1.7.9+76`
  - Major: 1
  - Minor: 7
  - Patch: 9
  - Build: 76

## Interactive Prompts

The script will ask:
1. Confirm version bump before proceeding
2. Whether to create a git commit (optional)

## Error Handling

- If either build fails, the script will report which one failed
- Build logs are saved for debugging
- Script exits with error code if builds fail

## Tips

- Use `patch` for bug fixes
- Use `minor` for new features
- Use `major` for breaking changes
- Use `build-only` when rebuilding without code changes

