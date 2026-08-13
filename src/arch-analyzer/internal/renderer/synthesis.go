package renderer

import (
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

const synthesisListLimit = 4

func deterministicShortPurpose(document model.Document) string {
	component := proseFallback(document.Component, "This component")
	interfaceCount := len(document.HTTPEndpoints) + len(document.GRPCServices) + len(document.CRDs) + len(document.ServingRuntimes)
	return fmt.Sprintf(
		"Source-backed analysis represents %s as %s with %s, %s, and %s.",
		component,
		proseFallback(document.Metadata.DeploymentType, "an architecture component"),
		countPhrase(len(document.ArchitectureComponents), "runtime component"),
		countPhrase(interfaceCount, "API identity"),
		countPhrase(len(document.IntegrationPoints), "integration point"),
	) + sourceCitation(document, "Architecture Components", "APIs Exposed", "Dependencies")
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
	interfaceCount := len(document.HTTPEndpoints) + len(document.GRPCServices) + len(document.CRDs) + len(document.ServingRuntimes)
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
	parts = append(parts, "This description is limited to typed, source-backed analyzer facts."+sourceCitation(document, "Architecture Components", "APIs Exposed", "Dependencies"))
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
		)+sourceCitation(document, "APIs Exposed", "Network Architecture"))
	}
	if len(document.ArchitectureComponents) > 0 {
		runtimeDefinitions := ""
		if len(document.ServingRuntimes) > 0 {
			runtimeDefinitions = " The packaged runtime inventory also includes " + countPhrase(len(document.ServingRuntimes), "serving runtime definition") + "."
		}
		flows = append(flows, fmt.Sprintf(
			"**Runtime inventory:** The extracted deployment and source facts identify %s: %s.%s The analyzer does not infer request flow or ordering between these components unless a structured integration states it.",
			countPhrase(len(document.ArchitectureComponents), "runtime component"),
			joinedList(architectureComponentNames(document.ArchitectureComponents)),
			runtimeDefinitions,
		)+sourceCitation(document, "Architecture Components", "APIs Exposed"))
	}
	if len(document.IntegrationPoints)+len(document.InternalDependencies)+len(document.Egress) > 0 {
		flows = append(flows, fmt.Sprintf(
			"**Downstream interactions:** The structured facts record %s, %s, and %s. Named destinations include %s.",
			countPhrase(len(document.IntegrationPoints), "integration point"),
			countPhrase(len(document.InternalDependencies), "internal dependency"),
			countPhrase(len(document.Egress), "egress destination"),
			joinedList(integrationNames(document)),
		)+sourceCitation(document, "Integration Points", "Dependencies", "Network Architecture"))
	}
	if len(document.Authentication)+len(document.Secrets) > 0 {
		flows = append(flows, fmt.Sprintf(
			"**Security context:** %s and %s describe the extracted enforcement and credential inputs applied around these interactions; unknown values remain explicit in the tables.",
			countPhrase(len(document.Authentication), "authentication rule"),
			countPhrase(len(document.Secrets), "secret reference"),
		)+sourceCitation(document, "Security"))
	}
	if len(flows) == 0 {
		flows = append(flows, "The available analyzer facts do not establish a complete runtime flow; the structured tables and source references delimit the evidence currently available.")
	}
	return flows
}

func deterministicIntegrationPoints(document model.Document) []string {
	if len(document.IntegrationPoints) == 0 {
		return []string{"The analyzer found no explicit integration point relationship; this is not evidence that the component has no runtime dependencies." + sourceCitation(document, "Integration Points", "Dependencies")}
	}

	points := make([]string, 0, min(len(document.IntegrationPoints), synthesisListLimit)+1)
	for _, point := range document.IntegrationPoints {
		name := proseFallback(point.Component, "unnamed destination")
		interaction := proseFallback(point.InteractionType, "unknown interaction")
		detail := interaction
		if point.Role != "" {
			detail += "; role: " + proseValue(point.Role)
		}
		if point.Protocol != "" {
			detail += "; protocol: " + proseValue(point.Protocol)
		}
		if point.Port != "" {
			detail += "; port: " + proseValue(point.Port)
		}
		if point.Purpose != "" {
			detail += "; purpose: " + proseValue(point.Purpose)
		}
		points = append(points, fmt.Sprintf("**%s:** %s.", name, detail)+sourceCitation(document, "Integration Points", "Dependencies", "Network Architecture"))
		if len(points) == synthesisListLimit {
			break
		}
	}
	if len(document.IntegrationPoints) > len(points) {
		points = append(points, fmt.Sprintf("**Additional relationships:** %d more integration point(s) are listed in the structured table.", len(document.IntegrationPoints)-len(points))+sourceCitation(document, "Integration Points", "Dependencies"))
	}
	return points
}

