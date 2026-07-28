"""Classify a repository's review policy."""


def findings(policy):
    """Return stable finding codes for unsafe policy."""
    issues = []
    reviews = policy.get("required_reviews")
    if not isinstance(reviews, int) or reviews < 1:
        issues.append("reviews-below-floor")
    if not policy.get("required_checks"):
        issues.append("checks-disabled")
    return issues
