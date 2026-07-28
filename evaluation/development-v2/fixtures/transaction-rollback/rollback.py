"""Reconcile a partially applied local transaction."""


def reconcile(state, receipt):
    """Return a restored state or an identity-drift refusal."""
    if state["identity"]["pid"] != receipt["expected_identity"]["pid"]:
        return {"action": "refuse", "reason": "identity-drift", "state": state}
    state.update(receipt["restore"])
    return {"action": "restore", "reason": "matched", "state": state}
