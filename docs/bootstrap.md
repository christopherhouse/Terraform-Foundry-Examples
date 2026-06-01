# Bootstrap reference

What was done to wire this repo up to Azure + GitHub. Reproduce in your own environment by swapping the IDs.

## Inputs

| Field | Value |
|---|---|
| Subscription | `8bd05b2f-62c5-4def-9869-f0617ebb3970` |
| Tenant | `76de2d2d-77f8-438d-9a87-01806f2345da` |
| State storage account | `cmhtfstatesa` (RG `RG-TF`, eastus2) — shared keys disabled, TLS1.2 |
| State container | `tfstate` |
| State key prefix | `foundry-examples/` |
| GitHub repo | `christopherhouse/Terraform-Foundry-Examples` |

## Azure AD app registration

```powershell
az ad app create --display-name "tf-foundry-examples-gh" --sign-in-audience AzureADMyOrg
az ad sp create --id <appId>
```

| Field | Value |
|---|---|
| Display name | `tf-foundry-examples-gh` |
| App (client) ID | `a1e77690-7567-4f24-a1fb-98ae718f0bf7` |
| SP object ID | `1cb836d3-99e8-4e7a-92b8-a3d607b9f1bc` |

## Role assignments on the SP

| Role | Scope |
|---|---|
| Contributor | `/subscriptions/8bd05b2f-...` (broad — fine for demo sub; tighten for prod) |
| Storage Blob Data Contributor | `/subscriptions/.../RG-TF/.../cmhtfstatesa` |

No data plane keys; Terraform uses `use_azuread_auth = true` on the backend.

## Federated credentials

Three subjects on the same app reg (issuer `https://token.actions.githubusercontent.com`, audience `api://AzureADTokenExchange`):

| Name | Subject | Used by |
|---|---|---|
| `gh-pull-request` | `repo:christopherhouse/Terraform-Foundry-Examples:pull_request` | PR plan job |
| `gh-main` | `repo:christopherhouse/Terraform-Foundry-Examples:ref:refs/heads/main` | Push-to-main plan job, manual dispatch from main (non-environment jobs) |
| `gh-env-scenario-01-dev` | `repo:christopherhouse/Terraform-Foundry-Examples:environment:scenario-01-dev` | Apply job for scenario 01 |

Each future scenario gets its own `gh-env-scenario-NN-dev` fedcred.

## GitHub repo configuration

### Variables (`gh variable list`)

| Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | `a1e77690-7567-4f24-a1fb-98ae718f0bf7` |
| `AZURE_TENANT_ID` | `76de2d2d-77f8-438d-9a87-01806f2345da` |
| `AZURE_SUBSCRIPTION_ID` | `8bd05b2f-62c5-4def-9869-f0617ebb3970` |

No secrets — OIDC handles auth.

### Environments

| Name | Reviewers | Branch policy |
|---|---|---|
| `scenario-01-dev` | `christopherhouse` (self-review allowed) | `main` only |

Add one new environment per scenario as the repo grows.
