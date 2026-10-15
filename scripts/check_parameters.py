"""Validate the scaffold's subnet contract offline, before any Azure operation."""
import ipaddress
import json
import re
import sys
from pathlib import Path


def validate(document):
    params = {key: item['value'] for key, item in document['parameters'].items()}
    if 'mysqlAdminPassword' in params:
        raise ValueError('Do not store database passwords in parameter examples')
    zone = params.get('mysqlPrivateDnsZoneName', '')
    if (len(zone) > 253 or not zone.endswith('.mysql.database.azure.com')
            or any(not re.fullmatch(r'[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?', label)
                   for label in zone.split('.'))):
        raise ValueError('MySQL private DNS zone must be a valid name ending in .mysql.database.azure.com')
    subnet_name = params['mysqlSubnetName']
    subnets = params['subnets']
    if subnet_name not in subnets:
        raise ValueError('MySQL subnet is missing from subnets')
    if subnet_name in ('CycleCloudSubnet', 'snet-workload', 'ComputeNodesSubnet', 'AzureBastionSubnet'):
        raise ValueError('MySQL requires a dedicated subnet, separate from workload nodes')
    vnets = [ipaddress.ip_network(prefix) for prefix in params['vnetAddressPrefixes']]
    if not vnets or any(vnet.version != 4 for vnet in vnets):
        raise ValueError('This lab requires nonempty IPv4 VNet address space')
    for index, vnet in enumerate(vnets):
        if vnet.overlaps(ipaddress.ip_network('10.20.0.0/24')):
            raise ValueError('VNet address space overlaps the draft vHub range')
        if any(vnet.overlaps(other) for other in vnets[index + 1:]):
            raise ValueError('VNet address spaces overlap')
    networks = {name: ipaddress.ip_network(prefix) for name, prefix in subnets.items()}
    for name, subnet in networks.items():
        if not any(subnet.version == vnet.version and subnet.subnet_of(vnet) for vnet in vnets):
            raise ValueError(f'{name} lies outside the VNet')
        if subnet.overlaps(ipaddress.ip_network('10.20.0.0/24')):
            raise ValueError(f'{name} overlaps the draft vHub range')
    entries = list(networks.items())
    for index, (name, subnet) in enumerate(entries):
        for other_name, other in entries[index + 1:]:
            if subnet.overlaps(other):
                raise ValueError(f'{name} overlaps {other_name}')
    mysql = networks[subnet_name]
    if mysql.version != 4 or mysql.prefixlen > 29:
        raise ValueError('MySQL subnet must be IPv4 /29 or larger')
    return {'mysqlSubnetName': subnet_name, 'mysqlPrefix': str(mysql), 'subnets': len(subnets), 'mysqlPrivateDnsZoneName': zone}


if __name__ == '__main__':
    for arg in sys.argv[1:] or ['parameters.dev.json', 'parameters.prod.json']:
        print(f'{Path(arg).name}: {json.dumps(validate(json.loads(Path(arg).read_text())))}')
