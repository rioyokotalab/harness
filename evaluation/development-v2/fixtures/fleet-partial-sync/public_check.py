import json
from pathlib import Path


result = json.loads(Path("result.json").read_text(encoding="utf-8"))
assert result == {
    "schema": 1,
    "source": "rev-cobalt",
    "target": "rev-umber",
    "nodes": [
        {"name": "birch", "action": "advance"},
        {"name": "cedar", "action": "retain"},
        {"name": "dahlia", "action": "refuse"},
    ],
}
ledger = Path("TODO.md").read_text(encoding="utf-8")
assert "Sync reconciliation: complete" in ledger
assert "evidence/completed.json" in ledger
print("fleet-partial-sync public check: pass")
