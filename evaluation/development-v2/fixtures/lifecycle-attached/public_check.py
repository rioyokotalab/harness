import json
from pathlib import Path


receipt = json.loads(Path("receipt.json").read_text(encoding="utf-8"))
assert set(receipt) == {
    "schema",
    "action",
    "reason",
    "target_identity",
    "mutation_performed",
}
assert receipt == {
    "schema": 1,
    "action": "defer",
    "reason": "target-attached",
    "target_identity": "window-saffron",
    "mutation_performed": False,
}
print("lifecycle-attached public check: pass")
