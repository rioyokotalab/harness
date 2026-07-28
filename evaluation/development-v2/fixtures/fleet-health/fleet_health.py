"""Summarize an offline fleet registry."""


def summarize(registry, now):
    """Return canonical node statuses and aggregate counts."""
    nodes = []
    for node in registry["nodes"]:
        ready = any(node.get("routes", []))
        if node.get("managed_status") not in (None, "ready"):
            ready = False
        nodes.append({"name": node["name"], "status": "ready" if ready else "failed"})
    return {
        "nodes": nodes,
        "ready": sum(item["status"] == "ready" for item in nodes),
        "maintenance": 0,
        "failed": sum(item["status"] == "failed" for item in nodes),
    }
