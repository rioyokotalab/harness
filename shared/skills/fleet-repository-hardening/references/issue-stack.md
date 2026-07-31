# Repository-local LIFO issue handling

On the slightest new ambiguity or failed gate:

1. Pause only the interrupted change and preserve safe evidence.
2. Classify retry safety and whether a coherent validated partial commit
   exists.
3. If no such commit exists, stash only explicitly named task-owned paths.
   Never use a broad stash or include pre-existing work.
4. Push the issue to the top of that repository's ledger with the exact
   failure, stash or commit identifier, unchanged external state, and next
   command.
5. Treat it as that repository's next task. Resolve it immediately when safe,
   validate the resolution, remove only superseded task-owned stash state, and
   pop back to the interrupted task.
6. If it requires owner input, administrator authority, or another unavailable
   external condition, defer it in place and continue the next highest safe
   item in that repository. Never skip work whose correctness depends on the
   blocked gate.
7. Keep every other repository progressing independently.

A failed gate becomes the newest work item, not a reason to idle an entire
repository. Preserve its exact helper or decision boundary in the ledger so a
later retry does not reconstruct or blindly replay ambiguous work.
