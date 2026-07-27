package extractor

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/jctanner/arch-analyzer/internal/gosource"
	"github.com/jctanner/arch-analyzer/internal/model"
	"github.com/jctanner/arch-analyzer/internal/platformfacts"
	"github.com/jctanner/arch-analyzer/internal/pythonsource"
	"github.com/jctanner/arch-analyzer/internal/rustsource"
	"github.com/jctanner/arch-analyzer/internal/websource"
)

const analyzerVersion = "0.1.0-dev"

type Options struct {
	Distribution     string
	Overlay          string
	SupplementalAuth []model.AuthenticationFact
}

func Extract(root string, options Options) (model.Input, error) {
	absoluteRoot, err := filepath.Abs(root)
	if err != nil {
		return model.Input{}, fmt.Errorf("resolve repository path: %w", err)
	}
	manifestRoot, err := selectManifestRoot(absoluteRoot, options.Overlay, options.Distribution)
	if err != nil {
		return model.Input{}, err
	}

	var objects []object
	kustomizeCoverage := "not_used"
	manifestCoverage := "complete"
	if manifestRoot != "" {
		resolver := &loader{root: absoluteRoot, visiting: map[string]bool{}}
		objects, err = resolver.load(manifestRoot)
		kustomizeCoverage = "complete"
		if len(resolver.warnings) > 0 {
			sort.Strings(resolver.warnings)
			kustomizeCoverage = "partial: " + strings.Join(resolver.warnings, "; ")
		}
	} else {
		var warnings []string
		objects, warnings, err = loadAllYAML(absoluteRoot)
		if len(warnings) > 0 {
			manifestCoverage = "partial: " + strings.Join(warnings, "; ")
		}
	}
	if err != nil {
		return model.Input{}, err
	}
	objects = dedupeObjects(objects)

	repository := gitValue(absoluteRoot, "config", "--get", "remote.origin.url")
	gitRoot := gitValue(absoluteRoot, "rev-parse", "--show-toplevel")
	input := model.Input{
		Component:       componentName(repository, absoluteRoot, gitRoot),
		Repo:            repository,
		CommitSHA:       gitValue(absoluteRoot, "rev-parse", "HEAD"),
		ExtractedAt:     time.Now().UTC().Format(time.RFC3339),
		AnalyzerVersion: analyzerVersion,
		SchemaVersion:   "1",
		DataCoverage: map[string]string{
			"manifests": manifestCoverage,
			"kustomize": kustomizeCoverage,
			"source":    "not_analyzed",
		},
	}
	collect(objects, &input)
	sourceWebhooks, webhookCoverage := discoverSourceWebhooks(absoluteRoot, input.Component)
	input.Webhooks = mergeSourceWebhooks(input.Webhooks, sourceWebhooks)
	input.DataCoverage["webhooks_source"] = webhookCoverage
	moduleConfigObjects, moduleConfigWarnings, err := loadGoModuleConfigObjects(absoluteRoot)
	if err != nil {
		return model.Input{}, err
	}
	mergeGoModuleConfigFacts(&input, moduleConfigObjects)
	input.DataCoverage["go_module_configs"] = moduleConfigCoverage(moduleConfigObjects, moduleConfigWarnings)
	input.SourceComponents = append(input.SourceComponents, sidecarComponents(input.Deployments)...)
	sourceFacts, err := gosource.Extract(absoluteRoot)
	if err != nil {
		return model.Input{}, fmt.Errorf("extract Go source: %w", err)
	}
	manifestInternal := input.Dependencies.Internal
	input.Dependencies = sourceFacts.Dependencies
	input.Dependencies.Internal = append(manifestInternal, input.Dependencies.Internal...)
	input.SourceComponents = append(input.SourceComponents, sourceFacts.Components...)
	input.Dependencies.Packages = append(input.Dependencies.Packages, semanticGoDependencies(sourceFacts)...)
	input.ControllerWatches = append(input.ControllerWatches, sourceFacts.ControllerWatches...)
	input.HTTPEndpoints = append(input.HTTPEndpoints, sourceFacts.HTTPEndpoints...)
	input.GRPCServices = append(input.GRPCServices, sourceFacts.GRPCServices...)
	input.Authentication = append(input.Authentication, sourceFacts.Authentication...)
	input.RuntimeClients = append(input.RuntimeClients, sourceFacts.RuntimeClients...)
	input.RuntimeModuleUses = append(input.RuntimeModuleUses, sourceFacts.RuntimeModuleUses...)
	input.RuntimeManagedUses = append(input.RuntimeManagedUses, sourceFacts.RuntimeManagedUses...)
	input.RuntimeServers = append(input.RuntimeServers, sourceFacts.RuntimeServers...)
	input.RuntimeSecurity = append(input.RuntimeSecurity, sourceFacts.RuntimeSecurity...)
	input.RuntimeProxies = append(input.RuntimeProxies, sourceFacts.RuntimeProxies...)
	input.RuntimeWebhooks = append(input.RuntimeWebhooks, sourceFacts.RuntimeWebhooks...)
	input.AccessPolicies = append(input.AccessPolicies, sourceFacts.AccessPolicies...)
	input.ComponentRefs = append(input.ComponentRefs, sourceFacts.ComponentRefs...)
	input.DataCoverage["source"] = sourceFacts.Coverage
	input.CRDs = mergeCRDFacts(input.CRDs, sourceFacts.CRDs)
	input.APIReferenceContracts = append(input.APIReferenceContracts, sourceFacts.APIReferenceContracts...)
	input.DataCoverage["go_crds"] = sourceFacts.CRDCoverage
	templateFacts, usedDefaults, templateCoverage, err := extractControllerTemplates(
		absoluteRoot,
		sourceFacts.EmbeddedManifests,
		sourceFacts.TemplateDefaults,
	)
	if err != nil {
		return model.Input{}, fmt.Errorf("extract controller templates: %w", err)
	}
	input.SourceDefaults = sourceDefaults(sourceFacts.TemplateDefaults, usedDefaults)
	mergeTemplateFacts(&input, templateFacts)
	mergeConstructedSecrets(&input, sourceFacts.ConstructedSecrets)
	input.RBAC.ClusterRoleBindings = append(input.RBAC.ClusterRoleBindings, sourceFacts.ConstructedBindings...)
	input.DataCoverage["controller_templates"] = templateCoverage
	rustFacts, err := rustsource.Extract(absoluteRoot)
	if err != nil {
		return model.Input{}, fmt.Errorf("extract Rust source: %w", err)
	}
	input.SourceComponents = append(input.SourceComponents, rustFacts.Components...)
	input.Dependencies.Packages = append(input.Dependencies.Packages, rustFacts.Dependencies...)
	input.Dependencies.Internal = append(input.Dependencies.Internal, rustFacts.Internal...)
	input.HTTPEndpoints = append(input.HTTPEndpoints, rustFacts.HTTPEndpoints...)
	input.Services = append(input.Services, rustFacts.Services...)
	input.ExternalConnections = append(input.ExternalConnections, rustFacts.Connections...)
	input.Authentication = append(input.Authentication, rustFacts.Authentication...)
	mergeConstructedSecrets(&input, rustFacts.Secrets)
	input.DataCoverage["rust"] = rustFacts.Coverage
	pythonFacts, err := pythonsource.Extract(absoluteRoot)
	if err != nil {
		return model.Input{}, fmt.Errorf("extract Python source: %w", err)
	}
	input.SourceComponents = append(input.SourceComponents, pythonFacts.Components...)
	input.Dependencies.Packages = append(input.Dependencies.Packages, pythonFacts.Dependencies...)
	input.HTTPEndpoints = append(input.HTTPEndpoints, pythonFacts.HTTPEndpoints...)
	input.GRPCServices = append(input.GRPCServices, pythonFacts.GRPCServices...)
	input.Services = append(input.Services, pythonFacts.Services...)
	input.ExternalConnections = append(input.ExternalConnections, pythonFacts.Connections...)
	input.Authentication = append(input.Authentication, pythonFacts.Authentication...)
	input.Dependencies.Internal = append(input.Dependencies.Internal, pythonFacts.Internal...)
	input.IntegrationPoints = append(input.IntegrationPoints, pythonFacts.Integrations...)
	mergeConstructedSecrets(&input, pythonFacts.Secrets)
	input.DataCoverage["python"] = pythonFacts.Coverage
	webFacts, err := websource.Extract(absoluteRoot)
	if err != nil {
		return model.Input{}, fmt.Errorf("extract web workspace source: %w", err)
	}
	input.SourceComponents = append(input.SourceComponents, webFacts.Components...)
	input.Dependencies.Packages = append(input.Dependencies.Packages, webFacts.Dependencies...)
	input.HTTPEndpoints = append(input.HTTPEndpoints, webFacts.Endpoints...)
	mergeServiceSecurity(&input, webFacts.Services)
	secureProxyService(&input)
	input.DataCoverage["web_workspace"] = webFacts.Coverage
	input.RecentChanges = recentChanges(absoluteRoot, 7)
	platformFacts := platformfacts.Extract(absoluteRoot, input)
	input.SourceComponents = append(input.SourceComponents, platformFacts.Components...)
	input.Dependencies.Internal = append(input.Dependencies.Internal, platformFacts.Internal...)
	input.ExternalConnections = append(input.ExternalConnections, platformFacts.Connections...)
	input.Authentication = append(input.Authentication, platformFacts.Authentication...)
	input.IntegrationPoints = append(input.IntegrationPoints, platformFacts.Integrations...)
	input.DataCoverage["platform_semantics"] = platformFacts.Coverage
	input.Summary = fmt.Sprintf(
		"Static analysis found %d CRDs, %d workloads, %d services, %d RBAC roles, %d ingress routes, %d controller watches, %d registered HTTP endpoints, and %d gRPC services.",
		validCRDCount(input.CRDs), len(input.Deployments), len(input.Services),
		len(input.RBAC.ClusterRoles)+len(input.RBAC.Roles), len(input.IngressRouting),
		len(input.ControllerWatches), len(input.HTTPEndpoints), len(input.GRPCServices),
	)
	input.DataCoverage["agent_baseline"] = agentBaselineCoverage(input)
	input.Authentication = append(input.Authentication, expandSupplementalAuth(input.GRPCServices, options.SupplementalAuth)...)
	input.CategoryCoverage = categoryCoverage(absoluteRoot, input)
	return input, nil
}

