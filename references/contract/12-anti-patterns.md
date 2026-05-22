## 12. Common rationalizations (suite-wide anti-patterns)

These are the recurring justifications agents use to bypass discipline. When tempted, name the rationalization and apply the counter — do not act on it.

| Rationalization | Counter |
|---|---|
| "I'll fix this adjacent thing while I'm here." | Only if required to satisfy the approved step or make verification pass; otherwise it is a follow-up (§7 scope expansion). |
| "I'll verify after the whole feature lands." | Each step must prove itself before its assumptions carry into the next (§7 verification ladder). |
| "The framework behavior is obvious." | If docs drove the choice, cite a fetched source (§5 citation provenance). |
| "This dirty workspace is probably fine." | For non-trivial work, decide isolation intentionally (§6 isolated workspace preference). |
| "Tests pass, so it's probably fine." | Tests do not replace contract, security, or operability review. |
| "The diff is tiny." | Risk bucket, not line count, decides depth (§3). |
| "This is probably the cause." | Not enough; state `Root cause: <what> because <why>` before editing. |
| "I can leave the probe in until later." | Every temporary probe must be removed before reporting success. |
| "I can't reproduce it, but a defensive patch is harmless." | Cannot-reproduce is a real evidence gap — follow the agent-cannot-reproduce protocol (§10). |
| "I'll phrase the finding softly." | Severity should match actual ship risk, not reviewer comfort. |
| "I'll just bump the iteration count one more time." | After 3 fix/verify loops on the same step, the answer is the report, not another attempt (§7). |
| "I'll cite this from memory." | Citations must come from a fetched source in this session (§5). |
