# Repository Guidelines

## Project Structure & Module Organization
- Apex sources live under `fflib-source/main/default`. `classes/` holds framework code and `*Test.cls` companions, `labels/` stores custom labels, and `profiles/` guards metadata visibility. Use `manifest/package.xml` when deploying subsets, and keep scratch definitions in `config/project-scratch-def.json`. Utility scripts and CI helpers belong in `scripts/`; JavaScript tooling config sits in the repo root (`jest.config.js`, `package.json`).

## Build, Test, and Development Commands
- `npm run lint` runs ESLint on Aura/LWC JavaScript. Gate UI contributions with it.
- `npm run prettier` (or `prettier:verify`) enforces formatting across Apex, metadata, and docs.
- `npm test` delegates to `npm run test:unit`, which executes `sfdx-lwc-jest` for Lightning unit tests; add `:watch` or `:coverage` when iterating.
- Use `sf project deploy start --source-dir fflib-source` for metadata pushes, and `sf apex run test --tests fflib_SObjectDomainTest` to validate Apex suites before review.
- Spin up scratch orgs via `npm run scratch:create MyAlias` and tear them down with `npm run scratch:delete MyAlias` once testing completes.

## Coding Style & Naming Conventions
- Apex: rely on `prettier-plugin-apex`; keep classes and files `PascalCase` with `Test` suffix for unit tests. Methods use lowerCamelCase, prefer explicit interfaces (`fflib_ISObjectSelector`).
- JavaScript (LWC/Aura): follow the Salesforce ESLint presets; use 2-space indentation and single quotes unless template syntax demands otherwise.
- Metadata filenames must match API names exactly; avoid ad-hoc prefixes beyond the established `fflib_` namespace.

## Testing Guidelines
- Apex tests live beside their implementation (`fflib_SObjectSelector.cls` / `fflib_SObjectSelectorTest.cls`). Name methods `testMethodName_StateUnderTest_ExpectedResult` for readability.
- Maintain high coverage for public framework entry points; target ≥90% on selectors, domains, and UnitOfWork to keep managed package ready.
- For LWCs, add Jest specs under `lwc/<component>/__tests__`. Use descriptive `it('renders empty state')` cases and keep snapshots committed.

## Commit & Pull Request Guidelines
- Craft imperative commit titles under 72 chars (current history shows short, lowercase summaries). Reference the affected module, e.g., `Add matcher for platform events`.
- PRs should summarize behavioral changes, list validation steps (`npm test`, `sf apex run test`), and link related Issues or Work Items. Attach org screenshots when altering UI metadata and include deployment notes if new permissions or labels are introduced.