func expandSupplementalAuth(services []model.GRPCService, supplemental []model.AuthenticationFact) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	for _, fact := range supplemental {
		if strings.EqualFold(strings.TrimSpace(fact.Methods), "gRPC") && fact.Endpoint == "*" {
			for _, svc := range services {
				result = append(result, model.AuthenticationFact{
					Endpoint:         svc.Service,
					Methods:          "gRPC",
					Mechanism:        fact.Mechanism,
					EnforcementPoint: fact.EnforcementPoint,
					Policy:           fact.Policy,
					Source:           fact.Source,
				})
			}
			continue
		}
		result = append(result, fact)
	}
	return result
}

func agentBaselineCoverage(input model.Input) string {
	crdFacts := validCRDCount(input.CRDs)
	runtimeFacts := crdFacts + len(input.Deployments) + len(input.Services) +
		len(input.HTTPEndpoints) + len(input.GRPCServices) + len(input.Webhooks) +
		len(input.IngressRouting) + len(input.RBAC.ClusterRoles) + len(input.RBAC.Roles) +
		len(input.ExternalConnections) + len(input.Authentication) + len(input.IntegrationPoints)
	runtimeSurfaces := 0
	for _, count := range []int{
		crdFacts,
		len(input.Deployments),
		len(input.Services),
		len(input.HTTPEndpoints),
		len(input.GRPCServices),
		len(input.Webhooks),
		len(input.IngressRouting),
		len(input.RBAC.ClusterRoles) + len(input.RBAC.Roles),
		len(input.ExternalConnections),
		len(input.Authentication),
		len(input.IntegrationPoints),
	} {
		if count > 0 {
			runtimeSurfaces++
		}
	}
	dependencyFacts := len(input.Dependencies.GoModules) + len(input.Dependencies.Packages) + len(input.Dependencies.Internal)
	sourceFacts := len(input.SourceComponents)
	detail := fmt.Sprintf("%d runtime facts, %d source components, and %d dependencies", runtimeFacts, sourceFacts, dependencyFacts)
	switch {
	case (runtimeFacts >= 3 && runtimeSurfaces >= 2) || (runtimeFacts > 0 && sourceFacts > 0 && dependencyFacts >= 5):
		return "sufficient: " + detail + "; broad repository discovery is not required"
	case runtimeFacts+sourceFacts+dependencyFacts > 0:
		return "partial: " + detail + "; use bounded language-specific gap discovery"
	default:
		return "insufficient: no high-value source or deployment facts; use legacy repository discovery"
	}
}

