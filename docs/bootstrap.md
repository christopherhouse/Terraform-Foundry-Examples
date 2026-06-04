# Bootstrap reference

How to wire a fork of this repo up to Azure + GitHub. This is a step-by-step template — fill in the placeholders with your own subscription, tenant, storage account, and GitHub repo details.

> 📝 **Placeholders used throughout this doc**
>
> | Placeholder | Meaning |
> |---|---|
> | `<subscription-id>` | The Azure subscription you'll deploy scenarios into. |
> | `<tenant-id>` | The Entra tenant the subscription lives in. |
> | `<state-rg>` | Resource group holding the Terraform state storage account (any region). |
> | `<state-sa>` | Storage account name for remote state (globally unique). |
> | `<state-region>` | Region for the state SA — doesn't have to match the scenario regions. |
> | `<github-org>/<github-repo>` | Your fork's path on GitHub. |
> | `<app-display-name>` | Display name for the Entra app registration (e.g. `tf-foundry-examples-gh`). |
> | `<app-client-id>` | App (client) ID returned after creating the app registration. |
> | `<sp-object-id>` | Object ID of the service principal created for the app. |
> | `<reviewer>` | GitHub username (or team) allowed to approve environment deploys. |

## 1. State backend

Create a resource group + storage account for remote state. Container is `tfstate`; one blob per scenario under `foundry-examples/`.

```powershell
az group create --name <state-rg> --location <state-region>

az storage account create `
  --name <state-sa> `
  --resource-group <state-rg> `
  --location <state-region> `
  --sku Standard_LRS `
  --kind StorageV2 `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false `
  --allow-shared-key-access false

az storage container create `
  --name tfstate `
  --account-name <state-sa> `
  --auth-mode login
```

Shared keys are off — Terraform uses `use_azuread_auth = true` on the backend and AAD-authenticates against the SA.

## 2. Azure AD app registration

```powershell
az ad app create --display-name "<app-display-name>" --sign-in-audience AzureADMyOrg
az ad sp create --id <app-client-id>
```

Capture the values:

| Field | Where to find it |
|---|---|
| App (client) ID | `az ad app list --display-name <app-display-name> --query "[0].appId" -o tsv` |
| SP object ID | `az ad sp list --display-name <app-display-name> --query "[0].id" -o tsv` |

## 3. Role assignments on the SP

| Role | Scope | Why |
|---|---|---|
| Contributor | `/subscriptions/<subscription-id>` | Broad — fine for a demo sub. Tighten to the scenario RGs for prod. |
| User Access Administrator | `/subscriptions/<subscription-id>` | Lets the SP create role assignments for the Foundry account/project SMIs. |
| Storage Blob Data Contributor | `/subscriptions/<subscription-id>/resourceGroups/<state-rg>/providers/Microsoft.Storage/storageAccounts/<state-sa>` | AAD-authed state read/write. No data-plane keys. |

```powershell
az role assignment create `
  --assignee <sp-object-id> `
  --role "Contributor" `
  --scope /subscriptions/<subscription-id>

az role assignment create `
  --assignee <sp-object-id> `
  --role "User Access Administrator" `
  --scope /subscriptions/<subscription-id>

az role assignment create `
  --assignee <sp-object-id> `
  --role "Storage Blob Data Contributor" `
  --scope /subscriptions/<subscription-id>/resourceGroups/<state-rg>/providers/Microsoft.Storage/storageAccounts/<state-sa>
```

## 4. Federated credentials

Add federated credentials on the app reg so GitHub Actions can mint Entra tokens via OIDC. Issuer is `https://token.actions.githubusercontent.com`, audience is `api://AzureADTokenExchange`. One fedcred per trust subject:

| Name | Subject | Used by |
|---|---|---|
| `gh-pull-request` | `repo:<github-org>/<github-repo>:pull_request` | PR plan job |
| `gh-main` | `repo:<github-org>/<github-repo>:ref:refs/heads/main` | Push-to-main plan job, manual dispatch from main (non-environment jobs) |
| `gh-env-scenario-01-dev` | `repo:<github-org>/<github-repo>:environment:scenario-01-dev` | Apply job for scenario 01 |
| `gh-env-scenario-02-dev` | `repo:<github-org>/<github-repo>:environment:scenario-02-dev` | Apply job for scenario 02 |

Add one new `gh-env-scenario-NN-dev` fedcred per scenario as the repo grows.

## 5. GitHub repo configuration

### Variables (`gh variable set`)

| Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | `<app-client-id>` |
| `AZURE_TENANT_ID` | `<tenant-id>` |
| `AZURE_SUBSCRIPTION_ID` | `<subscription-id>` |

No secrets are needed — OIDC handles auth.

### Environments

Create one GitHub Environment per scenario, gated on `main`:

| Name | Reviewers | Branch policy |
|---|---|---|
| `scenario-01-dev` | `<reviewer>` | `main` only |
| `scenario-02-dev` | `<reviewer>` | `main` only |

Add one new environment per scenario as the repo grows.

## 6. Wire up the backend in each scenario

Each scenario's `providers.tf` declares its own `backend "azurerm"` block. Update the `storage_account_name`, `resource_group_name`, and `key` values to match the SA you created in step 1. The key convention used in this repo is `foundry-examples/<scenario-folder>.tfstate`.

```hcl
backend "azurerm" {
  resource_group_name  = "<state-rg>"
  storage_account_name = "<state-sa>"
  container_name       = "tfstate"
  key                  = "foundry-examples/01-basic-foundry.tfstate"
  use_azuread_auth     = true
}
```
