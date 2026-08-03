# Task: Resolve External Analyzer-Assisted Rollout Gates

## Goal

Resolve the remaining promotion gates for full analyzer-assisted rollout.
These gates do not block local implementation or the documented provisional
track.

## Required inputs

- Approved external MLflow registration, if promotion requires it.
- External fetcher OTel producer evidence, if promotion requires it.
- Human adjudication for the 35 root-cause proposals.
- Human semantic labels for the 24 calibration questions and judge
  authorization.

## Current state — 2026-07-26

Local file-backed MLflow, local OTel/API capture, existing feedback-based
directional evaluation, and analyzer-assisted implementation may continue.
The 320-session provisional evaluation and clean-run isolation are complete.
Full rollout claims and legacy-route retirement remain prohibited until the
promotion inputs above are available. See the historical audit in commit
`26c42129`.

## Status

Blocked on promotion-only external/human inputs; not a blocker for local
analyzer-assisted synthesis work.
