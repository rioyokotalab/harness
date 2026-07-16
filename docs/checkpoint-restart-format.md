# Portable checkpoint/restart format v1

T-217's test state uses a fixed 40-byte record. The format is intentionally
small enough to audit and port; it is a readiness fixture, not an application
checkpoint recommendation.

| Offset | Size | Encoding | Field |
|---:|---:|---|---|
| 0 | 8 | bytes | ASCII `HCKPT001` |
| 8 | 4 | unsigned big-endian | version, exactly 1 |
| 12 | 4 | unsigned big-endian | flags, exactly 0 |
| 16 | 8 | unsigned big-endian | completed step count |
| 24 | 8 | unsigned big-endian | deterministic 64-bit state |
| 32 | 8 | unsigned big-endian | FNV-1a-64 of bytes 0–31 |

All arithmetic state transitions use defined unsigned 64-bit wraparound. The
initial state is `0x243f6a8885a308d3`. A checkpoint at step `s` records the
state after applying steps 1 through `s`; resume begins with `s + 1`. Readers
must require exact size and regular-file type before decoding, then validate
magic, version, flags, checksum, and the caller's expected step before using
the state.

FNV-1a uses offset basis `1469598103934665603` and prime
`1099511628211`. This checksum detects the gate's tested accidental corruption;
it is not cryptographic authentication and must not be used to trust an
untrusted checkpoint.

## Golden vector

For step 400, the complete record in hexadecimal is:

```text
48434b505430303100000001000000000000000000000190f228968bea039c89a12045f4cbcc95d1
```

Its SHA-256 is
`0cc4aab240009663fdc78161d523446dc3a71330e7b445b77aa7aa3cdb4dbfe1`.
The frozen uninterrupted state after 1,000,000 steps is
`0x7f7cadf8669fc055`.

The writer uses collision-refusing creation, mode 0600, complete writes, and
file `fsync`. Atomic publication and exact cleanup are validated separately by
T-211/T-217. This fixture does not claim directory-fsync crash durability,
concurrent writers, scheduler requeue, signal recovery, distributed state,
schema evolution beyond rejecting unknown versions, performance, or suitability
for floating-point/scientific application data.
