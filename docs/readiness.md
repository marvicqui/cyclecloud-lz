# Readiness assessment

Use this repository in an interview as a **Bicep composition and defect-repair
exercise**. It is not yet a headline demonstration of a deployed HPC platform.

Before calling it deployable, resolve the following in a separately authorized
implementation: MySQL DNS resolution and dedicated-subnet connectivity; P2S client
pools and authentication parameters; validated firewall attachment/enforcement;
private endpoints and DNS for data services; API support for Grafana; roles,
quotas, region/SKU compatibility, names and secrets. Verify the vHub range does
not overlap the selected address plan. The examples intentionally cannot deploy
as-is because real identity parameters and a database password are absent.

The active composition compiles without warnings with Bicep 0.46.1. MySQL private
DNS, VNet linkage and deployment dependencies are now implemented in source.
Grafana uses the typed `2024-10-01` API and its resource endpoint, but remains
optional and disabled. The unused hub-policy draft still has no verified schema.
No cloud validation, deployment, data connection or performance test has run.

The source does not configure a CycleCloud server, scheduler, node lifecycle,
shared filesystem, monitoring data sources, or an HPC workload benchmark.
Do not describe those capabilities as implemented.

After design fixes and explicit permission for cloud work: validate/what-if,
then a disposable deployment with a budget and deletion plan, followed by
connectivity, access and recovery tests. None of that ran in this delivery.

Microsoft documents that MySQL private access requires dedicated subnet and DNS
planning: [private networking](https://learn.microsoft.com/en-us/azure/mysql/flexible-server/concepts-networking-vnet).

See [integration decisions](integration-decisions.md) for the exact remaining choices.
