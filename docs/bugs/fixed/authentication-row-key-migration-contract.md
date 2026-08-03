# Bug: Authentication Row-Key Migration Contract

## Problem

The MLflow entrypoint-evidence replay exposed a contract gap when an agent
needed to split an analyzer authentication row into distinct serving surfaces.
The analyzer emitted `HTTP API :: All`, while source evidence established that
the tracking server should be `Tracking Server API :: All` and the gateway
should be a separate row.

The agent attempted to update the endpoint key in place and emitted an invalid
candidate-only add. The evidence-gated merge rejected the new tracking-server
row, rejected the key-changing updates, and restored the original analyzer row.

## Fix

Added explicit skill guidance and merge regression coverage requiring a row-key
migration to be represented as an evidence-backed delete of the old row plus
an add of the new row. Add/delete records use `*` and `<empty>` values, while
the candidate Markdown contains the replacement row.

## Validation

The corrected MLflow replay on 2026-08-02 applied 4 changes with 0 rejected and
0 restored changes. It completed with a 1.0 source-read justification ratio.
