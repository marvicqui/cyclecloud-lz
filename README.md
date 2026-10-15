# CycleCloud landing-zone scaffold

An Azure infrastructure composition lab in Bicep. It demonstrates subscription
and resource-group scopes, a managed identity, network segmentation and modular
service definitions. **It does not install Azure CycleCloud or create a working
HPC cluster.** No deployment has been validated for this revision.

The original subscription entry point was an incomplete fragment. This local
revision restores its parameter/resource wiring, fixes invalid nested firewall
loops and makes the MySQL subnet explicit in both synthetic examples.

## Run locally without Azure

Prerequisites: Python 3.12+ and standalone Bicep CLI (validated with 0.46.1).
No subscription, Azure login, password or paid service is needed for these steps.
From the repository root:

```sh
python3 -m unittest discover -s tests -v
python3 scripts/check_parameters.py
python3 examples/offline_demo.py
mkdir -p build
bicep build main.bicep --outfile build/main.json
python3 scripts/verify_compiled.py build/main.json
```

On macOS a sandboxed single-file Bicep executable may need a writable extraction
cache: `DOTNET_BUNDLE_EXTRACT_BASE_DIR=/tmp/bicep-demo-cache bicep ...`.
The tests compile a fresh template; set `BICEP_CLI=/absolute/path/to/bicep` if the
standalone CLI is not on PATH. Compilation validates the Bicep graph; it does not check Azure permissions,
quotas, regional availability, network connectivity or runtime provisioning.
The active composition compiles without warnings with Bicep 0.46.1.

## What is and is not implemented

| Component | Source coverage | Remaining work |
|---|---|---|
| Subscription composition | RG, managed identity, opt-in role arrays, nested RG module | Least-privilege review and deployment validation |
| VNet | One VNet, NSG per subnet, dedicated MySQL delegation | NSG rules, routing and connectivity tests |
| vWAN / vHub / P2S | Draft definitions and VNet connection | Client address pools, identity/cert configuration, routing and validation |
| Firewall | Policy and collection normalization | No Azure Firewall instance; no effective traffic enforcement |
| MySQL | Private-only Flexible Server, delegated subnet, private DNS zone and VNet link | DNS resolution, service provisioning and end-to-end access validation |
| Key Vault / Storage | Restrictive network settings | Private endpoints, DNS, data access and operational wiring |
| Grafana | Typed 2024-10-01 definition, actual endpoint output, disabled in examples | Region/version, authentication, data sources and endpoint validation |
| CycleCloud / scheduler / nodes / ANF | Not implemented | Separate design and implementation |

MySQL waits for the network and DNS/link deployment before creation. Subnet and
DNS IDs are required; there is no public-network fallback. The identity principal
is passed from its module, and service URLs come from resource outputs.

The unvalidated `modules/fwPolicyAssociation.bicep` draft is retained for review
but is no longer invoked. A policy object alone does not enforce network traffic.
A subnet named `AzureBastionSubnet` does not create a Bastion instance.

## Synthetic examples and secrets

`parameters.dev.json` and `parameters.prod.json` are **synthetic examples**, not
working environment configurations. Both use `snet-mysql` separately from
`snet-workload`, zero tenant placeholders, empty role arrays and disabled Grafana.
The filename `prod` is not a production-readiness claim. Original environment
names, tenant issuer and inline password examples have been removed.

`mysqlAdminPassword` remains a required secure Bicep parameter and is deliberately
absent from committed JSON. A future authorized deployment needs a separately
reviewed secret injection mechanism. Do not put a real password into these files.
No deployment commands are provided in this local review quickstart.

See [architecture](docs/architecture.md), [limitations and next steps](docs/readiness.md)
and the [90-second demo](docs/demo.md). [Integration decisions](docs/integration-decisions.md)
separate local work from cloud work that still needs approval. No license file was present at the reviewed
base commit; this change does not invent or grant a license.
