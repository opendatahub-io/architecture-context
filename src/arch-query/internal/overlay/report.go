package overlay

import (
	"fmt"
	"io"
	"sort"
	"text/tabwriter"

	"github.com/jctanner/arch-query/internal/types"
)

func GenerateCorrectionFrequencyReport(ps *types.ProposalSet, generatedAt string) (*types.CorrectionFrequencyReport, error) {
	if ps == nil {
		return nil, fmt.Errorf("proposal set is nil")
	}
	errs := ValidateProposalSet(ps)
	if len(errs) > 0 {
		return nil, fmt.Errorf("proposal set has %d validation error(s): %v", len(errs), errs[0])
	}

	report := &types.CorrectionFrequencyReport{
		ContractVersion: types.ReportContractVersion,
		GeneratedAt:     generatedAt,
		InputIdentity: types.ReportInputIdentity{
			ProposalContractVersion: ps.ContractVersion,
			ProposalGeneratedAt:     ps.GeneratedAt,
			TotalProposals:          len(ps.Proposals),
		},
	}

	componentCounts := make(map[string]map[string]int)
	categoryCounts := make(map[string]int)
	statusCounts := make(map[string]int)
	releaseCounts := make(map[string]int)
	supersededCount := 0

	for i := range ps.Proposals {
		p := &ps.Proposals[i]

		if p.Status == "superseded" {
			supersededCount++
			continue
		}

		if _, ok := componentCounts[p.Component]; !ok {
			componentCounts[p.Component] = make(map[string]int)
		}
		componentCounts[p.Component][p.Status]++

		categoryCounts[p.Category]++
		statusCounts[p.Status]++

		for _, r := range p.Releases {
			releaseCounts[r]++
		}
	}

	report.SupersededCount = supersededCount

	components := sortedKeys(componentCounts)
	for _, comp := range components {
		total := 0
		for _, c := range componentCounts[comp] {
			total += c
		}
		report.ByComponent = append(report.ByComponent, types.ComponentFrequency{
			Component: comp,
			Total:     total,
			ByStatus:  componentCounts[comp],
		})
	}
	sort.Slice(report.ByComponent, func(i, j int) bool {
		if report.ByComponent[i].Total != report.ByComponent[j].Total {
			return report.ByComponent[i].Total > report.ByComponent[j].Total
		}
		return report.ByComponent[i].Component < report.ByComponent[j].Component
	})

	for _, cat := range sortedKeysFromMap(categoryCounts) {
		report.ByCategory = append(report.ByCategory, types.CategoryFrequency{
			Category: cat,
			Total:    categoryCounts[cat],
		})
	}
	sort.Slice(report.ByCategory, func(i, j int) bool {
		if report.ByCategory[i].Total != report.ByCategory[j].Total {
			return report.ByCategory[i].Total > report.ByCategory[j].Total
		}
		return report.ByCategory[i].Category < report.ByCategory[j].Category
	})

	for _, st := range sortedKeysFromMap(statusCounts) {
		report.ByStatus = append(report.ByStatus, types.StatusFrequency{
			Status: st,
			Total:  statusCounts[st],
		})
	}
	sort.Slice(report.ByStatus, func(i, j int) bool {
		if report.ByStatus[i].Total != report.ByStatus[j].Total {
			return report.ByStatus[i].Total > report.ByStatus[j].Total
		}
		return report.ByStatus[i].Status < report.ByStatus[j].Status
	})

	for _, rel := range sortedKeysFromMap(releaseCounts) {
		report.ByRelease = append(report.ByRelease, types.ReleaseFrequency{
			Release: rel,
			Total:   releaseCounts[rel],
		})
	}
	sort.Slice(report.ByRelease, func(i, j int) bool {
		if report.ByRelease[i].Total != report.ByRelease[j].Total {
			return report.ByRelease[i].Total > report.ByRelease[j].Total
		}
		return report.ByRelease[i].Release < report.ByRelease[j].Release
	})

	activeCount := len(ps.Proposals) - supersededCount
	uniqueReleases := make(map[string]bool)
	for _, r := range report.ByRelease {
		uniqueReleases[r.Release] = true
	}
	report.Summary = types.ReportSummary{
		ActiveProposals: activeCount,
		Components:      len(report.ByComponent),
		Categories:      len(report.ByCategory),
		Releases:        len(uniqueReleases),
	}

	if report.ByComponent == nil {
		report.ByComponent = []types.ComponentFrequency{}
	}
	if report.ByCategory == nil {
		report.ByCategory = []types.CategoryFrequency{}
	}
	if report.ByStatus == nil {
		report.ByStatus = []types.StatusFrequency{}
	}

	return report, nil
}

func FormatReportText(w io.Writer, r *types.CorrectionFrequencyReport) {
	fmt.Fprintf(w, "Correction Frequency Report (contract %s)\n", r.ContractVersion)
	fmt.Fprintf(w, "Input: %d proposals (%d active, %d superseded)\n\n",
		r.InputIdentity.TotalProposals, r.Summary.ActiveProposals, r.SupersededCount)

	if len(r.ByComponent) > 0 {
		fmt.Fprintln(w, "By Component:")
		tw := tabwriter.NewWriter(w, 2, 4, 2, ' ', 0)
		fmt.Fprintf(tw, "  COMPONENT\tTOTAL\tPENDING\tREVIEWED\tREJECTED\n")
		for _, c := range r.ByComponent {
			fmt.Fprintf(tw, "  %s\t%d\t%d\t%d\t%d\n",
				c.Component, c.Total,
				c.ByStatus["pending"], c.ByStatus["reviewed"], c.ByStatus["rejected"])
		}
		tw.Flush()
		fmt.Fprintln(w)
	}

	if len(r.ByCategory) > 0 {
		fmt.Fprintln(w, "By Category:")
		tw := tabwriter.NewWriter(w, 2, 4, 2, ' ', 0)
		fmt.Fprintf(tw, "  CATEGORY\tTOTAL\n")
		for _, c := range r.ByCategory {
			fmt.Fprintf(tw, "  %s\t%d\n", c.Category, c.Total)
		}
		tw.Flush()
		fmt.Fprintln(w)
	}

	if len(r.ByStatus) > 0 {
		fmt.Fprintln(w, "By Status:")
		tw := tabwriter.NewWriter(w, 2, 4, 2, ' ', 0)
		fmt.Fprintf(tw, "  STATUS\tTOTAL\n")
		for _, s := range r.ByStatus {
			fmt.Fprintf(tw, "  %s\t%d\n", s.Status, s.Total)
		}
		tw.Flush()
		fmt.Fprintln(w)
	}

	if len(r.ByRelease) > 0 {
		fmt.Fprintln(w, "By Release:")
		tw := tabwriter.NewWriter(w, 2, 4, 2, ' ', 0)
		fmt.Fprintf(tw, "  RELEASE\tTOTAL\n")
		for _, rl := range r.ByRelease {
			fmt.Fprintf(tw, "  %s\t%d\n", rl.Release, rl.Total)
		}
		tw.Flush()
		fmt.Fprintln(w)
	}
}

func sortedKeys(m map[string]map[string]int) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func sortedKeysFromMap(m map[string]int) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
