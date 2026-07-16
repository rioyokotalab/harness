# Frozen offline project-lock gate

T-227 extends the dependency-free environment evidence from T-214. The tracked
[`pyproject.toml`](../tests/fixtures/offline-project/pyproject.toml) and
[`uv.lock`](../tests/fixtures/offline-project/uv.lock) form one intentionally
minimal project whose lock can be consumed on both supported architectures.
The gate copies those files into private scratch and runs the visible managed
`uv` and Python 3.12 with:

```text
uv sync --frozen --offline --no-python-downloads --no-install-project \
  --no-editable --no-config
```

The project environment and uv cache are both placed inside the same temporary
tree. The gate ignores user uv configuration, disables Python downloads,
requires the committed lock without updating it, runs Python in isolated mode,
and routes recursive scratch cleanup through the guarded deletion workflow.

This is a transport/control-plane check, not a useful application environment.
The lock deliberately has no third-party dependencies. A pass proves only that
the node can materialize and execute the same frozen dependency-free project
definition without network resolution. It does not prove cached wheel
availability, build backends, framework installation, immutable containers,
CUDA compatibility, model execution, or training correctness. Those remain
behind the framework/artifact choice in T-206.
