#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
export PYTHONDONTWRITEBYTECODE=1
python3 -B -m unittest discover -s "$ROOT/tests" -p 'test_slack_broker.py'
"$ROOT/bin/harness" slack-broker --help >/dev/null
echo 'slack_broker_tests=pass'
