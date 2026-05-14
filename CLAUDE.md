# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository status

This repository is currently **empty** — no source code, configuration, or documentation has been committed yet. The repository name (`MiYueControl4Driver`) suggests a Control4 home-automation driver, but no project files exist to confirm language, framework, or architecture.

If asked how to build, test, or run anything, state plainly that no source exists yet. Do not invent commands, file layouts, or architecture before the corresponding code is in the repository.

## What to do on first real commit

When source code is first added, this file should be replaced with concrete guidance. At minimum, document:

1. **Build / run / test commands** — including how to run a single test.
2. **High-level architecture** — the "big picture" that requires reading multiple files to grasp (entry points, module boundaries, data flow, key abstractions).
3. **Project-specific conventions** — anything non-obvious about how this codebase is organized or extended. For a Control4 driver this typically means: Lua entry points and lifecycle callbacks (`OnDriverInit`, `OnDriverLateInit`, `ReceivedFromProxy`, etc.), the `driver.xml` manifest, the `.c4z` packaging layout, target device protocol (TCP/serial/HTTP), and any sandbox/runtime constraints — but only document what the code actually uses.
4. **Important parts of any README, `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md`** if those files are added.

Do not invent any of the above before the code exists.

## Branch convention

Development for the current Claude-assisted task happens on `claude/add-claude-documentation-GZCwq`. Push to that branch; do not push to `master`/`main` without explicit instruction.
