"""Exercise malformed network inputs as well as the committed synthetic examples."""
import copy
import json
import unittest
from pathlib import Path
from scripts.check_parameters import validate

ROOT = Path(__file__).resolve().parents[1]


class NetworkContract(unittest.TestCase):
    def setUp(self):
        self.example = json.loads((ROOT / 'parameters.dev.json').read_text())

    def change(self, key, value):
        data = copy.deepcopy(self.example)
        data['parameters'][key] = {'value': value}
        return data

    def test_examples(self):
        for path in ROOT.glob('parameters.*.json'):
            with self.subTest(path=path.name):
                self.assertEqual(validate(json.loads(path.read_text()))['subnets'], 3)

    def test_missing_subnet(self):
        with self.assertRaisesRegex(ValueError, 'missing'):
            validate(self.change('mysqlSubnetName', 'not-present'))

    def test_workload_delegation(self):
        with self.assertRaisesRegex(ValueError, 'dedicated'):
            validate(self.change('mysqlSubnetName', 'snet-workload'))

    def test_overlapping_subnets(self):
        subnets = dict(self.example['parameters']['subnets']['value'])
        subnets['snet-mysql'] = '10.60.1.0/26'
        with self.assertRaisesRegex(ValueError, 'overlaps'):
            validate(self.change('subnets', subnets))

    def test_outside_vnet(self):
        with self.assertRaisesRegex(ValueError, 'outside'):
            validate(self.change('vnetAddressPrefixes', ['10.90.0.0/16']))

    def test_invalid_cidr(self):
        with self.assertRaises(ValueError):
            validate(self.change('vnetAddressPrefixes', ['10.60.0.1/16']))

    def test_small_mysql_subnet(self):
        subnets = dict(self.example['parameters']['subnets']['value'])
        subnets['snet-mysql'] = '10.60.2.0/30'
        with self.assertRaisesRegex(ValueError, '/29'):
            validate(self.change('subnets', subnets))

    def test_no_inline_password(self):
        with self.assertRaisesRegex(ValueError, 'passwords'):
            validate(self.change('mysqlAdminPassword', 'synthetic-test-only'))

    def test_invalid_mysql_dns(self):
        for zone in ['', 'mysql.database.azure.com', 'demo.example.com', '-demo.mysql.database.azure.com',
                     'a..mysql.database.azure.com', 'A.mysql.database.azure.com', 'x' * 64 + '.mysql.database.azure.com']:
            with self.subTest(zone=zone), self.assertRaisesRegex(ValueError, 'DNS'):
                validate(self.change('mysqlPrivateDnsZoneName', zone))

    def test_vnet_hub_overlap_without_subnet_overlap(self):
        with self.assertRaisesRegex(ValueError, 'VNet address space overlaps'):
            validate(self.change('vnetAddressPrefixes', ['10.0.0.0/8']))

    def test_overlapping_vnet_prefixes(self):
        with self.assertRaisesRegex(ValueError, 'address spaces overlap'):
            validate(self.change('vnetAddressPrefixes', ['10.60.0.0/16', '10.60.1.0/24']))

    def test_ipv4_lab_boundary(self):
        for prefixes in [[], ['fd00::/48']]:
            with self.subTest(prefixes=prefixes), self.assertRaisesRegex(ValueError, 'IPv4'):
                validate(self.change('vnetAddressPrefixes', prefixes))
