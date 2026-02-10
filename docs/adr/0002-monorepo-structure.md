# 2. Monorepo Structure with Manual Versioning

Date: 2026-02-09

## Status

Accepted

## Context

The project consists of multiple components (Firmware, Driver App, Backend) that share domain logic. We need a way to share code while maintaining clear boundaries.

## Decision

We will use a **monorepo structure** with a `packages/` directory for shared logic.
Versioning will be managed **manually** via `CHANGELOG.md` files in each package to avoid complex tooling overhead at this stage.

## Consequences

- Shared logic (e.g., Data Models) can be written once and reused.
- Independent versioning allows components to evolve at their own pace.
- Manual changelogs require discipline but offer flexibility.