func recentChanges(root string, limit int) []model.RecentChange {
	if limit <= 0 {
		return nil
	}
	output := gitValue(root, "log", fmt.Sprintf("-%d", limit), "--format=%h%x09%cs%x09%s")
	var result []model.RecentChange
	for _, line := range strings.Split(output, "\n") {
		parts := strings.SplitN(line, "\t", 3)
		if len(parts) != 3 {
			continue
		}
		result = append(result, model.RecentChange{Version: parts[0], Date: parts[1], Changes: parts[2]})
	}
	return result
}

func mergeServiceSecurity(input *model.Input, facts []model.Service) {
	for _, fact := range facts {
		for _, factPort := range fact.Ports {
			serviceIndex, portIndex, found := matchingServicePort(input.Services, fact.Name, factPort.Port)
			if !found {
				continue
			}
			port := &input.Services[serviceIndex].Ports[portIndex]
			port.AppProtocol = factPort.AppProtocol
			port.Encryption = factPort.Encryption
			port.Auth = factPort.Auth
		}
	}
}

func matchingServicePort(services []model.Service, name string, port any) (int, int, bool) {
	foundService, foundPort := -1, -1
	for serviceIndex, service := range services {
		if name != "" && service.Name != name {
			continue
		}
		for portIndex, candidate := range service.Ports {
			if fmt.Sprint(candidate.Port) != fmt.Sprint(port) {
				continue
			}
			if foundService >= 0 {
				return 0, 0, false
			}
			foundService, foundPort = serviceIndex, portIndex
		}
	}
	if foundService < 0 && name != "" {
		return matchingServicePort(services, "", port)
	}
	return foundService, foundPort, foundService >= 0
}

