---
name: conventional-commits
description: Write commit messages, PR titles and descriptions, and changelog entries for the Endurain mobile app following Conventional Commits. Use whenever creating, amending or squashing a commit, or opening or updating a pull request.
---

# Conventional Commits for the Endurain mobile app

Every commit subject and every PR title is validated in CI by `.github/workflows/conventional-commits.yml`
(script: `.github/scripts/check_conventional_commits.py`). A non-compliant title blocks the PR, so get it
right the first time.

## Header format

```
<type>(<scope>)!: <description>
```

- `(<scope>)` and `!` are optional.
- A single space after the colon is required.
- Only the first line is validated; the body and footers are free-form.

### Allowed types (project whitelist)

| Type | Use for |
| --- | --- |
| `feat` | New user-facing capability |
| `fix` | Bug fix (including security fixes) |
| `docs` | Documentation only (README, CONTRIBUTING, CHANGELOG, `AGENTS.md`, skills, comments) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `build` | Build system, Gradle, Xcode project, dependencies, the CI builder image |
| `ci` | CI workflows, composite actions and CI scripts |
| `chore` | Maintenance that fits nowhere else (releases, housekeeping) |
| `style` | Formatting only, no logic change |
| `revert` | Reverting a previous commit |

Any other type (e.g. `feature`, `bugfix`, `security`, `deps`) fails validation.

### Scope

Optional, any non-empty string without parentheses. Prefer the feature or platform touched, matching what
recent history uses: `activity`, `auth`, `health`, `map`, `sensors`, `settings`, `diagnostics`, `l10n`,
`android`, `wear`, `ios`, `release`, `deps`. Omit the scope when the change spans many areas.

### Description

- Imperative mood, describes what the change does: `add cadence to the recording statistics`, not `added` / `adds`.
- Specific, not vague (`fix(activity): write GPX files atomically`, not `fix: bug`).
- No trailing period; keep the header under 72 characters.

### Breaking changes

Mark with `!` after the type/scope and/or a `BREAKING CHANGE: <explanation>` footer when a change needs
action from users: a raised minimum OS version, dropped server-version support, a local data migration
that cannot be undone, or a changed build or signing input.

## Examples

```
feat(wear): add a start-workout tile
fix(activity): write GPX files atomically and retry backed-off uploads
fix(diagnostics): redact hosts, IP addresses and auth schemes
build(android): share one version catalog and split watch_shared
ci(ios): run on pull requests and run the watchOS unit tests
chore(release): 0.12.4+26
```

## Committing

1. Inspect the change first: `git status`, `git diff --staged` (and `git log --format=%s -10` to match
   recent style and scopes).
2. Choose the type by the *primary intent* of the change. If a diff mixes unrelated concerns, prefer
   splitting into separate commits, one concern each.
3. Write the header per the rules above. Add a body (blank line after the header) only when the *why*
   isn't obvious; wrap at ~72 columns.
4. Reference issues in the body/footer, e.g. `Closes #123` or `Refs #123`.
5. Do not use `--no-verify`, and do not rewrite or force-push shared history unless explicitly asked.
6. Include any attribution/co-author trailer that the session instructs you to add.

Optionally self-check before committing:

```bash
python3 .github/scripts/check_conventional_commits.py "feat(scope): your header"
```

## Changelog

- A user-visible change adds a line under `## [Unreleased]` in `CHANGELOG.md` in the same change.
- Sections follow Keep a Changelog: `Added`, `Changed`, `Fixed`, `Security` (and `Deprecated`, `Removed` when needed).
- Write for users: what changed for them and on which platform, in one or two sentences.
- Internal work that users cannot see goes, if anywhere, in the `Internal changes` list under `Changed`.
- A release moves `[Unreleased]` into a versioned section and bumps `version:` in `pubspec.yaml` (`chore(release): <version>`); only do so when asked.

## Pull requests

Opening or updating a PR (title, template, size, `gh pr create`): read `references/pull-requests.md`.
A PR title must itself be a valid header; every non-merge commit subject on the branch is validated too.
