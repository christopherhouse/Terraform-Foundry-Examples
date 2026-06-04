#requires -Version 7.0
# Generates a representative posture.csv with the same schema your real
# `az graph query` command would emit. Deterministic when -Seed is held
# constant.
param(
    [int]$Seed = 42,
    [string]$OutPath = "$PSScriptRoot/posture.csv"
)

$rng = [System.Random]::new($Seed)

function Pick($items, [int[]]$weights) {
    $total = ($weights | Measure-Object -Sum).Sum
    $r = $rng.Next(0, $total)
    $cum = 0
    for ($i = 0; $i -lt $items.Count; $i++) {
        $cum += $weights[$i]
        if ($r -lt $cum) { return $items[$i] }
    }
    return $items[-1]
}

function PickOne($items) { $items[$rng.Next(0, $items.Count)] }

# --- Catalog ---
$subs = @(
    @{ Id = "11111111-1111-1111-1111-111111111111"; Name = "sub-platform-prod";  Env = "prod"    },
    @{ Id = "22222222-2222-2222-2222-222222222222"; Name = "sub-app1-prod";      Env = "prod"    },
    @{ Id = "33333333-3333-3333-3333-333333333333"; Name = "sub-app1-nonprod";   Env = "nonprod" },
    @{ Id = "44444444-4444-4444-4444-444444444444"; Name = "sub-data-prod";      Env = "prod"    },
    @{ Id = "55555555-5555-5555-5555-555555555555"; Name = "sub-sandbox";        Env = "sbx"     }
)

$workloads = @(
    "contoso-shop","contoso-data","contoso-ml","contoso-web","contoso-api",
    "platform-shared","hr-portal","finance-ledger","fabrikam-iot","trader-desk",
    "marketing-cms","claims-engine"
)

$regions = @("eastus","eastus2","westus2","westus3","westeurope","northeurope")

$owners = @(
    "team-platform","team-data","team-ml","team-web","team-finance",
    "team-hr","team-iot","team-security","team-marketing"
)

# Per-type config: count, name prefix, exposure %, tlsBlank, costCenter range
$typeSpecs = @(
    @{ Type="microsoft.storage/storageaccounts";       Count=90; Prefix="st";    NamePattern="flat";   UsesAcls=$true;  UsesTls=$true  },
    @{ Type="microsoft.keyvault/vaults";                Count=45; Prefix="kv-";   NamePattern="dashed"; UsesAcls=$true;  UsesTls=$false },
    @{ Type="microsoft.cognitiveservices/accounts";    Count=25; Prefix="cog-";  NamePattern="dashed"; UsesAcls=$true;  UsesTls=$false },
    @{ Type="microsoft.sql/servers";                   Count=30; Prefix="sql-";  NamePattern="dashed"; UsesAcls=$false; UsesTls=$true  },
    @{ Type="microsoft.documentdb/databaseaccounts";   Count=18; Prefix="cosmos-"; NamePattern="dashed"; UsesAcls=$true; UsesTls=$false },
    @{ Type="microsoft.containerservice/managedclusters"; Count=12; Prefix="aks-"; NamePattern="dashed"; UsesAcls=$false; UsesTls=$false },
    @{ Type="microsoft.web/sites";                     Count=80; Prefix="app-";  NamePattern="dashed"; UsesAcls=$false; UsesTls=$false }
)

# Exposure probabilities (% chance of publicNetworkAccess=Enabled)
$exposureByEnv = @{ prod = 25; nonprod = 60; sbx = 95 }

$rows = New-Object System.Collections.Generic.List[object]
$counters = @{}

