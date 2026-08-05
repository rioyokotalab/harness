# Consumer receipts

A consumer may add one `Har-NNN.md` receipt for a producer-created task.
The metadata keys are exactly `task`, `status`, `updated`, and `validation`,
followed by `---`. Status is `complete` or `blocked`; a receipt records evidence
but never grants authority or creates another goal.
