import events
import parser


assert events.MAX_REPLY_COUNT == 8
current = events.make_event("ready", {"code": 7}, reply_count=2)
assert current == {
    "schema": 2,
    "kind": "ready",
    "payload": {"code": 7},
    "reply_count": 2,
}
assert parser.parse_event(current) == {
    "kind": "ready",
    "payload": {"code": 7},
    "reply_count": 2,
}
legacy = {"schema": 1, "kind": "waiting", "payload": None}
assert parser.parse_event(legacy)["reply_count"] == 0
print("code-coherence public check: pass")