foreach ($spec in $typeSpecs) {
    for ($i = 0; $i -lt $spec.Count; $i++) {
        $sub      = PickOne $subs
        $workload = PickOne $workloads
        $region   = PickOne $regions
        $owner    = PickOne $owners
        $env      = $sub.Env

        $key = "$($spec.Prefix)$workload$env"
        if (-not $counters.ContainsKey($key)) { $counters[$key] = 0 }
        $counters[$key]++
        $instance = ('{0:000}' -f $counters[$key])

        # Name
        if ($spec.NamePattern -eq "flat") {
            # Storage accounts: lowercase alphanumeric, <= 24 chars
            $stub = ("$($spec.Prefix)$($workload -replace '-')$env$instance").ToLower()
            $stub = $stub -replace '[^a-z0-9]'
            if ($stub.Length -gt 24) { $stub = $stub.Substring(0, 24) }
            $name = $stub
        } else {
            $name = "$($spec.Prefix)$workload-$env-$instance"
        }

        $rg = "rg-$workload-$env-$region-001"

        # publicNetworkAccess
        $exposureChance = $exposureByEnv[$env]
        $pna =
            if ($rng.Next(0,100) -lt $exposureChance) { "Enabled" }
            elseif ($rng.Next(0,100) -lt 10) { "SecuredByPerimeter" }
            else { "Disabled" }

        # networkAcls default action
        $acls = ""
        if ($spec.UsesAcls) {
            $denyChance = if ($env -eq "prod") { 70 } elseif ($env -eq "nonprod") { 35 } else { 10 }
            $acls = if ($rng.Next(0,100) -lt $denyChance) { "Deny" } else { "Allow" }
        }

        # minTlsVersion
        $tls = ""
        if ($spec.UsesTls) {
            $weakChance = if ($env -eq "prod") { 6 } elseif ($env -eq "nonprod") { 18 } else { 35 }
            $tls = if ($rng.Next(0,100) -lt $weakChance) {
                Pick @("TLS1_0","TLS1_1") @(40,60)
            } else { "TLS1_2" }
        }

        # Tags (JSON-stringified like Resource Graph emits)
        $cc = 1000 + $rng.Next(0, 50)
        $tagObj = [ordered]@{
            environment = $env
            owner       = $owner
            costCenter  = "CC$cc"
        }
        if ($rng.Next(0,100) -lt 60) { $tagObj.Add("workload", $workload) }
        if ($rng.Next(0,100) -lt 30) { $tagObj.Add("dataClassification", (Pick @("public","internal","confidential","restricted") @(15,50,25,10))) }
        $tags = ($tagObj | ConvertTo-Json -Compress)

        $rows.Add([pscustomobject][ordered]@{
            subscriptionId      = $sub.Id
            resourceGroup       = $rg
            name                = $name
            type                = $spec.Type
            location            = $region
            publicNetworkAccess = $pna
            networkAcls         = $acls
            minTlsVersion       = $tls
            tags                = $tags
        })
    }
}

# Salt in a handful of clear-cut posture findings so the agent has obvious
# wins to surface. Each one is intentionally provocative.
$plants = @(
    @{ name="stcontosoprodbackup01";  type="microsoft.storage/storageaccounts"; sub=$subs[1]; rg="rg-contoso-shop-prod-eastus-001"; loc="eastus";    pna="Enabled"; acls="Allow"; tls="TLS1_0"; tags='{"environment":"prod","owner":"team-platform","costCenter":"CC1003","dataClassification":"restricted"}' },
    @{ name="kv-finance-prod-099";    type="microsoft.keyvault/vaults";          sub=$subs[3]; rg="rg-finance-ledger-prod-eastus2-001"; loc="eastus2"; pna="Enabled"; acls="Allow"; tls="";       tags='{"environment":"prod","owner":"team-finance","costCenter":"CC1011","dataClassification":"confidential"}' },
    @{ name="sql-claims-prod-077";    type="microsoft.sql/servers";              sub=$subs[1]; rg="rg-claims-engine-prod-westeurope-001"; loc="westeurope"; pna="Enabled"; acls=""; tls="TLS1_0"; tags='{"environment":"prod","owner":"team-platform","costCenter":"CC1019"}' },
    @{ name="cog-trader-prod-044";    type="microsoft.cognitiveservices/accounts"; sub=$subs[1]; rg="rg-trader-desk-prod-westus2-001"; loc="westus2"; pna="Enabled"; acls="Allow"; tls=""; tags='{"environment":"prod","owner":"team-ml","costCenter":"CC1022","dataClassification":"confidential"}' },
    @{ name="cosmos-hr-prod-012";     type="microsoft.documentdb/databaseaccounts"; sub=$subs[3]; rg="rg-hr-portal-prod-eastus-001"; loc="eastus"; pna="Enabled"; acls="Allow"; tls=""; tags='{"environment":"prod","owner":"team-hr","costCenter":"CC1031","dataClassification":"restricted"}' },
    @{ name="app-marketing-prod-018"; type="microsoft.web/sites";                sub=$subs[1]; rg="rg-marketing-cms-prod-eastus-001"; loc="eastus"; pna="Enabled"; acls=""; tls=""; tags='{"environment":"prod","owner":"team-marketing","costCenter":"CC1015"}' }
)
foreach ($p in $plants) {
    $rows.Add([pscustomobject][ordered]@{
        subscriptionId      = $p.sub.Id
        resourceGroup       = $p.rg
        name                = $p.name
        type                = $p.type
        location            = $p.loc
        publicNetworkAccess = $p.pna
        networkAcls         = $p.acls
        minTlsVersion       = $p.tls
        tags                = $p.tags
    })
}

$rows | Export-Csv -NoTypeInformation -Path $OutPath -Encoding utf8

Write-Host "Wrote $($rows.Count) rows to $OutPath"
$rows | Group-Object type | Sort-Object Count -Descending | Format-Table Count, Name
