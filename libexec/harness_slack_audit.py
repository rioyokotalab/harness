#!/usr/bin/env python3
"""Bounded content-free audit writer for one Slack profile service."""

from __future__ import annotations

from datetime import datetime, timezone
import fcntl
import json
import os
from pathlib import Path
import stat
import time
from typing import Any

import harness_slack_broker as broker


class AuditError(ValueError):
    """Stable value-free audit failure."""


def fail(reason: str) -> None:
    raise AuditError(reason)


class AuditLog:
    def __init__(self, profile: dict[str, Any], path: str) -> None:
        self.profile = broker.validate_profile(profile)
        self.path = Path(path)
        if not self.path.is_absolute():
            fail("audit-path-invalid")
        try:
            parent = self.path.parent.lstat()
        except OSError:
            fail("audit-path-invalid")
        if (
            not stat.S_ISDIR(parent.st_mode)
            or parent.st_uid != os.geteuid()
            or stat.S_IMODE(parent.st_mode) != 0o700
        ):
            fail("audit-path-invalid")

    def write(
        self,
        capability: str,
        outcome: str,
        reason: str,
        started: float,
        item_count: int = 0,
    ) -> None:
        latency = max(0, min(300000, int((time.monotonic() - started) * 1000)))
        event = {
            "attempt": 1,
            "capability": capability,
            "item_count": item_count,
            "latency_ms": latency,
            "outcome": outcome,
            "reason": reason,
            "schema": 1,
            "time": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        }
        broker.validate_audit(self.profile, event)
        payload = (broker.canonical_json(event) + "\n").encode("ascii")
        if len(payload) > 4096:
            fail("audit-event-invalid")
        flags = os.O_RDWR | os.O_CREAT | os.O_APPEND | os.O_CLOEXEC
        if hasattr(os, "O_NOFOLLOW"):
            flags |= os.O_NOFOLLOW
        try:
            descriptor = os.open(self.path, flags, 0o600)
        except OSError:
            fail("audit-unavailable")
        try:
            fcntl.flock(descriptor, fcntl.LOCK_EX)
            info = os.fstat(descriptor)
            if (
                not stat.S_ISREG(info.st_mode)
                or info.st_uid != os.geteuid()
                or stat.S_IMODE(info.st_mode) != 0o600
                or info.st_nlink != 1
            ):
                fail("audit-metadata-invalid")
            max_bytes = self.profile["audit"]["max_bytes"]
            max_age = self.profile["audit"]["retention_days"] * 24 * 60 * 60
            expired = False
            if info.st_size:
                first = os.pread(descriptor, 4096, 0).split(b"\n", 1)[0]
                try:
                    first_event = json.loads(first)
                    oldest = datetime.strptime(
                        first_event["time"], "%Y-%m-%dT%H:%M:%SZ"
                    ).replace(tzinfo=timezone.utc)
                except (KeyError, TypeError, ValueError, json.JSONDecodeError):
                    fail("audit-history-invalid")
                expired = (
                    datetime.now(timezone.utc) - oldest
                ).total_seconds() > max_age
            if info.st_size + len(payload) > max_bytes or expired:
                os.ftruncate(descriptor, 0)
            if os.write(descriptor, payload) != len(payload):
                fail("audit-write-failed")
            os.fsync(descriptor)
        except OSError:
            fail("audit-write-failed")
        finally:
            os.close(descriptor)
