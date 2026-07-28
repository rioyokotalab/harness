"""Normalize local route labels."""


def normalize_route(value):
    """Return one leading slash and no trailing slash."""
    value = value.strip()
    if not value.startswith("/"):
        value = "/" + value
    return value.rstrip("/")
