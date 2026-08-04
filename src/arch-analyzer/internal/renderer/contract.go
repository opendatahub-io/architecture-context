package renderer

import (
	"fmt"
	"sort"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func renderContract(markdown *markdownWriter, contract *model.ContextContract) {
	if contract == nil {
		return
	}

	markdown.heading(2, "Context Contract")
	markdown.line("- **Contract Version**: %s", cell(contract.ContractVersion))
	markdown.blank()

	if p := contract.Provenance; p != nil {
		markdown.heading(3, "Provenance")
		markdown.line("- **Source**: %s", cell(p.Source))
		markdown.line("- **Extracted At**: %s", cell(p.ExtractedAt))
		markdown.line("- **Analyzer Version**: %s", cell(p.AnalyzerVersion))
		if p.CommitSHA != "" {
			markdown.line("- **Commit SHA**: %s", cell(p.CommitSHA))
		}
		if p.Repository != "" {
			markdown.line("- **Repository**: %s", cell(p.Repository))
		}
		markdown.line("- **Validation**: %s", validationLabel(p.Validation))
		markdown.blank()
	}

	if a := contract.Applicability; a != nil {
		markdown.heading(3, "Applicability")
		if a.Version != "" {
			markdown.line("- **Version**: %s", cell(a.Version))
		}
		if a.Release != "" {
			markdown.line("- **Release**: %s", cell(a.Release))
		}
		if a.ApplicableFrom != "" {
			markdown.line("- **Applicable From**: %s", cell(a.ApplicableFrom))
		}
		if a.ApplicableUntil != "" {
			markdown.line("- **Applicable Until**: %s", cell(a.ApplicableUntil))
		}
		if a.FreshnessWindow != "" {
			markdown.line("- **Freshness Window**: %s", cell(a.FreshnessWindow))
		}
		markdown.line("- **Validation**: %s", validationLabel(a.Validation))
		markdown.blank()
	}

	if c := contract.Confidence; c != nil {
		markdown.heading(3, "Confidence")
		markdown.line("- **Overall Validation**: %s", validationLabel(c.OverallValidation))
		if len(c.FactValidation) > 0 {
			keys := make([]string, 0, len(c.FactValidation))
			for k := range c.FactValidation {
				keys = append(keys, k)
			}
			sort.Strings(keys)
			for _, key := range keys {
				markdown.line("- **%s**: %s", cell(key), validationLabel(c.FactValidation[key]))
			}
		}
		markdown.blank()
	}

	if m := contract.Maturity; m != nil {
		markdown.heading(3, "Maturity")
		markdown.line("- **Lifecycle**: %s", cell(string(m.Lifecycle)))
		markdown.line("- **Validation**: %s", validationLabel(m.Validation))
		markdown.blank()
	}

	if s := contract.Scope; s != nil {
		markdown.heading(3, "Scope")
		if len(s.Limitations) > 0 {
			markdown.line("- **Limitations**:")
			for _, limitation := range s.Limitations {
				markdown.line("  - %s", cell(limitation))
			}
		}
		if s.DeploymentTopology != "" {
			markdown.line("- **Deployment Topology**: %s", cell(s.DeploymentTopology))
		}
		markdown.line("- **Validation**: %s", validationLabel(s.Validation))
		markdown.blank()
	}

	if len(contract.Dependencies) > 0 {
		markdown.heading(3, "Dependency Status")
		markdown.table(
			[]string{"Dependency", "Status", "Upstream", "Provenance", "Validation"},
			mapRows(contract.Dependencies, func(d model.ContractDependency) []string {
				return []string{
					d.Name,
					string(d.Status),
					d.Upstream,
					d.Provenance,
					string(d.Validation),
				}
			}),
		)
	}

	if b := contract.BehavioralEvidence; b != nil {
		markdown.heading(3, "Behavioral Evidence")
		if len(b.IntegrationConstraints) > 0 {
			markdown.line("- **Integration Constraints**:")
			for _, constraint := range b.IntegrationConstraints {
				markdown.line("  - %s", cell(constraint))
			}
		}
		if len(b.FailureModes) > 0 {
			markdown.line("- **Failure Modes**:")
			for _, mode := range b.FailureModes {
				markdown.line("  - %s", cell(mode))
			}
		}
		if len(b.TestTopology) > 0 {
			markdown.line("- **Test Topology**:")
			for _, topology := range b.TestTopology {
				markdown.line("  - %s", cell(topology))
			}
		}
		if len(b.PerformanceBaselines) > 0 {
			markdown.line("- **Performance Baselines**:")
			for _, baseline := range b.PerformanceBaselines {
				markdown.line("  - %s", cell(baseline))
			}
		}
		if len(b.ConfigurationRBAC) > 0 {
			markdown.line("- **Configuration/RBAC**:")
			for _, item := range b.ConfigurationRBAC {
				markdown.line("  - %s", cell(item))
			}
		}
		if len(b.ArchProviderMatrices) > 0 {
			markdown.line("- **Architecture/Provider Matrices**:")
			for _, item := range b.ArchProviderMatrices {
				markdown.line("  - %s", cell(item))
			}
		}
		if len(b.ObservableOutcomes) > 0 {
			markdown.line("- **Observable Outcomes**:")
			for _, item := range b.ObservableOutcomes {
				markdown.line("  - %s", cell(item))
			}
		}
		if len(b.ImageBuildStatus) > 0 {
			markdown.line("- **Image/Build Status**:")
			for _, item := range b.ImageBuildStatus {
				markdown.line("  - %s", cell(item))
			}
		}
		markdown.line("- **Validation**: %s", validationLabel(b.Validation))
		markdown.blank()
	}

	if cc := contract.ComponentClassification; cc != nil {
		markdown.heading(3, "Component Classification")
		if cc.Role != "" {
			markdown.line("- **Role**: %s", cell(cc.Role))
		}
		if cc.DeliveryIndependence != "" {
			markdown.line("- **Delivery Independence**: %s", cell(cc.DeliveryIndependence))
		}
		markdown.line("- **Validation**: %s", validationLabel(cc.Validation))
		markdown.blank()
	}
}

func validationLabel(state model.ValidationState) string {
	switch state {
	case model.ValidationConfirmed:
		return "confirmed"
	case model.ValidationNeedsValidation:
		return "needs-validation"
	case model.ValidationUnknown:
		return "unknown (value not determined)"
	case model.ValidationNotExtracted:
		return "not-extracted (extraction not attempted)"
	default:
		return fmt.Sprintf("unrecognized (%s)", string(state))
	}
}
