"""Mutation checks against a fresh compiler output, without Azure or credentials."""
import copy
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from scripts.verify_compiled import named, verify

ROOT = Path(__file__).resolve().parents[1]


class CompiledContract(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with tempfile.TemporaryDirectory() as temp:
            target = Path(temp) / 'main.json'
            subprocess.run([os.environ.get('BICEP_CLI', 'bicep'), 'build', str(ROOT / 'main.bicep'),
                            '--outfile', str(target)], check=True, capture_output=True, text=True)
            cls.compiled = json.loads(target.read_text())
        cls.examples = [json.loads(p.read_text())['parameters'] for p in ROOT.glob('parameters.*.json')]

    def setUp(self):
        self.template = copy.deepcopy(self.compiled)
        self.rg = named(self.template, 'rg-lz')
        self.composition = self.rg['properties']['template']
        self.database = named(self.composition, 'mysql')
        self.server = self.database['properties']['template']['resources'][0]

    def test_compiled_graph(self):
        verify(self.template, self.examples)

    def test_public_database_rejected(self):
        self.server['properties']['network']['publicNetworkAccess'] = 'Enabled'
        with self.assertRaisesRegex(ValueError, 'public access'):
            verify(self.template, self.examples)

    def test_missing_dns_binding_rejected(self):
        del self.server['properties']['network']['privateDnsZoneResourceId']
        with self.assertRaisesRegex(ValueError, 'DNS binding'):
            verify(self.template, self.examples)

    def test_dns_dependency_rejected(self):
        self.database['dependsOn'] = []
        with self.assertRaisesRegex(ValueError, 'dependency'):
            verify(self.template, self.examples)

    def test_autoregistration_rejected(self):
        dns = named(self.composition, 'mysql-dns')['properties']['template']
        dns['resources'][1]['properties']['registrationEnabled'] = True
        with self.assertRaisesRegex(ValueError, 'autoregistration'):
            verify(self.template, self.examples)

    def test_invented_endpoint_rejected(self):
        graf = named(self.composition, 'grafana')['properties']['template']
        graf['outputs']['endpoint']['value'] = 'https://example.invalid'
        with self.assertRaisesRegex(ValueError, 'endpoint'):
            verify(self.template, self.examples)

    def test_identity_bypass_rejected(self):
        self.rg['properties']['parameters']['uamiPrincipalId']['value'] = 'synthetic-id'
        with self.assertRaisesRegex(ValueError, 'principal'):
            verify(self.template, self.examples)

    def test_password_default_rejected(self):
        self.template['parameters']['mysqlAdminPassword']['defaultValue'] = 'synthetic-test-only'
        with self.assertRaisesRegex(ValueError, 'Password'):
            verify(self.template, self.examples)
