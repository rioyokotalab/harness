#!/bin/sh
set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
SCAFFOLD=$ROOT/shared/skills/onboard-project-repository/assets/scaffold
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=$SCAFFOLD/tools \
    exec python3 -m unittest discover -s "$SCAFFOLD/tests" \
        -p test_consumer_protocol.py
