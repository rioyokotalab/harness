# Compatibility unsafe-tail protocol index

Do not preload this legacy index during normal recovery. The router in
`SKILL.md` is authoritative: diagnosis loads no transaction reference;
one-shot rollback loads `safe-rollback.md` plus `acceptance.md`; bridge-first
replacement loads `bridge-first.md` plus `acceptance.md`. Those direct
references contain the complete requirements. This compatibility index
contains no transaction instructions and does not select a route.
