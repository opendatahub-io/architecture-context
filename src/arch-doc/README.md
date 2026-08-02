# arch-doc

`arch-doc` is the repository-local section assembly and validation command for
architecture Markdown. It keeps analyzer-owned sections authoritative while
allowing the generation pipeline to promote bounded agent synthesis.

## Commands

```bash
bin/arch-doc sections architecture/rhoai.next/kserve.md
bin/arch-doc sections architecture/rhoai.next/kserve.md --output json
bin/arch-doc validate architecture/rhoai.next/kserve.md
bin/arch-doc update architecture/rhoai.next/kserve.md \
  --section "Architectural Analysis" --input analysis.md
bin/arch-doc assemble \
  --base .generation/table-merged.md \
  --candidate .generation/candidate.md \
  --output .generation/merged.md
```

The section ownership contract is embedded from
[`section-manifest.json`](section-manifest.json). `update` accepts only
synthesis-owned sections. `assemble` replaces the required synthesis sections,
preserves analyzer-owned sections from the base, carries forward only missing
conditional synthesis sections, and rejects duplicate or missing synthesis
sections before writing atomically.

The Python architecture phase performs evidence-gated table adjudication first,
then invokes `arch-doc assemble` on the table-merged analyzer base. The raw
agent candidate is never promoted directly on constrained routes.
