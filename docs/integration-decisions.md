# Integration decisions and validation boundary

This revision completes source wiring for the existing private-MySQL design.
It does not choose a production topology or authorize Azure spending.

Implemented locally: private DNS zone and VNet link, MySQL subnet/DNS references
and deployment dependencies; no public fallback; identity principal output
wiring; typed Grafana API and actual service endpoint output. The subnet checker
now rejects whole-VNet overlap with the draft vHub, overlapping VNet prefixes,
invalid DNS names and unsupported IPv6 plans. Both examples are synthetic.

The 20 local tests include eight checks of a fresh compiled ARM graph, including
mutations that must be rejected.
Compilation and structural tests do not demonstrate successful Azure provisioning.

| Decision before cloud integration | Options and exact blocker |
| --- | --- |
| Intended demonstration | Keep a local composition lab (current recommendation), or authorize a disposable paid Azure validation. No budget, target subscription or resource lifecycle is approved. |
| MySQL DNS ownership | Current lab creates a per-environment zone. A real shared zone requires an explicit existing-zone contract, owner and VNet-link permission review. VPN/on-premises name resolution needs a separate resolver/forwarder design. |
| Remote access | P2S via reviewed identity or certificates, or remove the unneeded VPN path. Client pools and valid authentication inputs are not provided; the current zeros are placeholders. |
| Firewall | A policy alone is inert. Choose a secured hub or an explicit firewall/NVA and routes only after connectivity requirements and cost review. The unused association draft is not in the active graph. |
| Storage and Key Vault | Select required data subresources, private endpoint subnets, DNS zones and data-plane roles. Restrictive networking currently does not create a usable private data path. |
| Grafana | Leave disabled, or authorize service/version/region and identity/data-source design. A typed resource declaration does not validate access or queries. |
| HPC | CycleCloud server, scheduler, compute lifecycle, image, quotas, shared filesystem and benchmark are absent. A full cluster is a separate project. |

After those decisions and explicit authorization: validate/what-if in the named
subscription, review resource count and costs, then perform a disposable deployment
with an expiry/deletion plan. Only afterward test DNS, routes, least-privilege access,
failure handling and cleanup. None of those operations ran here.

Sources: [MySQL private networking](https://learn.microsoft.com/en-us/azure/mysql/flexible-server/concepts-networking-vnet),
[MySQL resource schema](https://learn.microsoft.com/en-us/azure/templates/microsoft.dbformysql/2023-12-30/flexibleservers),
[Grafana resource schema](https://learn.microsoft.com/en-us/azure/templates/microsoft.dashboard/2024-10-01/grafana).
