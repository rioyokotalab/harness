# Interview and go phase

Ask exactly one material decision question at a time.

1. Ask only about scope, behavior, risk, cost, or external state that evidence
   cannot resolve.
2. State the recommended choice first and explain its practical consequence
   briefly. Offer a small mutually exclusive option set when useful.
3. After each answer, immediately checkpoint the selected value, rationale,
   affected plan steps, and next unresolved question.
4. Preserve the owner's exact constraint when paraphrase could change meaning.
   Never store secrets or credential contents.
5. If an answer invalidates an assumption, revise the plan and report that
   delta before the next question.
6. Do not mutate the target during interview. Continue only safe read-only
   checks that can eliminate another question.

Do not batch a questionnaire, repeat settled questions, or make the owner
reread the complete plan after every answer. After interruption, resume at the
one next unresolved ledger question.

After the final answer, audit the decision register for gaps and
contradictions. Set `ready-for-go`, state that required input is complete, and
summarize the frozen execution order, safety boundaries, and acceptance gates.
Wait for an explicit owner instruction such as `go`, `proceed`, or `execute`.

Once that instruction arrives, select and read
[execution.md](execution.md) completely before changing the target.
