# fix

When the user says `/fix` or pastes an app screenshot with a bug/UI issue to fix, run the AfroPeep screenshot-fix workflow end-to-end. Follow `.cursor/rules/screenshot-fix-workflow.mdc` exactly.

## Trigger

- `/fix` with an attached screenshot, screen recording, or short description of what is broken
- Optional: user adds context after `/fix` (e.g. `/fix back button missing on settings`)

## Workflow (execute in order)

### 1. Triage (no code yet)

- Describe what is visible in the screenshot (screen name, widgets, text, layout).
- State what is wrong vs what should happen.
- Classify branch type: `fix/` (bug/regression), `feature/` (new capability), `refactor/`, or `chore/`.
- Ask at most 1–2 clarifying questions only if blocked.

### 2. Git setup

From repo root (`pubspec.yaml`):

```bash
git fetch origin
git checkout develop
git pull origin develop
git checkout -b <type>/<short-kebab-description>
```

- Never commit to `develop` or `main` directly.
- Do not commit or push unless the user explicitly asks.
- Production hotfix: branch from `main` instead, PR to `main`, then back-merge to `develop`.

### 3. Investigate

1. Read `PROJECT_CONTEXT.md` if the feature area is unfamiliar.
2. Locate the screen in `lib/features/` (visible text, route, AppBar title).
3. Trace: Screen → Widget → BLoC → Repository → Service/Firebase.
4. Reuse existing patterns; grep for similar fixes.
5. Use Dart MCP for analysis/tests when available.

### 4. Implement

- Minimal diff — fix only the reported issue.
- BLoC for shared/async state; repository pattern for data; no Firestore in widgets.
- Material 3, brand colors (green accents, `#FFF6E5` background), Montserrat.
- `const` where possible; null safety; no hardcoded secrets.

### 5. Verify

```bash
flutter analyze
flutter test
```

Add focused widget/unit tests when the fix is non-trivial. Give numbered manual retest steps for the same screen.

### 6. Report

Reply with:

1. **Root cause** — plain language
2. **Changes** — files + key edits (code citations)
3. **How to verify** — retest steps
4. **Branch name**
5. **Next steps** — offer `/pr` when ready to ship (PR targets `develop`)

This command will be available in chat with `/fix`
