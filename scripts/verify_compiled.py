"""Verify the emitted ARM graph offline; not a deployment or connectivity test."""
import json
from pathlib import Path
import sys


def require(condition, message):
    if not condition:
        raise ValueError(message)


def named(template, name):
    return next(resource for resource in template['resources'] if resource.get('name') == name)


def verify(template, examples):
    password = template['parameters']['mysqlAdminPassword']
    require(password['type'].lower() == 'securestring' and 'defaultValue' not in password,
            'Password must be secure and required')
    for supplied in examples:
        require(not (supplied.keys() - template['parameters'].keys()), 'Unknown example parameter')
        required = {key for key, spec in template['parameters'].items() if 'defaultValue' not in spec}
        require(required - supplied.keys() == {'mysqlAdminPassword'}, 'Example missing required parameter')
    rg = named(template, 'rg-lz')
    require('.outputs.principalId.value' in rg['properties']['parameters']['uamiPrincipalId']['value'],
            'Role principal must come from the identity module')
    composition = rg['properties']['template']
    dns = named(composition, 'mysql-dns')
    database = named(composition, 'mysql')
    db_template = database['properties']['template']
    server = next(r for r in db_template['resources'] if r['type'] == 'Microsoft.DBforMySQL/flexibleServers')
    net = server['properties']['network']
    require(net.get('publicNetworkAccess') == 'Disabled', 'MySQL public access must remain disabled')
    require(net.get('privateDnsZoneResourceId') == "[parameters('privateDnsZoneId')]", 'Missing MySQL DNS binding')
    require(net.get('delegatedSubnetResourceId') == "[parameters('delegatedSubnetId')]", 'Missing MySQL subnet binding')
    require('.outputs.zoneId.value' in database['properties']['parameters']['privateDnsZoneId']['value'],
            'DNS ID must come from the DNS module')
    dependencies = ' '.join(database.get('dependsOn', []))
    require("'mysql-dns'" in dependencies and "'network'" in dependencies, 'Missing network/DNS deployment dependency')
    link = next(r for r in dns['properties']['template']['resources'] if r['type'].endswith('/virtualNetworkLinks'))
    require(link['properties']['registrationEnabled'] is False, 'DNS autoregistration must stay disabled')
    require(link['properties']['virtualNetwork']['id'] == "[parameters('vnetId')]", 'DNS link targets wrong VNet')
    require('.outputs.vnetId.value' in dns['properties']['parameters']['vnetId']['value'], 'DNS must link the workload VNet')
    require('.fullyQualifiedDomainName' in db_template['outputs']['fqdn']['value'], 'MySQL FQDN must come from Azure')
    graf = named(composition, 'grafana')['properties']['template']
    require(graf['resources'][0]['apiVersion'] == '2024-10-01', 'Grafana API differs from reviewed schema')
    require(graf['outputs']['endpoint']['value'].endswith('.endpoint]'), 'Grafana endpoint must come from Azure')
    require('Microsoft.Network/virtualHubs/hubFirewallPolicies' not in json.dumps(template),
            'Unvalidated firewall attachment returned to active composition')


if __name__ == '__main__':
    root = Path(__file__).resolve().parents[1]
    template = json.loads(Path(sys.argv[1]).read_text())
    verify(template, [json.loads(path.read_text())['parameters'] for path in root.glob('parameters.*.json')])
    print('PASS: private MySQL DNS/subnet/link/dependencies, identity wiring, secure password and service outputs')
