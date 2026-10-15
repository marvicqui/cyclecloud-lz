"""Print the intended synthetic network boundary, without an Azure SDK or CLI."""
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from scripts.check_parameters import validate

root = Path(__file__).resolve().parents[1]
for path in sorted(root.glob('parameters.*.json')):
    result = validate(json.loads(path.read_text()))
    print(f"{path.name}: {result['subnets']} subnets; MySQL -> {result['mysqlSubnetName']} ({result['mysqlPrefix']})")
print('Scaffold only: no CycleCloud server, scheduler, compute cluster, or Azure calls.')
