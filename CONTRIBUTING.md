# Contributing to Endurain

Thank you for considering contributing to Endurain! Before diving in, please read these guidelines carefully. They exist to make the process sustainable for everyone.

## A Note on Maintainership

Endurain is maintained by a single person in their spare time. This means review bandwidth is genuinely limited. Following these guidelines isn't bureaucracy, it's what allows contributions to actually get merged rather than sitting in a queue indefinitely.

## Before You Write Any Code

**Open an issue first.** For anything beyond a small bug fix, typo, or documentation improvement, please open an issue and wait for a response before writing code. This takes minutes and can save you hours of work on something that won't be merged because it conflicts with planned direction, existing work, or project scope.

If an issue already exists, comment on it to signal your intent so work isn't duplicated.

## Contributor License Agreement

Before a pull request can be merged, every contributor must accept the [Contributor License Agreement](CONTRIBUTOR_LICENSE_AGREEMENT.md) in the pull request checklist. It grants the Project Owner a broad, irrevocable license to use and relicense accepted contributions under any terms, including future commercial, proprietary, or dual-license terms. Contributors retain their copyright.

By checking the agreement box and submitting or updating the pull request, you electronically sign the agreement for that contribution. Only do so when you have the authority to grant those rights, including any approval required by your employer. Pull requests without the checked agreement are blocked by the required `Contributor License Agreement / Verify contributor agreement` status check and must not be merged.

## Pull Request Size — The Most Important Rule

**Keep PRs small and focused on a single concern.**

As a rule of thumb:

- **Target under 300 lines changed** (excluding lock files, generated code, and migrations)
- **One PR = one thing.** Don't bundle a bug fix with a refactor with a new feature
- If your change is naturally large (e.g. a new integration), break it into a chain of smaller PRs that can each be reviewed and merged independently

PRs that are too large to review efficiently will be asked to be split before they receive a review. This isn't a judgment on the quality of the work, it's a maintainability constraint.

**Excluded from the line count:** `package-lock.json`, `uv.lock`, migration files, and other generated or vendored files.

## How to Contribute

### Bug Fixes

- Check if an issue already exists before opening a new one
- Include clear steps to reproduce in the issue
- Small, targeted fixes are the fastest path to a merge

### Documentation

- Always welcome and rarely requires prior discussion
- Improvements to the docs site, inline code comments, and the README all count
- Keep the same tone and structure as existing docs

### New Features

- **Always discuss in an issue first** — this is required, not optional
- Features that haven't been discussed and approved in an issue may be closed without review, regardless of quality

### Refactors and Code Quality

- Must be discussed in an issue first
- Pure refactor PRs (no behaviour change) are easiest to review. Keep them separate from feature or fix PRs
- Include a clear explanation of what improved and why

## Testing and Quality Checks

Before opening a PR, run the same checks as CI:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
dart run tool/check_coverage.dart \
  --min-line-coverage 80 \
  --min-file-line-coverage 60 \
  --exclude 'lib/l10n/app_localizations*.dart' \
  --exclude 'lib/core/theme/app_theme_tokens.dart' \
  --exclude 'lib/core/navigation/app_routes.dart' \
  --exclude 'lib/shared/widgets/app_bottom_nav.dart' \
  --exclude 'lib/core/services/platform/*.dart' \
  --exclude 'lib/features/health/services/health_package_platform_adapter.dart'
```

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/endurain-flutter.git
   ```
3. **Create a branch** and use a descriptive name:
   ```bash
   git checkout -b fix/garmin-sync-timeout
   # or
   git checkout -b feat/gpx-export
   ```
4. **Make your changes**, committing with clear messages following [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   fix: handle timeout on Garmin sync
   feat: add GPX export for activities
   docs: clarify Docker environment variables
   ```
5. **Push and open a PR** against the `main` branch, filling in the PR template completely and accepting the Contributor License Agreement

## Response Time Expectations

Reviews may take days to weeks depending on availability. A PR sitting without a response is not a rejection. Please feel free to leave a polite ping after two weeks if there's been no activity.

## Thank You

Even small contributions make a real difference. Thank you for taking the time to improve Endurain for everyone who self-hosts it.