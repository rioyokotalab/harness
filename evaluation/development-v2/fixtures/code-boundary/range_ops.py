"""Integer range helpers."""


def inclusive_range(start, stop, step=1):
    """Return an integer list spanning start toward stop."""
    if step == 0:
        raise ValueError("step must not be zero")
    return list(range(start, stop, step))
