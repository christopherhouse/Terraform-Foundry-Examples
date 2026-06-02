# Scenario 01 — Basic Foundry deployment

The smallest possible Foundry footprint, used to demonstrate end-to-end CI/CD automation in this repo.

## What this deploys

| Resource | Type | Purpose |
|---|---|---|
| Resource group | `Microsoft.Resources/resourceGroups` | Container for the scenario. |
| Foundry account | `Microsoft.CognitiveServices/accounts` (`kind = AIServices`) | The Foundry account, with `allowProjectManagement = true`, system-assigned managed identity, local auth disabled. |
| Foundry project | `Microsoft.CognitiveServices/accounts/projects` | A single project under the account. |
| gpt-4o deployment | `Microsoft.CognitiveServices/accounts/deployments` | `gpt-4o`, `Standard` SKU, capacity `50` (= 50K TPM). Tunable via `gpt4o_*` vars. |

API version: `2026-03-01` via the `azapi` provider.

## Naming (Microsoft CAF)

Resources follow `<abbr>-<workload>-<scenario>-<env>-<region>-<instance>`:

| Variable | Default |
|---|---|
| `workload` | `foundry` |
| `scenario_id` | `s01` |
| `environment` | `dev` |
| `location` | `eastus2` (abbr `eus2`) |
| `instance` | `001` |

With defaults you get:

- RG: `rg-foundry-s01-dev-eus2-001`
- Account: `cog-foundry-s01-dev-eus2-001`
- Project: `proj-foundry-s01-dev-eus2-001`

## State

Stored in `cmhtfstatesa` (RG `RG-TF`), container `tfstate`, key `foundry-examples/01-basic-foundry.tfstate`. AAD auth — shared keys are disabled on the SA. The CI service principal has **Storage Blob Data Contributor** on the SA.

## Local run

```powershell
az login
terraform init
terraform plan
terraform apply
```

The provider blocks expect `ARM_USE_OIDC` plus the OIDC token env vars in CI; locally, `az login` is enough because azurerm and azapi fall back to Azure CLI auth when OIDC env vars aren't set.

## CI

Triggered by the repo-level [`deploy.yml`](../../.github/workflows/deploy.yml) workflow:

- PR touching `scenarios/01-basic-foundry/**` → plan, posted as PR comment.
- Merge to `main` touching the same path → apply, gated by the `scenario-01-dev` GitHub Environment.
- Manual `workflow_dispatch` → tick the **scenario_01** checkbox and choose plan or apply.
