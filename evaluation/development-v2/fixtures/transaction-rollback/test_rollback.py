import copy
import json

import rollback


with open("receipt.json", encoding="utf-8") as handle:
    receipt = json.load(handle)
matched = {
    "identity": {"pid": 4312, "start_tick": 8801, "instance": "violet-7"},
    "phase": "partial",
    "link": "release-amber",
}
result = rollback.reconcile(copy.deepcopy(matched), receipt)
assert result == {
    "action": "restore",
    "reason": "matched",
    "state": {
        "identity": {"pid": 4312, "start_tick": 8801, "instance": "violet-7"},
        "phase": "ready",
        "link": "release-cobalt",
    },
}
drifted = copy.deepcopy(matched)
drifted["identity"]["start_tick"] = 9902
before = copy.deepcopy(drifted)
refusal = rollback.reconcile(drifted, receipt)
assert refusal["action"] == "refuse"
assert refusal["reason"] == "identity-drift"
assert drifted == before
print("transaction-rollback public check: pass")
