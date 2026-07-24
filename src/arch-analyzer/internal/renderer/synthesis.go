package renderer

import (
	"fmt"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const synthesisListLimit = 4

func deterministicShortPurpose(document model.Document) string {
	component := proseFallback(document.Component, "This component")
	interfaceCount := len(document.HTTPEndpoints) + len(document.GRPCServices) + len(document.CRDs)
	return fmt.Sprintf(
		"Source-backed analysis represents %s as %s with %s, %s, and %s.",
		component,
		proseFallback(document.Metadata.DeploymentType, "an architecture component"),
		countPhrase(len(document.ArchitectureComponents), "runtime component"),
		countPhrase(interfaceCount, "API identity"),
		countPhrase(len(document.IntegrationPoints), "integration point"),
	)
}

func deterministicDetailedPurpose(document model.Document) string {
	component := proseValue(document.Component)
	if component == "" {
		component = "This component"
	}
	parts := []string{
		fmt.Sprintf(
			"%s is represented by %s in the extracted architecture evidence.",
			component,
			countPhrase(len(document.ArchitectureComponents), "architecture component"),
		),
	}
	if names := architectureComponentSummaries(document.ArchitectureComponents); len(names) > 0 {
		parts = append(parts, "The principal extracted components are "+joinedList(names)+".")
	}
	interfaceCount := len(document.HTTPEndpoints) + len(document.GRPCServices) + len(document.CRDs)
	if interfaceCount > 0 {
		parts = append(parts, fmt.Sprintf(
			"Its documented interface surface contains %s, including %s.",
			countPhrase(interfaceCount, "API identity"),
			interfaceSummary(document),
		))
	}
	if len(document.IntegrationPoints)+len(document.InternalDependencies) > 0 {
		parts = append(parts, fmt.Sprintf(
			"The extracted dependency view records %s and %s.",
			countPhrase(len(document.InternalDependencies), "internal platform dependency"),
			countPhrase(len(document.IntegrationPoints), "integration point"),
		))
	}
	parts = append(parts, "This description is limited to typed, source-backed analyzer facts.")
	return strings.Join(parts, " ")
}

func deterministicDataFlows(document model.Document) []string {
	var flows []string
	if len(document.Ingress)+len(document.Services)+len(document.HTTPEndpoints)+len(document.GRPCServices) > 0 {
		flows = append(flows, fmt.Sprintf(
			"**Entry and service surface:** The analyzer associates %s and %s with %s and %s; the corresponding tables retain protocol, port, encryption, and authentication details when extracted.",
			countPhrase(len(document.Ingress), "ingress identity"),
			countPhrase(len(document.Services), "Kubernetes Service identity"),
			countPhrase(len(document.HTTPEndpoints), "HTTP endpoint"),
			countPhrase(len(document.GRPCServices), "gRPC service"),
		))
	}
	if len(document.ArchitectureComponents) > 0 {
		flows = append(flows, fmt.Sprintf(
			"**Runtime inventory:** The extracted deployment and source facts identify %s: %s. The analyzer does not infer request flow or ordering between these components unless a structured integration states it.",
			countPhrase(len(document.ArchitectureComponents), "runtime component"),
			joinedList(architectureComponentNames(document.ArchitectureComponents)),
		))
	}
	if len(document.IntegrationPoints)+len(document.InternalDependencies)+len(document.Egress) > 0 {
		flows = append(flows, fmt.Sprintf(
			"**Downstream interactions:** The structured facts record %s, %s, and %s. Named destinations include %s.",
			countPhrase(len(document.IntegrationPoints), "integration point"),
			countPhrase(len(document.InternalDependencies), "internal dependency"),
			countPhrase(len(document.Egress), "egress destination"),
			joinedList(integrationNames(document)),
		))
	}
	if len(document.Authentication)+len(document.Secrets) > 0 {
		flows = append(flows, fmt.Sprintf(
			"**Security context:** %s and %s describe the extracted enforcement and credential inputs applied around these interactions; unknown values remain explicit in the tables.",
			countPhrase(len(document.Authentication), "authentication rule"),
			countPhrase(len(document.Secrets), "secret reference"),
		))
	}
	if len(flows) == 0 {
		flows = append(flows, "The available analyzer facts do not establish a complete runtime flow; the structured tables and source references delimit the evidence currently available.")
	}
	return flows
}

func deterministicArchitecturalAnalysis(document model.Document) []string {
	analysis := []string{
		fmt.Sprintf(
			"**Deployment shape:** The normalized deployment type is %s, represented by %s and %s.",
			proseFallback(document.Metadata.DeploymentType, "Unknown"),
			countPhrase(len(document.ArchitectureComponents), "architecture component"),
			countPhrase(len(document.Services), "service identity"),
		),
	}
	if len(document.CRDs)+len(document.ClusterRoles)+len(document.RoleBindings) > 0 {
		analysis = append(analysis, fmt.Sprintf(
			"**Control-plane surface:** The document contains %s, %s, and %s, exposing the extracted Kubernetes API and authorization footprint without inferring permissions beyond listed rules.",
			countPhrase(len(document.CRDs), "CRD identity"),
			countPhrase(len(document.ClusterRoles), "RBAC rule"),
			countPhrase(len(document.RoleBindings), "role binding"),
		))
	}
	if len(document.Authentication)+len(document.Secrets)+len(document.Ingress)+len(document.Egress) > 0 {
		analysis = append(analysis, fmt.Sprintf(
			"**Security and network evidence:** %s, %s, %s, and %s capture the known enforcement, credential, exposure, and outbound boundaries. Empty or Unknown cells are not promoted into claims.",
			countPhrase(len(document.Authentication), "authentication rule"),
			countPhrase(len(document.Secrets), "secret reference"),
			countPhrase(len(document.Ingress), "ingress identity"),
			countPhrase(len(document.Egress), "egress identity"),
		))
	}
	if partial := partialCoverageNames(document.DataCoverage); len(partial) > 0 {
		analysis = append(analysis, "**Evidence boundary:** Analyzer coverage is partial for "+joinedList(partial)+". Dynamic behavior outside the extracted literal and manifest evidence is not asserted.")
	} else {
		analysis = append(analysis, "**Evidence boundary:** The analysis is constrained to the structured facts and source references in this document; behavior not represented there is not asserted.")
	}
	return analysis
}

func architectureComponentSummaries(rows []model.ArchitectureComponent) []string {
	values := make([]string, 0, min(len(rows), synthesisListLimit))
	for _, row := range rows {
		value := proseValue(row.Component)
		var details []string
		if row.Type != "" {
			details = append(details, proseValue(row.Type))
		}
		if row.Purpose != "" {
			details = append(details, proseValue(row.Purpose))
		}
		if len(details) > 0 {
			value += " (" + strings.Join(details, "; ") + ")"
		}
		if value != "" {
			values = append(values, value)
		}
		if len(values) == synthesisListLimit {
			break
		}
	}
	if len(rows) > len(values) {
		values = append(values, countPhrase(len(rows)-len(values), "additional component")+" listed in the table")
	}
	return values
}

func architectureComponentNames(rows []model.ArchitectureComponent) []string {
	values := make([]string, 0, min(len(rows), synthesisListLimit))
	for _, row := range rows {
		if value := proseValue(row.Component); value != "" {
			values = append(values, value)
		}
		if len(values) == synthesisListLimit {
			break
		}
	}
	if len(rows) > len(values) {
		values = append(values, countPhrase(len(rows)-len(values), "additional component"))
	}
	return values
}

func interfaceSummary(document model.Document) string {
	var parts []string
	if len(document.HTTPEndpoints) > 0 {
		parts = append(parts, countPhrase(len(document.HTTPEndpoints), "HTTP endpoint"))
	}
	if len(document.GRPCServices) > 0 {
		parts = append(parts, countPhrase(len(document.GRPCServices), "gRPC service"))
	}
	if len(document.CRDs) > 0 {
		parts = append(parts, countPhrase(len(document.CRDs), "custom resource identity"))
	}
	return joinedList(parts)
}

func integrationNames(document model.Document) []string {
	seen := map[string]bool{}
	var names []string
	add := func(value string) {
		value = proseValue(value)
		if value == "" || seen[value] || len(names) == synthesisListLimit {
			return
		}
		seen[value] = true
		names = append(names, value)
	}
	for _, row := range document.InternalDependencies {
		add(row.Component)
	}
	for _, row := range document.IntegrationPoints {
		add(row.Component)
	}
	for _, row := range document.Egress {
		add(row.Destination)
	}
	if len(document.InternalDependencies)+len(document.IntegrationPoints)+len(document.Egress) > len(names) {
		names = append(names, "additional destinations listed in the tables")
	}
	return names
}

func partialCoverageNames(coverage map[string]string) []string {
	var names []string
	for name, detail := range coverage {
		if strings.HasPrefix(strings.ToLower(strings.TrimSpace(detail)), "partial:") {
			names = append(names, proseValue(name))
		}
	}
	sort.Strings(names)
	if len(names) > synthesisListLimit {
		names = append(names[:synthesisListLimit], countPhrase(len(names)-synthesisListLimit, "additional surface"))
	}
	return names
}

func countPhrase(count int, singular string) string {
	if count == 1 {
		return "1 " + singular
	}
	plural := singular + "s"
	if strings.HasSuffix(singular, "y") {
		plural = strings.TrimSuffix(singular, "y") + "ies"
	}
	return fmt.Sprintf("%d %s", count, plural)
}

func joinedList(values []string) string {
	values = nonEmpty(values)
	switch len(values) {
	case 0:
		return "none recorded"
	case 1:
		return values[0]
	case 2:
		return values[0] + " and " + values[1]
	default:
		return strings.Join(values[:len(values)-1], ", ") + ", and " + values[len(values)-1]
	}
}

func nonEmpty(values []string) []string {
	result := make([]string, 0, len(values))
	for _, value := range values {
		if value = proseValue(value); value != "" {
			result = append(result, value)
		}
	}
	return result
}

func proseFallback(value, fallback string) string {
	if value = proseValue(value); value != "" {
		return value
	}
	return fallback
}

func proseValue(value string) string {
	value = strings.ReplaceAll(value, "\r", " ")
	value = strings.ReplaceAll(value, "\n", " ")
	value = strings.ReplaceAll(value, "|", "/")
	return strings.Join(strings.Fields(value), " ")
}
