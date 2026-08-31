---
id: "0026"
title: Google TPU vLLM pin is already 0.26.0+rhaiv.2.tpu, ahead of generated docs
status: active
created: 2026-08-27
affects:
  - platform
release:
  - "3.6"
provenance:
  - https://redhat.atlassian.net/browse/RHAISTRAT-2595
author: Reshmi Aravind
superseded_by: null
---

## Fact

For the Google TPU (`tpu-ubi9`) build variant, the RHAIIS pipeline's actual vLLM pin is confirmed
(against source) to already be **`vllm[tensorizer]==0.26.0+rhaiv.2.tpu`**. This diverges from overlay
0021, which documents `vllm[tensorizer]==0.21.0+rhaiv.13.tpu` and was last regenerated 2026-07-30 — a
recent scan, not a stale snapshot.

This is a notable jump — five minor versions ahead of what overlay 0021 currently documents for TPU.
Treat the confirmed `0.26.0+rhaiv.2.tpu` figure as verified, not a transposition or a target-vs-shipped
mix-up — it was independently confirmed before this overlay was written.

The torch pin for `tpu-ubi9` is **not** affected by this overlay: overlay 0021's `torch-2.10.0 *`
constraints-rules delegation for TPU (`torch==2.10.0`, "one torch minor behind the rest") remains
accurate. Torch stays at 2.10.0 because torchvision 0.25.0 does not support torch 2.11.0 — this is a
real, current constraint, not a stale one.

## Impact on Strategies

- Strategies proposing a vLLM version "catch-up" for the TPU variant (e.g., treating 0.21.0 as the
  starting point and a multi-minor-version bump as required work) are working from a stale baseline.
  Re-verify against this overlay before scoping vLLM work for TPU — the current pin (0.26.0+rhaiv.2.tpu)
  may already satisfy an EA2/GA target without any vLLM version-bump engineering.
- Do not treat NeuralMagic-fork-TPU-support-beyond-0.21.0 as an open feasibility gate — the fork already
  supports TPU well beyond that version, since 0.26.0+rhaiv.2.tpu is the confirmed current state.
- Do not conflate this vLLM correction with the torch pin: `torch-2.10.0 *` for `tpu-ubi9` remains
  correct and is not superseded by this overlay.

## Context

Overlay 0021 was last regenerated 2026-07-30 by its update skill scanning the `rhaiis/pipeline` source
repository, and does not reflect this more-current vLLM pin. As with the AWS Neuron variant (see overlay
0025, a similar divergence discovered the same week), this is most likely because a version bump landed
on a branch or through a mechanism the generator's scanned branch (`main`) does not reflect at scan time,
though the owning team has not yet confirmed the exact mechanism for TPU specifically. This overlay exists
to prevent strategies and reviews from re-deriving a "TPU vLLM catch-up" requirement from the generated
docs until the source repo and generator scan are reconciled and overlay 0021 is regenerated correctly,
at which point this overlay should be marked `superseded`.
