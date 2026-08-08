#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)

python3 - "$ROOT/libexec/harness_housekeeping.py" <<'PY'
from pathlib import Path
import runpy
import sys

module = runpy.run_path(sys.argv[1])
normalize = module["normalized_remote_identity"]
error = module["HousekeepingError"]

assert normalize("git@GitHub.COM:rio/repo.git") == "github.com/rio/repo"
assert normalize("ssh://git@github.com/rio/repo.git") == "github.com/rio/repo"
assert normalize("https://github.com/rio/repo") == "github.com/rio/repo"
for unsafe in (
    "",
    "https://user@github.com/rio/repo",
    "https://user:secret@github.com/rio/repo",
    "file:///tmp/repo",
    "git@github.com:../repo",
    "git@github.com:-repo",
    "git@github.com:rio//repo",
    "git@github.com:rio/repo?token=value",
):
    try:
        normalize(unsafe)
    except error:
        pass
    else:
        raise AssertionError(unsafe)

tips = [
    {"archive": "z", "tip": "a" * 40},
    {"archive": "a", "tip": "b" * 40},
]
assert module["alias_tip_digest"](tips) == module["alias_tip_digest"](list(reversed(tips)))
source = Path("/durable/receipts/source")
assert module["owner_alias_name"](source).endswith(".json")
assert module["owner_alias_source_key"](source) == str(source)

module["validate_item"]("archive-branch", "a" * 40)
for name, tip in (("-unsafe", "a" * 40), ("unsafe\nname", "a" * 40), ("ok", "bad")):
    try:
        module["validate_item"](name, tip)
    except error:
        pass
    else:
        raise AssertionError((name, tip))

print("HOUSEKEEPING_OWNER_ALIAS status=pass")
PY
