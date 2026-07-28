import ast
from pathlib import Path

import facts_parser


source = Path("facts_parser.py").read_text(encoding="utf-8")
ast.parse(source, filename="facts_parser.py", feature_version=(3, 6))
assert facts_parser.parse_facts(["state=ready\n", "count=3\n"]) == {
    "state": "ready",
    "count": "3",
}
for lines in (["State=ready\n"], ["state\n"], ["state=\n"], ["state=a\n", "state=b\n"]):
    try:
        facts_parser.parse_facts(lines)
    except ValueError:
        pass
    else:
        raise AssertionError("malformed facts accepted: {!r}".format(lines))
print("portable-runtime public check: pass")
