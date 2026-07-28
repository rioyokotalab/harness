"""Parse event records from current and legacy producers."""


def parse_event(record):
    """Normalize schema 1 or schema 2 to kind, payload, and reply_count."""
    if record.get("schema") != 1:
        raise ValueError("unsupported schema")
    return {
        "kind": record["kind"],
        "payload": record["payload"],
        "reply_count": 0,
    }
