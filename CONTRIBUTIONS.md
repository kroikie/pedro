# Contribution Guidelines

To maintain structure and consistency across the repository, all contributors (both human developers and AI agents) must follow these guidelines when creating branches, working with worktrees, submitting pull requests, and triggering releases.

---

## Branch Naming Convention

All branches created in this repository must follow the format:

```
<github-username>/<feature-or-fix-name>
```

> [!IMPORTANT]
> The `<github-username>` prefix must be your **GitHub username** (e.g. `kroikie`), not your local system machine username.

### Examples:
* Feature branch: `kroikie/score-board-redesign`
* Bug fix branch: `kroikie/fix-trump-selection`
* Docs branch: `kroikie/docs-how-to-play`

---

## Parallel Worktree Workflow

To prevent workspace collisions, open editor disruptions, and dirty working trees, all coding work is performed in isolated **Git Worktrees** rather than switching branches in the primary workspace root.

### 1. Create a Worktree
Use the helper script to create an isolated worktree based on the latest `origin/master`:
```bash
./scripts/worktree.sh create <feature-or-fix-name>
```
*Example:* `./scripts/worktree.sh create score-board` creates branch `kroikie/score-board` in `.worktrees/score-board`.

### 2. Implement, Build & Test
Navigate into the worktree:
```bash
cd .worktrees/<feature-or-fix-name>
```
Run tests for the affected components before requesting review or opening a PR:
```bash
# Flutter Client
cd app && flutter test
flutter build web

# Cloud Functions
cd ../functions && dart test
```

### 3. Reviewer Verification (Hybrid Protocol)
- Code changes must be audited against the **6 Review Pillars** (Requirements & Game Rules, Documentation, Code Quality & Architecture, Test Coverage & Full Compilation, Generated Code Sync, and Security).
- When working with AI agents, the dedicated `pr_reviewer` subagent audits the `git diff origin/master` prior to PR creation.
- For Cloud Functions additions or modifications, ensure the function is wired in `functions/bin/server.dart` and `functions/functions.yaml` is regenerated via `dart run build_runner build`.

### 4. Pull Request & Auto-Merge
1. Push the branch and create a PR:
   ```bash
   git push -u origin <github-username>/<feature-or-fix-name>
   gh pr create --fill
   ```
2. Enable auto-merge:
   ```bash
   gh pr merge --auto --squash --delete-branch
   ```
3. Post the review report directly to the PR comments:
   ```bash
   gh pr review <pr-number> --comment -b "<review-report>"
   ```
4. Once all CI checks in `pr-check.yml` pass, GitHub automatically squash-merges the PR into `master`.

### 5. Cleanup
After the PR is submitted and auto-merge is active, remove the local worktree and branch:
```bash
./scripts/worktree.sh clean <feature-or-fix-name>
```

---

## Local Testing & Beta Distribution

### 1. Synchronize Master On Demand
Local `master` in the root workspace is deliberately left untouched during task execution to prevent disrupting uncommitted work or running servers.
When a PR auto-merges, synchronize your root workspace with a single safe command:
```bash
./scripts/worktree.sh sync
```
*(This verifies your root workspace has no uncommitted changes before fast-forwarding `master` to `origin/master`.)*

### 2. Triggering Automated Beta Distribution
Releases to Android and iOS beta testers are distributed via Firebase App Distribution by pushing a release tag:
```bash
git checkout master
git pull --ff-only origin master
git tag v1.X.Y
git push origin v1.X.Y
```
Pushing a `v*` tag triggers the `.github/workflows/distribute_beta.yml` workflow, which:
- Automatically resolves tester UDIDs from Firebase and registers them on Apple Developer Portal via Fastlane.
- Re-bakes the `com.ool.pedro AdHoc` provisioning profile and builds the signed iOS `.ipa`.
- Decodes Android release keystore credentials, builds the release `.apk`, and uploads to Firebase App Distribution for the `beta-testers` group.
