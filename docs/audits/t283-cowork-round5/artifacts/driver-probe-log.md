# Driver receipt probe log

Baseline: `f87b019836ad5c5ed4cb9c85ac409d47484e06f2`; sandbox:
`/tmp/harness-t283-round5-codex`.

`python3 receipt-probe.py` produced:

```text
candidate drift leaves live unchanged: True
candidate drift leaves receipt hash valid: True
receipt exposes private path: False
replay refused before mutation: receipt already exists
failure injected: injected receipt write failure
failure restores destination: True
failure leaves receipt absent: True
```

The prototype receipt included roles, mode, projected input hashes, the full
live-state hash, stage-manifest hash, candidate hash, and destination
before/after hashes. It intentionally stored hashes rather than filesystem
paths. It replaced evidence, injected a receipt failure, restored exact prior
evidence, and left no receipt.

Against a real current helper session, `cowork-session digests` output was
byte-identical before and after adding
`artifacts/import-receipt.json`; the command printed only the seven fixed
protected top-level files. Thus a receipt below current shared artifacts is not
driver-protected unless `digests` explicitly covers a closed receipt subtree.
Adding a new top-level `receipts/` directory to the current helper immediately
would require a layout/schema compatibility rule because old predecessor
sessions have a closed top-level set without it.
