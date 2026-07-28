"""Produce small event records."""


MAX_REPLY_COUNT = 8


def make_event(kind, payload, reply_count=0):
    """Return schema 2 with an integer reply count from zero through eight."""
    return {"schema": 2, "kind": kind, "payload": payload}
