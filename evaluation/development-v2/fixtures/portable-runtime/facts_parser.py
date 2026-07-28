"""Parse newline-oriented public facts."""


def parse_facts(lines):
    """Return a mapping from strict ``key=value`` input lines."""
    facts: dict[str, str] = {}
    for raw in lines:
        match raw.rstrip("\n").split("=", maxsplit=1):
            case [key, value] if key.islower() and key.isidentifier() and value:
                if key in facts:
                    raise ValueError("duplicate fact")
                facts[key] = value
            case _:
                raise ValueError("malformed fact")
    return facts
