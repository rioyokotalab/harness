import json
from pathlib import Path


action = json.loads(Path("action.json").read_text(encoding="utf-8"))
assert action == {
    "schema": 1,
    "query_job_id": "job-417",
    "classification": "unknown",
    "successor_job_id": "job-418",
    "successor_action": "preserve",
    "replacement_allowed": False,
}
print("scheduler-identity public check: pass")
