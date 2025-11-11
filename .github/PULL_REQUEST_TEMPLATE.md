<!-- Pull Request template: please keep concise and fill the checklist -->

## Summary

<!-- Short description of the change -->

## Changes
- List the main changes included in this PR (one per line)

## Testing
- How was this change tested? (local steps, CI, etc.)

## Security & secrets
- Does this PR add or expose any secrets? No — secrets should be provided via `.env` and CI secrets.
- Reference any key rotations or remediation performed if secrets were previously found.

## Reviewer checklist
- [ ] Code change looks correct and follows project guidelines
- [ ] CI checks (lint, analyze, tests) pass
- [ ] Secret scan passes (gitleaks / secret-scan job)
- [ ] Docs updated (README / CONTRIBUTING) where applicable
- [ ] Branch protection changes approved (if included)

## Notes
- Any additional notes for reviewers.


