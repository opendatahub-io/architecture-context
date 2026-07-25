# Enable the Query-Aware Evaluation Boundary

Added an opt-in `arch-query` path to the consumer-v1 evaluator. Query access
is enabled only when the selected condition permits `arch-query`; the guard
accepts only the bare approved command, contract query subcommands, explicit
JSON output, and an explicit `--base-dir` inside the evaluated tree. Shell
operators, arbitrary commands, path escapes, writes, and baseline Bash remain
denied. Query calls and denials are recorded in telemetry, and query capability
metadata is included in condition provenance.

Validation: 205 focused host tests passed, including 60 query-boundary tests;
Ruff and `git diff --check` passed. Direct parser checks confirmed the security
constraints. No experiment conditions were marked available and no evaluation
was run. The task container lacked `uv`; this was classified as infrastructure
and the host `uv` environment was repaired for verification.
