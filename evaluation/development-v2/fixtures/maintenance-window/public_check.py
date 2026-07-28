import json
from pathlib import Path


result = json.loads(Path("maintenance.json").read_text(encoding="utf-8"))
assert result == {
    "schema": 1,
    "nodes": [
        {
            "name": "opal",
            "classification": "scheduled",
            "interval": {
                "start": "2042-08-03T09:00:00+09:00",
                "end": "2042-08-03T17:00:00+09:00",
                "boundary": "half-open",
            },
            "backup_interval": {
                "start": "2042-08-24T09:00:00+09:00",
                "end": "2042-08-24T17:00:00+09:00",
                "boundary": "half-open",
            },
        },
        {"name": "lichen", "classification": "unknown"},
    ],
}
print("maintenance-window public check: pass")
