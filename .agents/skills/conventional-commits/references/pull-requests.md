# Pull requests

- **PR title**: must itself be a valid Conventional Commit header (same rules and whitelist). If the PR
  has a single commit, reuse its header. If it has several, write one header that summarizes the whole
  change, with the type of the most significant change.
- **Commits in the PR**: every non-merge commit subject on the branch is validated too, so make sure each
  one complies before pushing (`git log --no-merges --format=%s origin/main..HEAD`). Fix offenders
  with an interactive-free approach (e.g. `git commit --amend` for the last commit) or ask the user.
- **PR description**: fill in `.github/PULL_REQUEST_TEMPLATE.md`:
  - *Summary* - the change, why, and its user-facing effect; `Closes #XYZ` for the related issue.
  - *Testing* - the checks that ran and the platforms and devices tested; name the ones that did not run.
  - *Checklist* - tick only what is true.
    Never tick the Contributor License Agreement box: it is the contributor's electronic signature, so leave it for the user.
- **Size**: one concern per PR, under about 300 changed lines excluding `pubspec.lock` and `flutter gen-l10n` output; propose a chain of smaller PRs when a change is larger.
- **Discussion**: a `feat` or `refactor` PR needs a prior issue (`CONTRIBUTING.md`); link it.
- **CI**: the `iOS` workflow runs on pull requests only for changes to `ios/**`, `lib/**`, the pubspec files, `.flutter-version`, `test/fixtures/**` or `integration_test/**`; mention it in *Testing* when it did not run.
- Base branch is `main`. Create the PR with `gh pr create --title "<header>" --body "<filled template>"`.
  Pushing and opening a PR are outward-facing: only do so when the user asked.