func secureProxyService(input *model.Input) {
	proxyDeployments := map[string]bool{}
	for _, deployment := range input.Deployments {
		for _, container := range deployment.Containers {
			if container.Name == "kube-rbac-proxy" || container.Name == "odh-kube-auth-proxy" {
				proxyDeployments[deployment.Name] = true
			}
		}
	}
	for serviceIndex := range input.Services {
		service := &input.Services[serviceIndex]
		if !proxyDeployments[service.TargetDeployment] {
			continue
		}
		for portIndex := range service.Ports {
			port := &service.Ports[portIndex]
			if port.Name != "dashboard-ui" {
				continue
			}
			port.AppProtocol = "https"
			port.Encryption = "TLS (kube-rbac-proxy)"
			port.Auth = "OpenShift project list"
		}
	}
}

func semanticGoDependencies(facts gosource.Result) []model.LanguagePackage {
	var result []model.LanguagePackage
	if facts.Dependencies.GoVersion != "" {
		version := strings.TrimSuffix(facts.Dependencies.GoVersion, ".0")
		result = append(result, model.LanguagePackage{
			Name: "Go", Version: version, Ecosystem: "go", Purpose: "Go runtime and build toolchain",
			Source: facts.GoVersionSource,
		})
	}
	for _, dependency := range facts.Dependencies.GoModules {
		if dependency.Module != "sigs.k8s.io/controller-runtime" {
			continue
		}
		result = append(result, model.LanguagePackage{
			Name: "controller-runtime", Version: strings.TrimPrefix(dependency.Version, "v"),
			Ecosystem: "go", Purpose: "Operator framework", Source: dependency.Source,
		})
		break
	}
	return result
}

func sidecarComponents(deployments []model.Deployment) []model.SourceComponent {
	var result []model.SourceComponent
	for _, deployment := range deployments {
		for _, container := range deployment.Containers {
			if container.Name != "kube-rbac-proxy" && container.Name != "odh-kube-auth-proxy" {
				continue
			}
			result = append(result, model.SourceComponent{
				Name: "kube-rbac-proxy", Type: "Sidecar Container",
				Purpose: "TLS termination and Kubernetes authorization proxy", Source: deployment.Source,
			})
		}
	}
	return result
}

func componentName(repository, root, gitRoot string) string {
	if repository == "" || filepath.Clean(gitRoot) != filepath.Clean(root) {
		return filepath.Base(root)
	}
	name := strings.TrimSuffix(repository, ".git")
	name = strings.TrimSuffix(name, "/")
	if separator := strings.LastIndexAny(name, "/:"); separator >= 0 {
		name = name[separator+1:]
	}
	if name == "" {
		return filepath.Base(root)
	}
	return name
}

func sourceDefaults(defaults map[string]model.SourceDefault, used map[string]bool) []model.SourceDefault {
	keys := make([]string, 0, len(defaults))
	for key := range defaults {
		if used[key] {
			keys = append(keys, key)
		}
	}
	sort.Strings(keys)
	result := make([]model.SourceDefault, 0, len(keys))
	for _, key := range keys {
		result = append(result, defaults[key])
	}
	return result
}

func mergeConstructedSecrets(input *model.Input, secrets []model.Secret) {
	positions := make(map[string]int, len(input.Secrets))
	for index, secret := range input.Secrets {
		positions[secret.Name] = index
	}
	for _, secret := range secrets {
		index, exists := positions[secret.Name]
		if !exists {
			index, exists = matchingDynamicSecret(input.Secrets, secret.Name)
		}
		if exists {
			current := &input.Secrets[index]
			upgraded := false
			if current.Type == "" || current.Type == "referenced" {
				current.Type = secret.Type
				upgraded = true
			}
			if current.ProvisionedBy == "" || current.ProvisionedBy == "controller template" {
				current.ProvisionedBy = secret.ProvisionedBy
				upgraded = true
			}
			if current.Source == "" || upgraded {
				current.Source = secret.Source
			}
			continue
		}
		positions[secret.Name] = len(input.Secrets)
		input.Secrets = append(input.Secrets, secret)
	}
}

