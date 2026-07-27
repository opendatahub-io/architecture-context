package extractor

import (
	"fmt"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

// crossReferences joins facts only when the join key is explicit: a service
// name/reference, an endpoint owner, a webhook service reference, or an exact
// port. It intentionally does not guess from component names or prose.
func crossReferences(input model.Input) []model.CrossReference {
	var result []model.CrossReference
	seen := map[string]bool{}
	add := func(ref model.CrossReference) {
		if ref.From == "" || ref.To == "" || ref.Relationship == "" || len(ref.Sources) == 0 {
			return
		}
		key := ref.Kind + "\x00" + ref.From + "\x00" + ref.To + "\x00" + ref.Relationship
		if seen[key] {
			return
		}
		seen[key] = true
		ref.Sources = uniqueStrings(ref.Sources)
		result = append(result, ref)
	}
	for _, endpoint := range input.HTTPEndpoints {
		for _, service := range input.Services {
			matched := endpoint.Owner != "" && (endpoint.Owner == service.Name || endpoint.Owner == service.TargetDeployment)
			if !matched && endpoint.Port != nil {
				for _, port := range service.Ports {
					if scalarAny(port.Port) == scalarAny(endpoint.Port) || scalarAny(port.TargetPort) == scalarAny(endpoint.Port) {
						matched = true
						break
					}
				}
			}
			if !matched {
				continue
			}
			add(model.CrossReference{
				Kind: "network", From: "HTTP " + endpoint.Method + " " + endpoint.Path,
				To: service.Name, Relationship: "served-by", Details: "endpoint and service share an explicit owner or port",
				Sources: []string{endpoint.Source, service.Source},
			})
		}
	}
	for _, webhook := range input.Webhooks {
		if webhook.ServiceRef == "" {
			continue
		}
		for _, service := range input.Services {
			if service.Name != webhook.ServiceRef {
				continue
			}
			add(model.CrossReference{
				Kind: "webhook", From: webhook.Name, To: service.Name, Relationship: "served-by",
				Details: "admission webhook declares an explicit service reference",
				Sources: append(webhookSources(webhook), service.Source),
			})
		}
	}
	for _, auth := range input.Authentication {
		for _, endpoint := range input.HTTPEndpoints {
			if auth.Endpoint != endpoint.Path && auth.Endpoint != "*" {
				continue
			}
			add(model.CrossReference{
				Kind: "security", From: endpoint.Method + " " + endpoint.Path, To: auth.Mechanism,
				Relationship: "protected-by", Details: auth.EnforcementPoint + ": " + auth.Policy,
				Sources: []string{endpoint.Source, auth.Source},
			})
		}
	}
	for _, watch := range input.ControllerWatches {
		for _, ref := range input.ComponentRefs {
			if ref.Reference != watch.GVK && ref.Component != watch.GVK {
				continue
			}
			add(model.CrossReference{
				Kind: "controller", From: watch.Controller, To: ref.Component, Relationship: "watches-reference",
				Details: watch.GVK, Sources: []string{watch.Source, ref.Source},
			})
		}
	}
	sort.Slice(result, func(i, j int) bool {
		if result[i].Kind != result[j].Kind {
			return result[i].Kind < result[j].Kind
		}
		if result[i].From != result[j].From {
			return result[i].From < result[j].From
		}
		return result[i].To < result[j].To
	})
	return result
}

func webhookSources(webhook model.Webhook) []string {
	var sources []string
	for _, source := range webhook.Sources {
		if source.File == "" {
			continue
		}
		if source.Line > 0 {
			sources = append(sources, fmt.Sprintf("%s:%d", source.File, source.Line))
		} else {
			sources = append(sources, source.File)
		}
	}
	return sources
}

func coverageFindings(input model.Input) []model.CoverageFinding {
	counts := map[string]int{
		"crds": validCRDCount(input.CRDs), "grpc_services": len(input.GRPCServices),
		"http_endpoints": len(input.HTTPEndpoints), "services": len(input.Services),
		"ingress": len(input.IngressRouting), "webhooks": len(input.Webhooks),
	}
	coverage := map[string]model.CategoryCoverage{
		"crds": {Status: input.DataCoverage["go_crds"]}, "grpc_services": input.CategoryCoverage["grpc_services"],
		"http_endpoints": input.CategoryCoverage["http_endpoints"], "services": input.CategoryCoverage["services"],
		"ingress": {Status: input.DataCoverage["manifests"]}, "webhooks": {Status: input.CategoryCoverage["http_endpoints"].Status},
	}
	var result []model.CoverageFinding
	for _, category := range []string{"crds", "grpc_services", "http_endpoints", "services", "ingress", "webhooks"} {
		status := "observed"
		if counts[category] == 0 {
			status = "not-verified"
		}
		if counts[category] == 0 && coverage[category].Status == "complete" {
			status = "confirmed-empty"
		}
		finding := fmt.Sprintf("%d %s facts extracted", counts[category], category)
		if counts[category] == 0 && status == "not-verified" {
			finding += "; absence is not proven by the available coverage"
		}
		result = append(result, model.CoverageFinding{Category: category, Status: status, Finding: finding, Sources: coverageSources(input, category)})
	}
	return result
}

func coverageSources(input model.Input, category string) []string {
	var sources []string
	switch category {
	case "crds":
		for _, fact := range input.CRDs {
			sources = append(sources, fact.Source)
		}
	case "grpc_services":
		for _, fact := range input.GRPCServices {
			sources = append(sources, fact.Source)
		}
	case "http_endpoints":
		for _, fact := range input.HTTPEndpoints {
			sources = append(sources, fact.Source)
		}
	case "services":
		for _, fact := range input.Services {
			sources = append(sources, fact.Source)
		}
	case "ingress":
		for _, fact := range input.IngressRouting {
			sources = append(sources, fact.Source)
		}
	case "webhooks":
		for _, fact := range input.Webhooks {
			sources = append(sources, webhookSources(fact)...)
		}
	}
	return uniqueStrings(sources)
}

func synthesisEvidence(input model.Input) map[string][]model.EvidenceRecord {
	result := map[string][]model.EvidenceRecord{}
	add := func(category, claim string, sources ...string) {
		sources = uniqueStrings(sources)
		if strings.TrimSpace(claim) == "" || len(sources) == 0 || len(result[category]) >= 40 {
			return
		}
		result[category] = append(result[category], model.EvidenceRecord{Claim: claim, Sources: sources})
	}
	for _, endpoint := range input.HTTPEndpoints {
		add("http_endpoints", fmt.Sprintf("%s %s on port %s; transport=%s encryption=%s auth=%s owner=%s", endpoint.Method, endpoint.Path, scalarAny(endpoint.Port), endpoint.Transport, endpoint.Encryption, endpoint.Auth, endpoint.Owner), endpoint.Source)
	}
	for _, service := range input.Services {
		for _, port := range service.Ports {
			add("services", fmt.Sprintf("%s port=%s target=%s protocol=%s encryption=%s auth=%s", service.Name, scalarAny(port.Port), scalarAny(port.TargetPort), port.Protocol, port.Encryption, port.Auth), service.Source)
		}
	}
	for _, dependency := range input.Dependencies.Internal {
		add("internal_dependencies", fmt.Sprintf("%s interaction=%s role=%s purpose=%s", dependency.Component, dependency.Interaction, dependency.Role, dependency.Purpose), dependency.Source)
	}
	for _, integration := range input.IntegrationPoints {
		add("integrations", fmt.Sprintf("%s interaction=%s role=%s protocol=%s purpose=%s", integration.Component, integration.InteractionType, integration.Role, integration.Protocol, integration.Purpose), integration.Source)
	}
	for _, auth := range input.Authentication {
		add("authentication", fmt.Sprintf("%s methods=%s mechanism=%s enforcement=%s policy=%s", auth.Endpoint, auth.Methods, auth.Mechanism, auth.EnforcementPoint, auth.Policy), auth.Source)
	}
	for category := range result {
		sort.Slice(result[category], func(i, j int) bool { return result[category][i].Claim < result[category][j].Claim })
	}
	return result
}

func scalarAny(value any) string {
	switch typed := value.(type) {
	case nil:
		return ""
	case string:
		return typed
	case float64:
		if typed == float64(int64(typed)) {
			return strconv.FormatInt(int64(typed), 10)
		}
		return strconv.FormatFloat(typed, 'f', -1, 64)
	default:
		return fmt.Sprint(typed)
	}
}

func uniqueStrings(values []string) []string {
	seen := map[string]bool{}
	result := make([]string, 0, len(values))
	for _, value := range values {
		if value != "" && !seen[value] {
			seen[value] = true
			result = append(result, value)
		}
	}
	sort.Strings(result)
	return result
}
