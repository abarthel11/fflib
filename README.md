# fflib Salesforce DX Project

This repository packages fflib Apex libraries, mocks, and supporting metadata so they can be pushed to scratch or sandbox orgs using Salesforce DX. It also contains JavaScript tooling for Lightning Web Components (LWCs) that integrate with the framework.

## Project Layout
- `fflib-source/main/default/classes`: Apex framework code and matching `*Test.cls` suites.
- `fflib-source/main/default/{labels,profiles}`: shared metadata such as custom labels and security profiles.
- `manifest/`: curated `package.xml` files for targeted deployments.
- `config/project-scratch-def.json`: baseline scratch-org shape.
- `scripts/`: helper automation invoked from CI or npm scripts.

## Getting Started
1. Install the Salesforce CLI (`sf`) and Node.js 18+.
2. Clone the repo and install dependencies: `npm install`.
3. Authenticate to a Dev Hub (`sf org login web --set-default-dev-hub`).
4. Create a scratch org: `npm run scratch:create MyAlias`.
5. Push sources: `sf project deploy start --source-dir fflib-source --target-org MyAlias`.

## Common Commands
- `npm run lint`: ESLint for Aura/LWC JavaScript.
- `npm run prettier` / `npm run prettier:verify`: enforce formatting across Apex, JS, XML, and docs.
- `npm test`: runs `sfdx-lwc-jest` specs (`npm run test:unit:watch` while iterating).
- `sf apex run test --tests fflib_SObjectDomainTest --target-org MyAlias`: executes Apex tests in an org.
- `npm run scratch:delete MyAlias`: delete the scratch org when finished.

## Testing
- Apex: keep feature tests beside implementation classes (`fflib_Unit.cls` plus `fflib_UnitTest.cls`). Use `sf apex run test --code-coverage` to confirm ≥90% coverage on selectors, domains, and UnitOfWork services.
- LWCs: add Jest files under `lwc/<component>/__tests__`; rely on `npm test` locally and in CI. Commit snapshots to prevent regressions.

## Contributing
Follow the detailed contributor handbook in [`AGENTS.md`](AGENTS.md) for structure conventions, coding style, testing expectations, and pull-request requirements. Align commits with the documented guidelines and note any org validation steps in PR descriptions.