func deterministicArchitecturalAnalysis(document model.Document) []string {
	analysis := []string{
		fmt.Sprintf(
			"**Deployment shape:** The normalized deployment type is %s, represented by %s and %s.",
			proseFallback(document.Metadata.DeploymentType, "Unknown"),
			countPhrase(len(document.ArchitectureComponents), "architecture component"),
			countPhrase(len(document.Services), "service identity"),
		) + sourceCitation(document, "Architecture Components", "Network Architecture"),
	}
	if len(document.CRDs)+len(document.ClusterRoles)+len(document.RoleBindings) > 0 {
		analysis = append(analysis, fmt.Sprintf(
			"**Control-plane surface:** The document contains %s, %s, and %s, exposing the extracted Kubernetes API and authorization footprint without inferring permissions beyond listed rules.",
			countPhrase(len(document.CRDs), "CRD identity"),
			countPhrase(len(document.ClusterRoles), "RBAC rule"),
			countPhrase(len(document.RoleBindings), "role binding"),
		)+sourceCitation(document, "APIs Exposed", "Security"))
	}
	if len(document.Authentication)+len(document.Secrets)+len(document.Ingress)+len(document.Egress) > 0 {
		analysis = append(analysis, fmt.Sprintf(
			"**Security and network evidence:** %s, %s, %s, and %s capture the known enforcement, credential, exposure, and outbound boundaries. Empty or Unknown cells are not promoted into claims.",
			countPhrase(len(document.Authentication), "authentication rule"),
			countPhrase(len(document.Secrets), "secret reference"),
			countPhrase(len(document.Ingress), "ingress identity"),
			countPhrase(len(document.Egress), "egress identity"),
		)+sourceCitation(document, "Security", "Network Architecture"))
	}
	if partial := partialCoverageNames(document.DataCoverage); len(partial) > 0 {
		analysis = append(analysis, "**Evidence boundary:** Analyzer coverage is partial for "+joinedList(partial)+". Dynamic behavior outside the extracted literal and manifest evidence is not asserted."+sourceCitation(document, "Architecture Components", "APIs Exposed", "Network Architecture", "Integration Points", "Security"))
	} else {
		analysis = append(analysis, "**Evidence boundary:** The analysis is constrained to structured facts and inline source citations in this document; behavior not represented there is not asserted."+sourceCitation(document, "Architecture Components", "APIs Exposed", "Network Architecture", "Integration Points", "Security"))
	}
	return analysis
}

// sourceCitation turns the normalized section-to-source index into a small,
// deterministic provenance marker for narrative claims. It intentionally
// limits the number of files so generated prose remains useful to a synthesis
// agent; detailed agent source-read audit metadata belongs in generation
// sidecars rather than the final Markdown.
func sourceCitation(document model.Document, sections ...string) string {
	wanted := make(map[string]bool, len(sections))
	for _, section := range sections {
		wanted[section] = true
	}
	refs := make([]string, 0, synthesisListLimit)
	for _, source := range document.Sources {
		matched := false
		for _, section := range strings.Split(source.Sections, ",") {
			if wanted[strings.TrimSpace(section)] {
				matched = true
				break
			}
		}
		if !matched || strings.TrimSpace(source.File) == "" {
			continue
		}
		ref := proseValue(source.File)
		if strings.TrimSpace(source.Lines) != "" && strings.TrimSpace(source.Lines) != "Unknown" {
			ref += ":" + collapseLineRanges(source.Lines)
		}
		refs = append(refs, ref)
		if len(refs) == synthesisListLimit {
			break
		}
	}
	if len(refs) == 0 {
		return " [source: no section-specific file recorded]"
	}
	return " [source: " + strings.Join(refs, ", ") + "]"
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
	if len(document.ServingRuntimes) > 0 {
		parts = append(parts, countPhrase(len(document.ServingRuntimes), "serving runtime definition"))
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

// collapseLineRanges turns "2, 26, 28, 29, 30, 31, 32" into "2, 26, 28-32".
func collapseLineRanges(lines string) string {
	parts := strings.Split(lines, ",")
	nums := make([]int, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if n, err := strconv.Atoi(p); err == nil {
			nums = append(nums, n)
		}
	}
	if len(nums) == 0 {
		return strings.TrimSpace(lines)
	}
	sort.Ints(nums)

	var ranges []string
	start, end := nums[0], nums[0]
	for _, n := range nums[1:] {
		if n == end+1 {
			end = n
		} else {
			ranges = append(ranges, lineRange(start, end))
			start, end = n, n
		}
	}
	ranges = append(ranges, lineRange(start, end))
	return strings.Join(ranges, ", ")
}

func lineRange(start, end int) string {
	if start == end {
		return strconv.Itoa(start)
	}
	return strconv.Itoa(start) + "-" + strconv.Itoa(end)
}
