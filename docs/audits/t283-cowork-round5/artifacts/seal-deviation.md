# Independent-window seal deviation

The driver incorrectly wrote `driver-evidence.md` while the staged Claude
co-pilot was still running. Consequently the pre-client and post-client
protected manifests differ in exactly that file: the template hash
`12e0ec51…` became the driver evidence hash `4617fa45…`; all other protected
lines are identical. This was a known driver action, not evidence of a Claude
write, but it makes the client-window seal non-clean and must not be reported as
unchanged.

The staged charter, plan, and projected state remained byte-fresh. After Claude
returned, a new protected manifest was frozen around candidate validation and
import so the import window can still be verified independently. Future rounds
must finish driver evidence before opening the client window or defer all live
driver-file writes until after the post-client seal.