func matchingDynamicSecret(secrets []model.Secret, name string) (int, bool) {
	suffix, dynamic := dynamicNameSuffix(name)
	if !dynamic {
		return 0, false
	}
	match := -1
	for index, candidate := range secrets {
		candidateSuffix, candidateDynamic := dynamicNameSuffix(candidate.Name)
		if !candidateDynamic || candidateSuffix != suffix {
			continue
		}
		if match >= 0 {
			return 0, false
		}
		match = index
	}
	return match, match >= 0
}

func dynamicNameSuffix(name string) (string, bool) {
	if !strings.HasPrefix(name, "{") {
		return "", false
	}
	end := strings.Index(name, "}")
	if end < 0 {
		return "", false
	}
	return name[end+1:], true
}

func mergeTemplateFacts(input *model.Input, facts model.Input) {
	input.CRDs = append(input.CRDs, facts.CRDs...)
	input.Services = append(input.Services, facts.Services...)
	input.Deployments = append(input.Deployments, facts.Deployments...)
	input.RBAC.ClusterRoles = append(input.RBAC.ClusterRoles, facts.RBAC.ClusterRoles...)
	input.RBAC.Roles = append(input.RBAC.Roles, facts.RBAC.Roles...)
	input.RBAC.ClusterRoleBindings = append(input.RBAC.ClusterRoleBindings, facts.RBAC.ClusterRoleBindings...)
	input.RBAC.RoleBindings = append(input.RBAC.RoleBindings, facts.RBAC.RoleBindings...)
	input.Secrets = append(input.Secrets, facts.Secrets...)
	input.IngressRouting = append(input.IngressRouting, facts.IngressRouting...)
	input.Webhooks = append(input.Webhooks, facts.Webhooks...)
	input.AccessPolicies = append(input.AccessPolicies, facts.AccessPolicies...)
}

func dedupeObjects(objects []object) []object {
	byKey := make(map[string]object, len(objects))
	var order []string
	for _, item := range objects {
		key := objectKey(item.data)
		if _, exists := byKey[key]; !exists {
			order = append(order, key)
		}
		byKey[key] = item
	}
	result := make([]object, 0, len(order))
	for _, key := range order {
		result = append(result, byKey[key])
	}
	return result
}

func gitValue(root string, args ...string) string {
	commandArgs := append([]string{"-C", root}, args...)
	output, err := exec.Command("git", commandArgs...).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(output))
}

func collect(objects []object, input *model.Input) {
	secretRefs := map[string]*model.Secret{}
	for _, item := range objects {
		switch stringValue(item.data, "kind") {
		case "CustomResourceDefinition":
			collectCRD(item, input)
		case "Deployment", "StatefulSet", "DaemonSet":
			collectWorkload(item, input, secretRefs)
		case "Service":
			collectService(item, objects, input, secretRefs)
		case "ClusterRole":
			input.RBAC.ClusterRoles = append(input.RBAC.ClusterRoles, collectRole(item))
		case "Role":
			input.RBAC.Roles = append(input.RBAC.Roles, collectRole(item))
		case "ClusterRoleBinding":
			input.RBAC.ClusterRoleBindings = append(input.RBAC.ClusterRoleBindings, collectBinding(item))
		case "RoleBinding":
			input.RBAC.RoleBindings = append(input.RBAC.RoleBindings, collectBinding(item))
		case "ConfigMap":
			collectConfigMapAnnotations(item, input)
		case "Secret":
			collectDeclaredSecret(item, secretRefs)
		case "Ingress", "Route", "HTTPRoute", "Gateway":
			input.IngressRouting = append(input.IngressRouting, collectIngress(item))
		case "AuthPolicy":
			policy := collectAccessPolicy(item)
			if policy.TargetKind != "" && len(policy.Authentication) > 0 {
				input.AccessPolicies = append(input.AccessPolicies, policy)
			}
		case "MutatingWebhookConfiguration", "ValidatingWebhookConfiguration":
			collectWebhooks(item, input)
		}
	}
	for _, secret := range secretRefs {
		input.Secrets = append(input.Secrets, *secret)
	}
	sort.Slice(input.Secrets, func(i, j int) bool { return input.Secrets[i].Name < input.Secrets[j].Name })
}
