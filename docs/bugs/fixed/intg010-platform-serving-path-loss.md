# INTG-010: Platform Synthesis Drops a Serving Path

## Evidence

The fresh `consumer-v1` run at
`tmp/evaluations/consumer-v1-rhoai-next-20260803T005702Z/` shows Tree B's
`PLATFORM.md` replacing the documented external-provider MaaS path with the
llm-d implementation path. The component document
`models-as-a-service.md` is present, but the platform-level serving analysis
does not preserve it as a distinct path.

## Impact

Platform consumers can mistake a specialized serving implementation for the
complete serving architecture and miss the separately deployed external-
provider routing path.

## Fix

Require an evidence-derived serving-path matrix during platform synthesis and
carry every distinct path into a dedicated serving-path subsection. The
contract must prevent omission or substitution without hardcoding a fixed list
of component names.

## Current Status

The focused platform replay now produces and validates six evidence-backed
rows, including MaaS and external-provider AI Gateway routing. The remaining
failure came from benchmark contract drift: the old question asked for three
paths, which encouraged a three-path generational summary even though the
current document exposes six rows. The consumer, strategy, and analyzer
manifest contracts have been synchronized to the current six-path section.
The focused rerun at
`tmp/evaluations/consumer-v1-rhoai-next-20260803T154251Z/` passed for Tree B
with score `1.0`. The bug is fixed; the full consumer benchmark remains a
broader regression check.
