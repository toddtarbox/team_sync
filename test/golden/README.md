# Golden Tests

Golden tests (also called snapshot tests) capture screenshots of your widgets and compare them against reference images to detect visual regressions.

## Setup

1. Generate golden files:
```bash
flutter test --update-goldens
```

2. Run golden tests:
```bash
flutter test
```

## Best Practices

- Update goldens only when you intentionally change the UI
- Review golden diffs carefully before updating
- Commit golden files to version control
- Run goldens in CI to catch unintended visual changes

## Screen Size Testing

Golden tests are particularly useful for verifying responsive layouts across different screen sizes. The test suite includes:

- Small screens (320x568) - iPhone SE/5
- Medium screens (375x667) - iPhone 8
- Large screens (414x896) - iPhone 11 Pro Max
- Tablets (768x1024) - iPad

## Troubleshooting

If golden tests fail unexpectedly:

1. Check if the failure is intentional due to UI changes
2. View the diff images in `test/golden/failures/`
3. Update goldens if changes are correct: `flutter test --update-goldens`
4. Platform differences: Goldens may differ between macOS/Linux/Windows. Consider using CI for consistency.

## Ignoring Platform Differences

For font rendering differences across platforms, you can:
- Use a consistent test environment (Docker/CI)
- Adjust tolerance: `matchesGoldenFile('test.png', version: 1)`
- Skip goldens on certain platforms if needed

