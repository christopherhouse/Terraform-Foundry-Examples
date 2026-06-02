# Scenario 02 — Foundry with private networking

Network-isolated Foundry deployment built around the Standard Agent: VNet-injected Foundry account, private endpoints for every dependency, AAD-only data plane on Cosmos / Storage / Search, and a project-level capability host wiring it all together.

Modeled on Microsoft's [`15a-private-network-standard-agent-setup`](https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-terraform/15a-private-network-standard-agent-setup) reference but reorganized into composable per-concern modules.

## What this deploys

| Group | Resource | Purpose |
|---|---|---|
| Networking | VNet (`vnet-…`) | One /16 with two /24 subnets. |
| | `snet-agent` | Delegated to `Microsoft.App/environments` — host for Standard Agent compute via Foundry's `networkInjections`. |
| | `snet-pe` | Hosts private endpoints. |
| | 6 private DNS zones | `privatelink.{blob.core.windows.net, documents.azure.com, search.windows.net, cognitiveservices.azure.com, services.ai.azure.com, openai.azure.com}` — all linked to the VNet. |
| Data plane | Storage account (`st…`) | StorageV2 / ZRS / TLS1.2 / shared keys off / public network disabled / Deny default rules. |
| | Cosmos DB (`cosno-…`) | NoSQL, Session consistency, local auth disabled, public network disabled. |
| | AI Search (`srch-…`) | Standard SKU, system identity, public network disabled. |
| Foundry | Account (`cog-…`) | `AIServices` kind, `allowProjectManagement=true`, `disableLocalAuth=true`, `publicNetworkAccess=Disabled`, `networkInjections` pointing at `snet-agent`. |
| | `gpt-4o` deployment | Tunable via `gpt4o_*` vars (default `GlobalStandard`, capacity `50`). |
| | `text-embedding-3-large` deployment | Tunable via `embedding_*` vars (default `Standard`, capacity `50`). |
| | Project (`proj-…`) | System-assigned identity, displayName + description. |
| | Project connections | AAD-typed connections to Cosmos, Storage, AI Search. |
| | Project capability host | `Agents` kind wiring connections as `vectorStoreConnections` / `storageConnections` / `threadStorageConnections`. |
| Private endpoints | 4× `azurerm_private_endpoint` | One each for blob, Cosmos (Sql), Search, Foundry account — all in `snet-pe` with DNS zone groups. |
| RBAC | Project SMI role assignments | Cosmos DB Operator, Storage Blob Data Contributor, Search Index Data Contributor, Search Service Contributor on control plane; Cosmos SQL Built-in Data Contributor + ABAC-scoped Storage Blob Data Owner after the capability host provisions containers. |

Foundry API: `2026-03-01`. Capability host API: `2025-04-01-preview` (no GA path yet).

## Module layout

```text
scenarios/02-private-networking/
├── providers.tf, variables.tf, main.tf, outputs.tf, terraform.auto.tfvars
└── modules/
    ├── network/             # VNet + subnets + 6 DNS zones + VNet links
    ├── data-resources/      # Storage + Cosmos + AI Search
    ├── foundry-account/     # Account + model deployments + destroy-time purge
    ├── private-endpoints/   # 4 PEs with DNS zone groups
    └── foundry-project/     # Project + connections + RBAC + capability host
```

Module composition lives in [`main.tf`](./main.tf). Each child module has its own `variables.tf` / `main.tf` / `outputs.tf` and declares its own `required_providers` block.

## Naming (Microsoft CAF)

Resources follow `<abbr>-<workload>-<scenario>-<env>-<region>-<instance>`. With defaults:

| Resource | Name |
|---|---|
| Resource group | `rg-foundry-s02-dev-wus3-001` |
| VNet | `vnet-foundry-s02-dev-wus3-001` |
| Foundry account | `cog-foundry-s02-dev-wus3-001` |
| Foundry project | `proj-foundry-s02-dev-wus3-001` |
| Cosmos DB | `cosno-foundry-s02-dev-wus3-001` |
| AI Search | `srch-foundry-s02-dev-wus3-001` |
| Storage account | `stfoundrys02devwus3001` (flattened — `st` + base name minus hyphens, ≤24 chars) |
| Private endpoints | `pep-{blob,cosmos,search,foundry}-foundry-s02-dev-wus3-001` |

## State

`cmhtfstatesa` (RG `RG-TF`), container `tfstate`, key `foundry-examples/02-private-networking.tfstate`. AAD auth, shared keys disabled.

## Destroy notes

Deleting a Foundry account leaves a soft-deleted record AND a service association link (SAL) on the agent subnet — Terraform can't delete the subnet until the SAL is released. The `foundry-account` module handles this with:

1. `time_sleep.purge_cooldown` — 900s `destroy_duration` between purge and downstream subnet teardown so the platform finishes releasing the SAL.
2. `azapi_resource_action.purge_on_destroy` — `when = destroy` DELETE call against the soft-deleted account record so the name can be reused.

You'll see destroys hang for ~15 min near the end — expected.

## Local run

```powershell
az login
terraform init
terraform plan
terraform apply
```

## CI

Triggered by the repo-level [`deploy.yml`](../../.github/workflows/deploy.yml) workflow:

- PR touching `scenarios/02-private-networking/**` → plan, posted as PR comment.
- Merge to `main` touching the same path → apply, gated by the `scenario-02-dev` GitHub Environment.
- Manual `workflow_dispatch` → tick the **scenario_02** checkbox (combine with `scenario_01` for both) and choose plan or apply.

## Post-deploy

Assign developers who want to create/edit agents in this project the **Foundry User** role on the project scope.
