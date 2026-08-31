---
id: "0025"
title: AWS Neuron base image (RHEL) and vllm-neuron pin diverge from generated docs as of 3.6 EA1
status: active
created: 2026-08-26
affects:
  - platform
release:
  - "3.6"
provenance:
  - https://redhat.atlassian.net/browse/RHAISTRAT-2597
author: Reshmi Aravind
superseded_by: null
---

## Fact

For 3.6 EA1, the AWS Neuron `rhaibi-neuron` base image is confirmed (against actual EA1 build/release
artifacts) to already be on the **RHEL 9.8** base, and the RHAIIS pipeline's `neuron-ubi9` collection
already ships **vllm-neuron 0.5.3**. Both facts diverge from the currently generated architecture docs
and overlay 0017 / overlay 0021, which document `rhaibi-neuron` on RHEL 9.6 (overlay 0017: "Neuron
Runtime Library 2.32.31, Neuron Tools 2.30.10, Neuron Collectives 2.32.28") and `neuron-ubi9` pinned to
`vllm-neuron==0.5.1` (overlay 0021).

The Neuron SDK version itself is not fully reconciled by this overlay: the confirmed-shipped target is
referenced as "2.31.0" against build/release artifacts, which does not obviously map onto the
`2.32.31` / `2.30.10` / `2.32.28` per-component RPM versions documented in overlay 0017. Treat the SDK
version number as an open question pending clarification from the AIPCC/Neuron owning team, but treat
the RHEL 9.8 base and vllm-neuron 0.5.3 facts above as confirmed.

This overlay covers the `rhaibi-neuron` **base image** only. It does not confirm the OS version of the
separate **wheels builder** image (`builder-neuron-ubi9-*`, documented in the wheels-builder overlay) --
that image may still be on RHEL 9.6 independent of this fact, since base images and builder images are
rebased on independent schedules.

## Impact on Strategies

- Strategies proposing a "RHEL 9.6 → 9.8 rebase" or a "vllm-neuron 0.5.1 → 0.5.3" version bump for the
  AWS Neuron variant in 3.6 EA2 (or later) are describing work that was already completed in 3.6 EA1.
  Re-verify against this overlay before scoping rebase/version-bump work for Neuron.
- Do not conflate the `rhaibi-neuron` base image's RHEL version (9.8, per this overlay) with the Neuron
  wheels builder image's RHEL version (still 9.6 per the wheels-builder overlay, unconfirmed whether a
  Neuron-specific exception exists) -- these are two independently-versioned images.
- The exact Neuron SDK version number is unresolved between the RFE/strategy-stated "2.31.0" and
  overlay 0017's per-component RPM versions ("2.32.31" / "2.30.10" / "2.32.28"). Strategies citing a
  specific Neuron SDK version should confirm with the owning team rather than assuming either source is
  authoritative.

## Context

Overlays 0017 and 0021 were both last regenerated 2026-07-30 by their respective update skills scanning
the `base-images/app` and `rhaiis/pipeline` source repositories. Despite being a recent scan (not a
stale snapshot), they do not reflect the AWS Neuron variant's actual 3.6 EA1 shipped state for RHEL
base version and vllm-neuron pin. This is most likely because the EA1 release values were carried on a
release branch that the generator scripts' scanned branch (`main`) does not reflect, though the owning
team has not yet confirmed the exact mechanism. This overlay exists to prevent strategies and reviews
from re-deriving "Neuron needs a RHEL 9.8 rebase / vllm-neuron bump" from the generated docs until the
source repos and generator scan are reconciled and overlays 0017/0021 are regenerated correctly, at
which point this overlay should be marked `superseded`.
