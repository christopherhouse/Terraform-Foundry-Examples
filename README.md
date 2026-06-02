# Terraform Foundry Examples

Reference Terraform implementations of Microsoft Foundry deployments for a range of scenarios. Each scenario lives in its own folder under [`scenarios/`](./scenarios) and deploys independently to its own resource group with its own remote state key.

## Scenarios

| # | Folder | Description |
|---|---|---|
| 01 | [`scenarios/01-basic-foundry`](./scenarios/01-basic-foundry) | Minimal Foundry account + project demonstrating end-to-end CI/CD automation. |
| 02 | [`scenarios/02-private-networking`](./scenarios/02-private-networking) | Network-isolated Foundry with VNet-injected Standard Agent, private endpoints for Foundry/Cosmos/Storage/Search, and project capability host. |

## Conventions

- **Naming** — Microsoft [CAF abbreviations](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) with the scenario number embedded (e.g. `rg-foundry-s01-dev-eus2-001`).
- **State** — Remote backend in Azure Storage. One key per scenario under `tfstate/foundry-examples/<scenario-folder>.tfstate`. AAD auth only (shared keys disabled on the SA).
- **Auth** — GitHub Actions authenticates to Azure with OIDC and federated credentials on a single shared app registration.
- **Region** — `eastus2` by default; override per scenario via `variables.tf`.

## CI/CD

A single workflow at [`.github/workflows/deploy.yml`](./.github/workflows/deploy.yml) handles all scenarios:

- **PR** — plans every scenario whose files changed and posts the plan as a PR comment.
- **Push to `main`** — applies every scenario whose files changed (each gated by its own GitHub Environment for approval).
- **Manual run** (`workflow_dispatch`) — pick any combination of scenarios via checkboxes; choose plan-only or apply.

## Bootstrap

The Azure app registration, federated credentials, GitHub environments, and repo variables are pre-provisioned. See [`docs/bootstrap.md`](./docs/bootstrap.md) for the exact commands used so you can reproduce in your own subscription.
