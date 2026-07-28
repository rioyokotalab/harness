import json

import audit_policy


with open("policy.json", encoding="utf-8") as handle:
    policy = json.load(handle)
assert audit_policy.findings(policy) == []
assert audit_policy.findings(
    {"required_reviews": 0, "zero_review_owner_override": False, "required_checks": True}
) == ["reviews-below-floor"]
assert audit_policy.findings(
    {"required_reviews": 2, "zero_review_owner_override": False, "required_checks": False}
) == ["checks-disabled"]
print("preserve-dirty-policy public check: pass")
