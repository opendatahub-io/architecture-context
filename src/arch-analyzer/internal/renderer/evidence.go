package renderer

import (
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const synthesisEvidenceLimit = 40

// SynthesisEvidenceMarkdown renders the bounded analyzer projection used for
// agent navigation. It deliberately excludes the full inventory and retains
// only coverage, relationships, claims, and provenance needed to decide which
// gaps justify a source read.
func SynthesisEvidenceMarkdown(writer io.Writer, input model.Input) error {
	if _, err := fmt.Fprintf(writer, "# Analyzer Synthesis Context: %s\n\n", input.Component); err != nil {
		return err
	}
	if _, err := io.WriteString(writer, "This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.\n\n## Coverage Findings\n\n"); err != nil {
		return err
	}
	for _, finding := range input.CoverageFindings {
		if _, err := fmt.Fprintf(writer, "- **%s (%s)**: %s", finding.Category, finding.Status, finding.Finding); err != nil {
			return err
		}
		if len(finding.Sources) > 0 {
			if _, err := fmt.Fprintf(writer, " [source: %s]", strings.Join(finding.Sources, ", ")); err != nil {
				return err
			}
		}
		if _, err := io.WriteString(writer, "\n"); err != nil {
			return err
		}
	}

	if _, err := io.WriteString(writer, "\n## Deterministic Cross-References\n\n"); err != nil {
		return err
	}
	for _, ref := range input.CrossReferences {
		if _, err := fmt.Fprintf(writer, "- **%s**: %s —%s→ %s", ref.Kind, ref.From, ref.Relationship, ref.To); err != nil {
			return err
		}
		if ref.Details != "" {
			if _, err := fmt.Fprintf(writer, "; %s", ref.Details); err != nil {
				return err
			}
		}
		if len(ref.Sources) > 0 {
			if _, err := fmt.Fprintf(writer, " [source: %s]", strings.Join(ref.Sources, ", ")); err != nil {
				return err
			}
		}
		if _, err := io.WriteString(writer, "\n"); err != nil {
			return err
		}
	}

	if _, err := io.WriteString(writer, "\n## Section Evidence\n\n"); err != nil {
		return err
	}
	keys := make([]string, 0, len(input.SynthesisEvidence))
	for key := range input.SynthesisEvidence {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		if _, err := fmt.Fprintf(writer, "### %s\n\n", key); err != nil {
			return err
		}
		records := input.SynthesisEvidence[key]
		if len(records) > synthesisEvidenceLimit {
			records = records[:synthesisEvidenceLimit]
		}
		for _, record := range records {
			claim := strings.TrimSpace(record.Claim)
			if len(claim) > 500 {
				claim = claim[:497] + "..."
			}
			if _, err := fmt.Fprintf(writer, "- %s [source: %s]\n", claim, strings.Join(record.Sources, ", ")); err != nil {
				return err
			}
		}
	}
	return nil
}
