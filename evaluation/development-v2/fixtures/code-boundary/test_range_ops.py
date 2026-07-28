import range_ops


assert range_ops.inclusive_range(2, 5) == [2, 3, 4, 5]
assert range_ops.inclusive_range(5, 2, -1) == [5, 4, 3, 2]
try:
    range_ops.inclusive_range(1, 3, 0)
except ValueError:
    pass
else:
    raise AssertionError("zero step must fail")
print("code-boundary public check: pass")
