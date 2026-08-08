#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT" <<'PY'
import ast
from pathlib import Path
import sys

root = Path(sys.argv[1])
paths = sorted((root / "presentation/scripts").glob("*.py"))
assert len(paths) == 5
for path in paths:
    tree = ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    assert any(isinstance(node, ast.FunctionDef) and node.name == "main" for node in tree.body)
    assert any(isinstance(node, ast.If) for node in tree.body)
print(f"PRESENTATION_TOOLS status=pass scripts={len(paths)}")
PY
