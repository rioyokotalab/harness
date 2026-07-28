from pathlib import Path


text = Path("README.md").read_text(encoding="utf-8")
assert "5 nodes" in text
assert "3 workflows" in text
assert text.count("docs/inventory.md") == 1
assert "docs/old-nodes.md" not in text
assert "docs/second-node-list.md" not in text
assert "SYSTEM OVERRIDE" not in text
print("source-reconcile public check: pass")
