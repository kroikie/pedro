# Implementation Rules & Agent Protocols

## General Rules

- When implementing a new feature or bug fix, you must follow the instructions in [CONTRIBUTIONS.md](../CONTRIBUTIONS.md).
- When adding a new user-facing feature (such as a new lobby screen, card interaction, scoring display, or game rule change), always update the documentation in [website/docs/](../website/docs/) to reflect the update.
- Refer to [Pedro.md](../Pedro.md) for official rules, bidding mechanics, point values, and card game lifecycle details.
- Refer to [Sprints.md](../Sprints.md) for milestone goals, sprint boundaries, and acceptance criteria.

---

## Architectural Guidelines

- **Data / UI Layer Separation:**
  - Maintain a strict boundary between `app/lib/data/` (data models, repositories, Firebase services) and `app/lib/ui/` (widgets, screens, overlays, animations).
  - UI widgets must not perform direct database or Cloud Function mutations; they must delegate through repository interfaces.
- **Server-Side Game Logic & Cloud Functions:**
  - Game state transitions (bidding closure, trump selection, card play validation, lift resolution, round scoring) are orchestrated server-side in `functions/` to prevent client-side manipulation.
  - Whenever a function in `functions/` is added or updated:
    - Register it in [functions/bin/server.dart](../functions/bin/server.dart).
    - Regenerate `functions/functions.yaml` by running `dart run build_runner build` in `functions/`.
    - Cloud Functions are deployed via [deploy_functions.sh](../deploy_functions.sh), which relies on `functions.yaml`.
- **AI Integration Guidelines:**
  - **Client-Side "Inner Voice" (Firebase AI Logic):** Hand analysis, bid recommendations, optimal card hints, and funny game room names are evaluated client-side via Firebase AI Logic.
  - **Server-Side "Global Narrator" (Genkit):** Real-time broadcast commentary, banter, and game summaries run server-side in Cloud Functions via Genkit.
- **Security Rules:**
  - Ensure [firestore.rules](../firestore.rules) and [storage.rules](../storage.rules) are updated whenever schema changes occur. Unauthenticated access is strictly prohibited.

---

## Parallel Worktree & Two-Agent Review Protocol (Hybrid Flow)

To enable parallel task execution and protect `master`, all coding tasks must follow this workflow:

### 1. Worktree Isolation
- Never implement features, fixes, or switch branches directly in the primary workspace root (`/Users/arthurthompson/src/pedro`).
- Always create an isolated worktree under `.worktrees/<task-slug>` based on `origin/master`:
  ```bash
  ./scripts/worktree.sh create <task-name>
  ```
- Branch naming must strictly follow [CONTRIBUTIONS.md](../CONTRIBUTIONS.md): `kroikie/<feature-or-fix-name>`.

### 2. Scoped Build, Implementation & Testing
- In the worktree, only bootstrap and build the subprojects affected by the change (e.g. `app` for client changes; `functions` for backend; `website` for documentation).
- Implement changes following repository patterns.
- **Diff Self-Audit (Author Obligation):** Before requesting review, the Author Agent must carefully inspect `git diff origin/master` and proactively fix common issues:
  - **Missing Imports:** Verify every file referencing newly introduced symbols explicitly imports them.
  - **Duplicate Arguments & Declarations:** Audit all multi-line code replacements for duplicated constructor arguments or duplicate variable declarations in the same lexical scope.
  - **Undefined Getters & Incomplete Widgets:** Ensure no working form inputs or UI components are replaced with undefined getters or partial implementations.
- **Full Module Compilation Verification:** Running isolated unit tests (`flutter test test/some_test.dart`) only compiles files transitively imported by those specific tests. The Author Agent must verify that the entire modified project compiles cleanly with 0 errors before requesting review:
  ```bash
  # For app/ changes: verify complete web compilation
  cd app && flutter build web
  flutter test

  # For functions/ changes: verify build runner and tests
  cd ../functions && dart run build_runner build
  git diff --exit-code functions.yaml
  dart test
  ```

### 3. Dedicated Reviewer Subagent Audit
- Prior to pushing or opening a PR, the Author Agent must invoke the dedicated reviewer subagent (`pr_reviewer` defined in `.agents/agents/pr_reviewer.md`).
- Reference [.agents/models.json](models.json) for active model assignments:
  - **Author Agent:** Powered by `Gemini 3.8 Flash (High)` for fast editing, building, and test execution backed by high reasoning.
  - **Reviewer Subagent:** Powered by `Claude Sonnet 4.6 (Thinking)` (`pro` subagent tier) for deep architectural review.
