package renderer

import (
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const synthesisEvidenceLimit = 40
const gapEvidenceLimit = 12

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

	if _, err := io.WriteString(writer, "\n## Gap Evidence Index\n\n"); err != nil {
		return err
	}
	if len(input.GapEvidenceIndex) == 0 {
		if _, err := io.WriteString(writer, "No deterministic gap candidates were extracted.\n"); err != nil {
			return err
		}
	}
	gapKeys := make([]string, 0, len(input.GapEvidenceIndex))
	for key := range input.GapEvidenceIndex {
		gapKeys = append(gapKeys, key)
	}
	sort.Strings(gapKeys)
	for _, key := range gapKeys {
		if _, err := fmt.Fprintf(writer, "### %s\n\n", key); err != nil {
			return err
		}
		candidates := input.GapEvidenceIndex[key]
		if len(candidates) > gapEvidenceLimit {
			candidates = candidates[:gapEvidenceLimit]
		}
		for _, candidate := range candidates {
			if _, err := fmt.Fprintf(writer, "- **Question:** %s\n  **Expected signal:** %s\n  **Candidate:** `%s`", candidate.Question, candidate.ExpectedSignal, candidate.Source); err != nil {
				return err
			}
			if candidate.LineRange != "" {
				if _, err := fmt.Fprintf(writer, ":%s", candidate.LineRange); err != nil {
					return err
				}
			}
			if len(candidate.Symbols) > 0 {
				if _, err := fmt.Fprintf(writer, " (%s)", strings.Join(candidate.Symbols, ", ")); err != nil {
					return err
				}
			}
			if _, err := fmt.Fprintf(writer, "\n  **Status:** %s; **Limitations:** %s\n", candidate.Status, strings.Join(candidate.Limitations, "; ")); err != nil {
				return err
			}
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
