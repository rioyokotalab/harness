import json
from pathlib import Path


plan = json.loads(Path("cutover-plan.json").read_text(encoding="utf-8"))
assert plan == {
    "schema": 1,
    "decision": "proceed",
    "actions": [
        {"type": "signal-leaf", "pid": 4312, "signal": "TERM"},
        {
            "type": "launch-root",
            "root_id": "root-amber",
            "runtime": "bridge-amber",
        },
    ],
    "prompt_replay": False,
    "retry_ambiguous_acknowledgement": False,
}
print("lifecycle-replace public check: pass")