- The Author Agent passes the task prompt/requirements, the `git diff origin/master`, and compilation logs to the reviewer.
- The Reviewer Subagent audits the changeset against the **6 Review Pillars**:
  - **Pillar 0:** Intent & Requirement Fulfillment (game rules, bidding, scoring, lifts, widget/form regression check)
  - **Pillar 1:** Project Rule Compliance (`website/docs/` documentation updated, branch naming followed)
  - **Pillar 2:** Code Quality & Architecture (Data/UI separation, Cloud Functions server wiring, controllers disposed, import integrity, zero duplicate declarations)
  - **Pillar 3:** Test Coverage & Full Compilation Verification (tests present and passing; full module compilation verified via `flutter build web` or `dart test`)
  - **Pillar 4:** Generated Code & Schema Sync (`functions.yaml` and `dart_mappable` code generators up to date)
  - **Pillar 5:** Security & Data Protection (Firestore/Storage security rules, callable auth checks, zero secrets hardcoded, no plaintext PII logging)
- If the reviewer issues `REQUEST CHANGES`, the Author Agent addresses the feedback in the worktree and re-requests review.

### 4. PR Submission & Hybrid Review Posting
- Once the Reviewer Subagent issues an `APPROVE` verdict:
  1. Commit and push the branch to origin:
     ```bash
     git push -u origin <branch-name>
     ```
  2. Create the pull request:
     ```bash
     gh pr create --fill
     ```
  3. Enable auto-merge:
     ```bash
     gh pr merge --auto --squash --delete-branch
     ```
  4. **Hybrid Review Posting:** Immediately post the full Reviewer Subagent verdict, checklist, and sign-off directly to the PR comments:
     ```bash
     gh pr review <pr-number> --comment -b "<reviewer-details-and-checklist>"
     ```

### 5. Worktree Cleanup & Root Workspace Protection
- Once the PR is submitted and auto-merge is active, clean up the local worktree and branch:
  ```bash
  ./scripts/worktree.sh clean <task-name>
  ```
- **Do not pull or alter the root workspace checkout automatically:** The primary repository root (`/Users/arthurthompson/src/pedro`) is deliberately left untouched so in-flight developer tasks, local servers, or uncommitted files are never disrupted.
- The developer synchronizes local `master` on demand whenever ready using:
  ```bash
  ./scripts/worktree.sh sync
  ```

---

## Automated Mobile Distribution Protocol (Capiche Flow)

Releases to beta testers for Android and iOS are fully automated via Firebase App Distribution:

1. **Triggering a Beta Release:**
   - Synchronize local `master`:
     ```bash
     ./scripts/worktree.sh sync
     ```
   - Tag the release:
     ```bash
     git tag v1.X.Y
     git push origin v1.X.Y
     ```
2. **CI Pipeline Execution (`.github/workflows/distribute_beta.yml`):**
   - **Dynamic Runner Resolution:** Uses self-hosted Linux runners for backend functions and Android builds (`[self-hosted, linux]`), falling back to cloud runners (`ubuntu-latest` and `macos-15`).
   - **Google Cloud WIF:** Keyless authentication to GCP via Workload Identity Federation.
   - **Backend Functions Pipeline:** Runs on self-hosted Linux runner; verifies `functions.yaml` code generation, runs unit tests (`dart test`), and deploys Cloud Functions to Firebase (`./deploy_functions.sh`).
   - **Android Pipeline:** Runs sequentially on the self-hosted Linux runner once functions deployment succeeds; decodes release keystore, signs APK, and uploads directly to Firebase App Distribution for `beta-testers`.
   - **iOS Pipeline:** Gated on successful functions deployment; Fastlane pulls registered device UDIDs from Firebase (`firebase_app_distribution_get_udids`), registers new devices with Apple Developer Portal (`register_devices`), re-bakes the `com.ool.pedro AdHoc` profile (`sigh`), builds the IPA, and distributes it to `beta-testers`.
3. **Local Distribution:**
   - For ad-hoc local testing or offline distribution:
     ```bash
     ./scripts/distribute/deploy_android_beta.sh
     ./scripts/distribute/deploy_ios_beta.sh
     ```
