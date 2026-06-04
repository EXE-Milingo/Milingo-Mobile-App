# MiLingo Mobile App

AI-Powered Language Learning App.

## Do

- Inspect relevant code and tests before editing.
- Use targeted searches and bounded reads; ignore generated folders (`build/`, `.dart_tool/`, `node_modules/`, `bin/`, `obj/`).
- Make the smallest runnable diff. Avoid unrelated refactors.
- Preserve existing architectural patterns (state mgmt, routing, networking).
- Add or update tests when behavior changes.
- Use PowerShell syntax for commands on Windows.
- After code changes, run the relevant `/verify-*` skill.

## Ask first

- Package installs or upgrades.
- New MCP servers or network-heavy commands.
- Destructive Git or workspace actions.

## Never

- Expose secrets in files, logs, or chat.
- Guess current APIs, versions, schemas, or deprecations. Use Context7 or official docs and cite the URL.

Use `/setup-team` for onboarding and optional personal MCP integrations.
