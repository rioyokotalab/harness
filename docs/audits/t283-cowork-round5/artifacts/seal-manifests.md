# Round-5 protected seal summary

The independent pre-client and post-client manifests matched for charter,
execution, plan, reconciliation, state, and validation. Driver evidence changed
from `12e0ec51cd319a4d78480db81154891573cae8427e13ad74b0f994cd36df214a`
(template) to
`4617fa45ffc0271db7f1cf082b01623d888a6000a93edaa7e8184a6fe257cced`
because the driver authored it during the window. The fresh pre/post independent
import manifest was identical.

After the driver evidence/deviation record was frozen, its hash was
`b2b3045877131fe9328e80a512514a4c2cfaa093dbe9728440645cd568e3cadb`.
Every line of the reciprocal pre-client and post-client manifests matched, and
the import-only comparison also matched. The raw mode-0600 manifests stay
outside the session until guarded cleanup; this bounded tracked summary makes
the exact supported claims durable without exposing private values.
