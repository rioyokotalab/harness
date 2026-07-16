def clamp(value, lower=0.0, upper=1.0):
    if lower > upper:
        raise ValueError("lower must not exceed upper")
    return max(lower, min(upper, value))
