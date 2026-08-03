# Bug: NAV-005 Symlink Evaluation Context

## Problem

`NAV-005` asks for symlinks in the `architecture/` directory, but the consumer
benchmark materializer copies only regular files and the evaluation agents are
restricted to `Read`, `Glob`, and `Grep`. Symlink metadata is therefore absent
from the evaluated tree and cannot be inspected by the agent.

## Evidence

- Benchmark: `tmp/evaluations/consumer-v1-rhoai-next-20260802T234823Z/`
- Expected symlinks: `current-ga`, `latest-released`, `early-access`,
  `future-ga`, and `newest`
- `benchmark/consumer-v1/run_evaluation.py` materializes files with `find
  ... -type f`, excluding symlinks.
- Tree B correctly reported that symlink metadata was unavailable, but failed
  source citation because no symlink manifest exists in the evaluation tree.

## Expected Behavior

Either provide a generated, readable symlink manifest in the evaluation tree
and score against that document, or retire/rewrite `NAV-005` so it asks a fact
available through the permitted architecture-document tools.

## Scope

Fix the benchmark context contract and add a focused test proving the question
is answerable under the actual materialization and tool restrictions.
