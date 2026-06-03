# Scenario 02 — Foundry with external services (public network)

Public-network Foundry deployment with the full BYO connected-services set wired in: Storage, Cosmos, AI Search, Key Vault, and Application Insights. All connections live on the **Foundry account** so every project on the account inherits them.

This is the public-network sibling of scenario 03. Same data resources, same project capability host pattern, but no VNet / no private endpoints / `publicNetworkAccess = Enabled` everywhere.

## What this deploys

| Group | Resource | Purpose |
|---|---|---|
| Data plane | Storage account (`st…`) | StorageV2 / ZRS / TLS1.2 / shared keys off / public network enabled / AAD only. |
| | Cosmos DB (`cosno-…`) | NoSQL, Session consistency, local auth disabled, public network enabled. |
| | AI Search (`srch-…`) | Standard SKU, system identity, public network enabled. |
| | Key Vault (`kv-…`) | Standard SKU, RBAC mode, public network enabled, soft-delete 7 days, no purge protection. |
| | Log Analytics workspace (`log-…`) | PerGB2018, 30-day retention. App Insights workspace target. |
| | Application Insights (`appi-…`) | Workspace-based (LAW above), `web` application type. |
| Foundry | Account (`cog-…`) | `AIServices` kind, `allowProjectManagement=true`, `disableLocalAuth=true`, `publicNetworkAccess=Enabled`. No `networkInjections`. |
| | `gpt-4o` deployment | Tunable via `gpt4o_*` vars (default `GlobalStandard`, capacity `50`). |
| | `text-embedding-3-large` deployment | Tunable via `embedding_*` vars (default `Standard`, capacity `50`). |
| | Account-scoped connections | `AzureStorageAccount`, `CosmosDb`, `CognitiveSearch`, `AzureKeyVault`, `AppInsights` — all `isSharedToAll: true` so every project inherits them by name. |
| | Account capability host | Empty `Agents` kind — documented prerequisite for the project capability host. |
| | Project (`proj-…`) | System-assigned identity. |
| | Project capability host | Wires the inherited Storage / Cosmos / Search connection names as `storageConnections` / `threadStorageConnections` / `vectorStoreConnections`. KV and App Insights connections aren't part of the capability host triad — they're available to agents via inheritance only. |
| RBAC | Foundry account SMI → KV | `Key Vault Secrets User` (required because the KV connection uses `authType = AccountManagedIdentity`). |
| | Foundry User role | Assigned at the Foundry account scope to entries in `var.foundry_users`. |
| | Project SMI pre-host | Cosmos DB Operator, Storage Blob Data Contributor, Search Index/Service Contributor — needed before the capability host provisions containers / role defs. |
| | Project SMI post-host | Cosmos SQL Built-in Data Contributor, ABAC-scoped Storage Blob Data Owner on `*-azureml-agent` containers under the project's GUID. |

Foundry API: `2026-03-01`. Capability host API: `2025-04-01-preview`. Connections API: `2026-03-01`.

## Module layout

```text
scenarios/02-external-services/
├── providers.tf, variables.tf, main.tf, outputs.tf, terraform.auto.tfvars
└── modules/
    ├── data-resources/     # Storage + Cosmos + AI Search + KV + LAW + App Insights
    ├── foundry-account/    # Account + 2 model deployments + 5 account-scoped connections
    │                       # + Foundry User RBAC + account capability host + destroy-time purge
    └── foundry-project/    # Project + pre/post-host RBAC + project capability host
```

Module composition lives in [`main.tf`](./main.tf). Each child module has its own `variables.tf` / `main.tf` / `outputs.tf` and declares its own `required_providers` block.

## Naming (Microsoft CAF)

Resources follow `<abbr>-<workload>-<scenario>-<env>-<region>-<instance>`. With defaults:

| Resource | Name |
|---|---|
| Resource group | `rg-foundry-s02-dev-wus3-001` |
| Foundry account | `cog-foundry-s02-dev-wus3-001` |
| Foundry project | `proj-foundry-s02-dev-wus3-001` |
| Cosmos DB | `cosno-foundry-s02-dev-wus3-001` |
| AI Search | `srch-foundry-s02-dev-wus3-001` |
| Storage account | `stfoundrys02devwus3001` (flattened — `st` + base name minus hyphens, ≤24 chars) |
| Key Vault | `kv-foundrys02devwus3001` (flattened — KV name must be ≤24 chars) |
| Log Analytics | `log-foundry-s02-dev-wus3-001` |
| Application Insights | `appi-foundry-s02-dev-wus3-001` |

## Why account-scoped connections?

Scenario 03 puts connections on the project. This scenario puts them on the account so every project on the account inherits them automatically. Per Microsoft docs:

> Connections defined at the account level are inherited by new projects. However, the project capability host configuration is not inherited. To use those connections with Agent Service, you must create a project capability host that explicitly references the project-level connections.

So we still create a project capability host that names the connections explicitly — inheritance just means we don't redefine the connection on every project.

## State

`cmhtfstatesa` (RG `RG-TF`), container `tfstate`, key `foundry-examples/02-external-services.tfstate`. AAD auth, shared keys disabled.

## Destroy notes

- **Foundry account**: soft-deleted on destroy; the destroy-time `purge_on_destroy` action removes the soft-deleted record so the name can be reused immediately. Cooldown is 60s (much shorter than scenario 03's 900s — no VNet SAL to release).
- **Key Vault**: soft-deleted with a 7-day retention. The `azurerm` provider's `purge_soft_delete_on_destroy = true` flag in `providers.tf` purges it on destroy.

## Local run

```powershell
az login
terraform init
terraform plan
terraform apply
```

## CI

Triggered by the repo-level [`deploy.yml`](../../.github/workflows/deploy.yml) workflow:

- PR touching `scenarios/02-external-services/**` → plan, posted as PR comment.
- Merge to `main` touching the same path → apply, gated by the `scenario-02-dev` GitHub Environment.
- Manual `workflow_dispatch` → tick the **scenario_02** checkbox and choose plan or apply.

## Post-deploy

Assign developers who want to create/edit agents in this project the **Foundry User** role on the project scope.
