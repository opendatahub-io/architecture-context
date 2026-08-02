# Bug: Composite Corpus Primary Metric Mixed Domains

## Summary

The consumer scorer selected primary questions using
`required_scope: architecture` even when a composite corpus supplied an
explicit `domain`. Five SME-context questions carried an architecture required
scope for their source boundary and were incorrectly included in the primary
architecture metric.

## Evidence

Run:
`tmp/evaluations/consumer-v1-rhoai-next-vs-bak-20260731T133148Z/`

- Corpus size: 60 questions.
- Intended domains: 40 architecture, 10 pipeline, 10 SME context.
- Old primary count: 42.
- Corrected primary count: 40.

## Fix

The scorer now uses explicit `domain` metadata for primary selection and emits
per-domain aggregates. Legacy corpora without domain metadata continue to use
`required_scope` as a compatibility fallback. Reports classify regressions by
domain when available.

## Status

Resolved 2026-07-31. The completed run was rescored and its report regenerated;
the corrected architecture comparison is Tree A `0.6000` versus Tree B
`0.5500`.
