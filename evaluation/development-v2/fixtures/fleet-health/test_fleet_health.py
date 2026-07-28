import json

import fleet_health


with open("registry.json", encoding="utf-8") as handle:
    registry = json.load(handle)
summary = fleet_health.summarize(registry, "2042-06-10T10:00:00Z")
assert summary == {
    "nodes": [
        {"name": "moss", "status": "ready"},
        {"name": "ridge", "status": "ready"},
        {"name": "delta", "status": "ready"},
        {"name": "studio", "status": "ready"},
        {"name": "quarry", "status": "maintenance"},
    ],
    "ready": 4,
    "maintenance": 1,
    "failed": 0,
}
print("fleet-health public check: pass")
