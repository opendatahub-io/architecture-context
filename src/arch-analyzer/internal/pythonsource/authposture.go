package pythonsource

import (
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func resolveAuthPosture(
	endpoints []model.HTTPEndpoint,
	authentication []model.AuthenticationFact,
) []model.AuthenticationFact {
	if !hasPythonEndpoints(endpoints) {
		return nil
	}
	if hasPythonSourceAuthFacts(authentication) {
		return nil
	}
	source := firstPythonEndpointSource(endpoints)
	return []model.AuthenticationFact{{
		Endpoint:         "HTTP API",
		Methods:          "All",
		Mechanism:        "None (no auth middleware detected)",
		EnforcementPoint: "FastAPI/Starlette application",
		Policy:           "No authentication middleware registered",
		Source:           source,
	}}
}

func hasPythonEndpoints(endpoints []model.HTTPEndpoint) bool {
	for _, ep := range endpoints {
		if isPythonSource(ep.Source) {
			return true
		}
	}
	return false
}

func hasPythonSourceAuthFacts(facts []model.AuthenticationFact) bool {
	for _, fact := range facts {
		if isPythonSource(fact.Source) {
			return true
		}
	}
	return false
}

func firstPythonEndpointSource(endpoints []model.HTTPEndpoint) string {
	for _, ep := range endpoints {
		if isPythonSource(ep.Source) {
			return ep.Source
		}
	}
	return ""
}

func isPythonSource(source string) bool {
	file := strings.SplitN(source, ":", 2)[0]
	return strings.HasSuffix(file, ".py")
}
