package platformfacts

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type Result struct {
	Components     []model.SourceComponent
	Internal       []model.InternalDependency
	Connections    []model.ExternalConnection
	Authentication []model.AuthenticationFact
	Integrations   []model.IntegrationFact
	Coverage       string
}

type resourceFact struct {
	InternalName        string
	InternalInteraction string
	IntegrationName     string
	IntegrationType     string
	Purpose             string
}

var resourceGroups = map[string]resourceFact{
	"datasciencecluster.opendatahub.io": {
		"DataScienceCluster CR", "CRD Watch", "DataScienceCluster CR", "CRD Watch", "Read enabled platform components",
	},
	"dscinitialization.opendatahub.io": {
		"DSCInitialization CR", "CRD Watch", "DSCInitialization CR", "CRD Watch", "Read platform initialization state",
	},
	"kubeflow.org": {
		"Kubeflow Notebooks (kubeflow.org)", "CRD CRUD", "Kubeflow Notebooks", "CRD CRUD", "Create and manage notebook workbenches",
	},
	"serving.kserve.io": {
		"KServe InferenceService", "CRD Watch", "KServe InferenceService", "CRD Watch", "Read model serving state",
	},
	"modelregistry.opendatahub.io": {
		"ModelRegistry (modelregistry.opendatahub.io)", "CRD CRUD", "ModelRegistry CR", "CRD CRUD", "Manage model registry instances",
	},
	"ogx.io": {
		"OGX Server (ogx.io)", "CRD Watch", "OGX Server CR", "CRD Watch", "Read OGX server state",
	},
	"trustyai.opendatahub.io": {
		"TrustyAI (trustyai.opendatahub.io)", "CRD Watch", "TrustyAI CRs", "CRD Watch", "Read TrustyAI service resources",
	},
	"feast.dev": {
		"Feast (feast.dev)", "CRD Watch", "Feast FeatureStore CR", "CRD Watch", "Read feature store instances",
	},
	"infrastructure.opendatahub.io": {
		"HardwareProfile CR", "CRD CRUD", "HardwareProfile CR", "CRD CRUD", "Manage hardware profile resources",
	},
	"mlflow.opendatahub.io": {
		"MLflow (mlflow.opendatahub.io)", "CRD Watch", "MLflow CR", "CRD Watch", "Read MLflow instances",
	},
	"monitoring.coreos.com": {
		"prometheus-operator", "CRD CRUD", "prometheus-operator", "CRD CRUD", "Manage Prometheus monitoring resources",
	},
	"cert-manager.io": {
		"cert-manager", "CRD CRUD", "cert-manager", "Certificate CR", "Manage TLS certificates through cert-manager CRDs",
	},
	"gateway.networking.k8s.io": {
		"Gateway API", "CRD CRUD", "Gateway API", "HTTPRoute CRUD", "Manage Gateway API routing resources",
	},
}

var resourceKinds = map[string]resourceFact{
	"dashboard.opendatahub.io/acceleratorprofiles": {
		"", "", "AcceleratorProfile CR", "CRD CRUD", "Manage hardware accelerator profiles",
	},
	"nim.opendatahub.io/accounts": {
		"", "", "NIM Account CR", "CRD CRUD", "Manage NVIDIA NIM account configuration",
	},
	"serving.kserve.io/servingruntimes": {
		"", "", "ServingRuntime CR", "CRD CRUD", "Manage serving runtime templates",
	},
}

var additionalInternalDependencyAliases = []string{
	"components.platform.opendatahub.io",
	"config.openshift.io",
	"gatewayconfig",
	"github.com/opendatahub-io/odh-platform-utilities",
	"jobset.x-k8s.io",
	"operator.openshift.io",
	"route.openshift.io",
	"scheduling.volcano.sh",
	"scheduling.x-k8s.io",
	"services.platform.opendatahub.io",
	"volcano",
	"yunikorn",
}

// InternalDependencyDiscoveryAliases returns the dependency-bearing vocabulary
// shared by semantic extraction and the bounded absence contract.
func InternalDependencyDiscoveryAliases() []string {
	aliases := append([]string{}, additionalInternalDependencyAliases...)
	for group, fact := range resourceGroups {
		if fact.InternalName != "" {
			aliases = append(aliases, group)
		}
	}
	sort.Strings(aliases)
	result := aliases[:0]
	for _, alias := range aliases {
		if len(result) == 0 || result[len(result)-1] != alias {
			result = append(result, alias)
		}
	}
	return append([]string{}, result...)
}

func Extract(root string, input model.Input) Result {
	result := Result{
		Coverage: "partial: ODH/RHOAI semantic aliases from manifest API groups, direct modules, proxy route trees, federation configuration, and literal security middleware",
	}
	groups := roleGroupSources(input.RBAC)
	groupNames := make([]string, 0, len(groups))
	for group := range groups {
		groupNames = append(groupNames, group)
	}
	sort.Strings(groupNames)
	for _, group := range groupNames {
		fact, exists := resourceGroups[group]
		if !exists {
			continue
		}
		source := groups[group]
		result.Internal = append(result.Internal, model.InternalDependency{
			Component: fact.InternalName, Interaction: fact.InternalInteraction, Purpose: fact.Purpose, Source: source,
		})
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: fact.IntegrationName, InteractionType: fact.IntegrationType,
			Protocol: "HTTPS", Encryption: "TLS 1.2+", Purpose: fact.Purpose, Source: source,
		})
	}
	coreDeps, coreIntegrations := coreResourceFacts(input.RBAC)
	result.Internal = append(result.Internal, coreDeps...)
	result.Integrations = append(result.Integrations, coreIntegrations...)
	result.Internal = append(result.Internal, inputWatchInternalDependencies(input.ControllerWatches, input.CRDs)...)
	result.Internal = append(result.Internal, componentRefInternalDependencies(input.ComponentRefs)...)
	result.Internal = append(result.Internal, projectionInternalDependencies(input.FieldProjections)...)
	result.Internal = append(result.Internal, managedComponentInternalDependencies(input.ManagedComponents, input.RuntimeManagedUses, input.RBAC)...)
	result.Internal = append(result.Internal, runtimeClientInternalDependencies(input.RuntimeClients)...)
	result.Integrations = append(result.Integrations, runtimeClientIntegrationFacts(input.RuntimeClients)...)
	result.Internal = append(result.Internal, runtimeModuleInternalDependencies(input.RuntimeModuleUses)...)
	result.Internal = append(result.Internal, grpcServiceInternalDependencies(input.GRPCServices)...)
	for identity, source := range roleResourceSources(input.RBAC) {
		fact, exists := resourceKinds[identity]
		if !exists {
			continue
		}
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: fact.IntegrationName, InteractionType: fact.IntegrationType,
			Port: 6443, Protocol: "HTTPS", Encryption: "TLS 1.2+",
			Purpose: fact.Purpose, Source: source,
		})
	}

	for _, dependency := range input.Dependencies.GoModules {
		if dependency.Module == "github.com/opendatahub-io/odh-platform-utilities" {
			result.Internal = append(result.Internal, model.InternalDependency{
				Component: "odh-platform-utilities", Interaction: "Go Library",
				Purpose: "Platform detection, manifest rendering, and deployment helpers", Source: dependency.Source,
			})
		}
	}
	for _, component := range input.SourceComponents {
		if component.Name != "kube-rbac-proxy" {
			continue
		}
		result.Internal = append(result.Internal, model.InternalDependency{
			Component: "kube-rbac-proxy (odh-kube-auth-proxy)", Interaction: "Sidecar Container",
			Purpose: "TLS termination and authentication enforcement", Source: component.Source,
		})
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: "kube-rbac-proxy", InteractionType: "Sidecar (localhost)", Port: "8443 to 8080",
			Protocol: "HTTPS to HTTP", Encryption: "TLS termination",
			Purpose: "Authentication enforcement", Source: component.Source,
		})
	}
	addDashboardRelationships(root, &result)
	for _, ingress := range input.IngressRouting {
		if ingress.Kind != "HTTPRoute" {
			continue
		}
		result.Internal = append(result.Internal, model.InternalDependency{
			Component: "Gateway API (data-science-gateway)", Interaction: "HTTPRoute",
			Purpose: "Platform ingress through Gateway API", Source: ingress.Source,
		})
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: "Gateway API (data-science-gateway)", InteractionType: "HTTPRoute", Port: 8443,
			Protocol: "HTTPS", Encryption: "TLS", Purpose: "External dashboard ingress", Source: ingress.Source,
		})
		break
	}

	result.Integrations = append(result.Integrations, externalConnectionIntegrationFacts(input.ExternalConnections)...)
	result.Connections = append(result.Connections, sourceConnections(root, input)...)
	result.Components = append(result.Components, endpointPickerRuntimeComponents(input)...)
	result.Components = append(result.Components, runtimeServerComponents(input.RuntimeServers)...)
	result.Authentication = append(result.Authentication, authenticationFacts(root, input)...)
	result.Integrations = append(result.Integrations, openshiftIntegrations(groups)...)
	return result
}

func runtimeServerComponents(servers []model.RuntimeServer) []model.SourceComponent {
	var result []model.SourceComponent
	seen := map[string]bool{}
	for _, server := range servers {
		component := model.SourceComponent{}
		switch {
		case strings.EqualFold(server.Surface, "health") && strings.EqualFold(server.Protocol, "gRPC"):
			component = model.SourceComponent{
				Name: "Health Server", Type: "gRPC Service",
				Purpose: "Runtime gRPC health service used for readiness and liveness checks",
				Source:  server.Source,
			}
		case strings.EqualFold(server.Surface, "metrics") && strings.EqualFold(server.Protocol, "HTTP"):
			component = model.SourceComponent{
				Name: "Metrics Server", Type: "HTTP Service",
				Purpose: "Standalone Prometheus metrics service backed by a runtime HTTP listener",
				Source:  server.Source,
			}
		}
		if component.Name != "" && component.Source != "" && server.Lifecycle != "" && !seen[component.Name] {
			seen[component.Name] = true
			result = append(result, component)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Name < result[j].Name })
	return result
}

func grpcServiceInternalDependencies(services []model.GRPCService) []model.InternalDependency {
	for _, service := range services {
		if service.Service != "ExternalProcessor" || service.Source == "" {
			continue
		}
		return []model.InternalDependency{{
			Component: "Envoy proxy", Interaction: "gRPC ExtProc callout",
			Purpose: "Receive per-request processing callouts through the Envoy External Processing API",
			Source:  service.Source,
		}}
	}
	return nil
}

func runtimeModuleInternalDependencies(uses []model.RuntimeModuleUse) []model.InternalDependency {
	var result []model.InternalDependency
	seen := map[string]bool{}
	for _, use := range uses {
		component := projectModuleComponent(use.Module)
		if component == "." || component == "" || use.Source == "" || seen[component] {
			continue
		}
		seen[component] = true
		result = append(result, model.InternalDependency{
			Component: component, Interaction: "Go library",
			Purpose: "Use runtime packages from " + use.Module, Source: use.Source,
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Component < result[j].Component })
	return result
}

func projectModuleComponent(module string) string {
	for _, prefix := range []string{
		"github.com/llm-d/",
		"github.com/opendatahub-io/",
		"github.com/red-hat-data-services/",
	} {
		if !strings.HasPrefix(module, prefix) {
			continue
		}
		remainder := strings.TrimPrefix(module, prefix)
		if component, _, _ := strings.Cut(remainder, "/"); component != "" {
			return component
		}
	}
	for _, exact := range []string{
		"sigs.k8s.io/gateway-api-inference-extension",
	} {
		if module == exact || strings.HasPrefix(module, exact+"/") {
			parts := strings.Split(exact, "/")
			return parts[len(parts)-1]
		}
	}
	return ""
}

func endpointPickerRuntimeComponents(input model.Input) []model.SourceComponent {
	hasConfigAPI := false
	configSource := ""
	for _, crd := range input.CRDs {
		if crd.Kind == "EndpointPickerConfig" {
			hasConfigAPI = true
			configSource = crd.Source
			break
		}
	}
	if !hasConfigAPI {
		return nil
	}
	for _, service := range input.GRPCServices {
		if service.Service != "ExternalProcessor" {
			continue
		}
		purpose := "Envoy external processing service with EndpointPickerConfig-driven scheduling, flow control, data-layer, and parsing plugins"
		source := configSource
		for _, contract := range input.APIReferenceContracts {
			if contract.OwnerKind != "InferencePool" || !strings.HasSuffix(contract.Field, "EndpointPickerRef") {
				continue
			}
			failureModes := strings.Join(contract.FailureModes, "/")
			if failureModes == "" {
				failureModes = contract.FailureModeDefault
			}
			purpose += fmt.Sprintf("; referenced by %s as a %s through %s with %s failure behavior (default %s)",
				contract.OwnerKind, contract.DefaultKind, contract.Field, failureModes, contract.FailureModeDefault)
			if contract.Source != "" {
				source = contract.Source
			}
			break
		}
		return []model.SourceComponent{{
			Name: "Endpoint Picker (EPP)", Type: "Go gRPC Service",
			Purpose: purpose,
			Source:  source,
		}}
	}
	return nil
}

func projectionInternalDependencies(projections []model.FieldProjection) []model.InternalDependency {
	type projectionGroup struct {
		kind    string
		fields  []string
		sources []string
	}
	groups := map[string]*projectionGroup{}
	var result []model.InternalDependency
	seen := map[string]bool{}
	for _, projection := range projections {
		projector := strings.ToLower(strings.TrimSpace(projection.Projector))
		if projector != "orchestrator" && projector != "platform orchestrator" {
			continue
		}
		key := projection.APIGroup + "\x00" + projection.Kind
		group := groups[key]
		if group == nil {
			group = &projectionGroup{kind: projection.Kind}
			groups[key] = group
		}
		group.fields = appendUniqueString(group.fields, strings.TrimPrefix(projection.Field, "spec."))
		group.sources = appendUniqueString(group.sources, projection.Source)

		component, purpose := projectionUpstreamDependency(projection)
		if component == "" || seen[component+"\x00"+key] {
			continue
		}
		seen[component+"\x00"+key] = true
		result = append(result, model.InternalDependency{
			Component: component, Interaction: "Indirect (via orchestrator)",
			Purpose: purpose, Source: projection.Source,
		})
	}
	keys := make([]string, 0, len(groups))
	for key := range groups {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	for _, key := range keys {
		group := groups[key]
		sort.Strings(group.fields)
		result = append(result, model.InternalDependency{
			Component: "Platform orchestrator", Interaction: "CR field projection",
			Purpose: fmt.Sprintf("Projects %s into %s CR spec", strings.Join(group.fields, ", "), group.kind),
			Source:  strings.Join(group.sources, "; "),
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Component < result[j].Component })
	return result
}

func managedComponentInternalDependencies(
	contracts []model.ManagedComponentContract,
	runtimeUses []model.RuntimeManagedComponent,
	rbac model.RBAC,
) []model.InternalDependency {
	var result []model.InternalDependency
	seen := map[string]bool{}
	for _, contract := range contracts {
		var runtimeUse model.RuntimeManagedComponent
		for _, candidate := range runtimeUses {
			if strings.EqualFold(candidate.Field, contract.Field) &&
				candidate.Lifecycle == "Manifest reconciliation" {
				runtimeUse = candidate
				break
			}
		}
		if runtimeUse.Source == "" {
			continue
		}
		group, resource, roleSource := managedComponentLifecycleRBAC(contract, rbac)
		if group == "" {
			continue
		}
		component := managedComponentIdentity(group, contract.Component)
		key := strings.ToLower(component)
		if component == "" || seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, model.InternalDependency{
			Component: component, Interaction: "CRD-managed sub-component",
			Purpose: fmt.Sprintf(
				"%s selects the %s state to reconcile manifests with full lifecycle RBAC for %s/%s (schema: %s; RBAC: %s)",
				contract.Field, contract.ManagedState, group, resource, contract.Source, roleSource,
			),
			Source: runtimeUse.Source,
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Component < result[j].Component })
	return result
}

func managedComponentLifecycleRBAC(contract model.ManagedComponentContract, rbac model.RBAC) (string, string, string) {
	segments := strings.Split(contract.Field, ".")
	if len(segments) < 2 {
		return "", "", ""
	}
	fieldToken := normalizedResourceToken(segments[len(segments)-2])
	required := []string{"create", "delete", "get", "list", "patch", "update", "watch"}
	for _, roles := range [][]model.Role{rbac.ClusterRoles, rbac.Roles} {
		for _, role := range roles {
			for _, rule := range role.Rules {
				if !containsAllFold(rule.Verbs, required) {
					continue
				}
				for _, group := range rule.APIGroups {
					if group == "" || strings.EqualFold(group, contract.APIGroup) {
						continue
					}
					for _, resource := range rule.Resources {
						if strings.Contains(normalizedResourceToken(resource), fieldToken) {
							return group, resource, role.Source
						}
					}
				}
			}
		}
	}
	return "", "", ""
}

func containsAllFold(values, required []string) bool {
	found := map[string]bool{}
	for _, value := range values {
		found[strings.ToLower(value)] = true
	}
	for _, value := range required {
		if !found[value] {
			return false
		}
	}
	return true
}

func normalizedResourceToken(value string) string {
	var result strings.Builder
	for _, character := range strings.ToLower(value) {
		if character >= 'a' && character <= 'z' || character >= '0' && character <= '9' {
			result.WriteRune(character)
		}
	}
	return result.String()
}

func managedComponentIdentity(apiGroup, schemaComponent string) string {
	base := strings.TrimSpace(strings.ToLower(schemaComponent))
	base = strings.TrimSpace(strings.TrimSuffix(base, " operator"))
	base = strings.ReplaceAll(base, "-", " ")
	base = strings.Join(strings.Fields(base), " ")
	for _, segment := range strings.Split(strings.ToLower(apiGroup), ".") {
		if !strings.Contains(segment, "-") || strings.Contains(base, segment) {
			continue
		}
		return strings.TrimSpace(segment + " " + base)
	}
	return base
}

func projectionUpstreamDependency(projection model.FieldProjection) (string, string) {
	upstream := strings.ToLower(strings.TrimSpace(projection.UpstreamSource))
	field := strings.TrimPrefix(projection.Field, "spec.")
	switch {
	case strings.Contains(upstream, "gatewayconfig"):
		return "GatewayConfig", fmt.Sprintf("Source of %s projected into %s CR spec", field, projection.Kind)
	case strings.Contains(upstream, "mlflowoperator"):
		return "DSC MLflowOperator", fmt.Sprintf("Source of %s state projected into %s CR spec", field, projection.Kind)
	default:
		return "", ""
	}
}

func componentRefInternalDependencies(references []model.ComponentRef) []model.InternalDependency {
	var result []model.InternalDependency
	seen := map[string]bool{}
	for _, reference := range references {
		component := strings.ToLower(reference.Component)
		dependency := model.InternalDependency{}
		switch {
		case component == "config.openshift.io/v1/apiserver" && componentRefReadsResource(reference):
			dependency = model.InternalDependency{
				Component: "OpenShift Cluster Configuration", Interaction: "APIServer resource read",
				Purpose: "Read cluster-wide API server configuration", Source: reference.Source,
			}
		case strings.Contains(component, "cert-manager.io/") &&
			(strings.HasSuffix(component, "/certificate") || strings.HasSuffix(component, "/issuer")) &&
			reference.Interaction == "Resource CRUD" && componentRefMutatesResource(reference):
			dependency = model.InternalDependency{
				Component: "cert-manager", Interaction: "Certificate and Issuer CRD CRUD",
				Purpose: "Reconcile cert-manager Certificate and Issuer resources", Source: reference.Source,
			}
		case strings.Contains(component, "gateway.networking.k8s.io/") && strings.HasSuffix(component, "/httproute") &&
			reference.Interaction == "Resource CRUD" && componentRefMutatesResource(reference):
			dependency = model.InternalDependency{
				Component: "Gateway API", Interaction: "HTTPRoute CRUD",
				Purpose: "Reconcile HTTPRoute resources against a configured Gateway", Source: reference.Source,
			}
		}
		if dependency.Component == "" {
			dependency = componentRefResourceGroupFallback(reference)
		}
		key := dependency.Component + "\x00" + dependency.Interaction
		if dependency.Component != "" && !seen[key] {
			seen[key] = true
			result = append(result, dependency)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Component < result[j].Component })
	return result
}

var componentRefSpecificGroups = map[string]bool{
	"config.openshift.io":        true,
	"cert-manager.io":            true,
	"gateway.networking.k8s.io":  true,
}

func componentRefResourceGroupFallback(reference model.ComponentRef) model.InternalDependency {
	component := strings.ToLower(reference.Component)
	parts := strings.SplitN(component, "/", 2)
	if len(parts) < 2 {
		return model.InternalDependency{}
	}
	group := parts[0]
	if componentRefSpecificGroups[group] {
		return model.InternalDependency{}
	}
	fact, exists := resourceGroups[group]
	if !exists || fact.InternalName == "" {
		return model.InternalDependency{}
	}
	return model.InternalDependency{
		Component: fact.InternalName, Interaction: fact.InternalInteraction,
		Purpose: fact.Purpose, Source: reference.Source,
	}
}

func componentRefReadsResource(reference model.ComponentRef) bool {
	operations, _, _ := strings.Cut(strings.ToLower(reference.Reference), " operations")
	for _, operation := range strings.Split(operations, ", ") {
		if operation == "get" || operation == "list" {
			return true
		}
	}
	return false
}

func componentRefMutatesResource(reference model.ComponentRef) bool {
	operations, _, _ := strings.Cut(strings.ToLower(reference.Reference), " operations")
	for _, operation := range strings.Split(operations, ", ") {
		switch operation {
		case "create", "delete", "patch", "update":
			return true
		}
	}
	return false
}

func watchInternalDependencies(watches []model.ControllerWatch) []model.InternalDependency {
	return watchInternalDependenciesWithOwnedGroups(watches, nil)
}

func inputWatchInternalDependencies(watches []model.ControllerWatch, crds []model.CRD) []model.InternalDependency {
	ownedGroups := map[string]bool{}
	for _, crd := range crds {
		if crd.Group != "" {
			ownedGroups[strings.ToLower(crd.Group)] = true
		}
	}
	return watchInternalDependenciesWithOwnedGroups(watches, ownedGroups)
}

func watchInternalDependenciesWithOwnedGroups(watches []model.ControllerWatch, ownedGroups map[string]bool) []model.InternalDependency {
	var result []model.InternalDependency
	seen := map[string]bool{}
	for _, watch := range watches {
		controller := strings.ToLower(strings.TrimSpace(watch.Controller))
		gvk := strings.ToLower(strings.TrimSpace(watch.GVK))
		group, _, _ := strings.Cut(gvk, "/")
		if ownedGroups[group] {
			continue
		}
		dependency := model.InternalDependency{}
		switch {
		case controller == "jobset" && strings.HasSuffix(gvk, "/jobset"):
			dependency = model.InternalDependency{
				Component: "JobSet", Interaction: "CRD Watch",
				Purpose: "Create and reconcile replicated distributed training jobs",
				Source:  watch.Source,
			}
		case controller == "volcano" && strings.HasSuffix(gvk, "/podgroup"):
			dependency = model.InternalDependency{
				Component: "Volcano Scheduler", Interaction: "PodGroup CRD Watch",
				Purpose: "Coordinate gang scheduling through Volcano PodGroups",
				Source:  watch.Source,
			}
		case controller == "coscheduling" && strings.HasSuffix(gvk, "/podgroup"):
			dependency = model.InternalDependency{
				Component: "Kubernetes Scheduler Plugins (CoScheduling)", Interaction: "PodGroup CRD Watch",
				Purpose: "Coordinate gang scheduling through scheduler-plugins PodGroups",
				Source:  watch.Source,
			}
		case controller == "scaledobjectreconciler" && gvk == "keda.sh/v1alpha1/scaledobject":
			dependency = model.InternalDependency{
				Component: "KEDA", Interaction: conditionalWatchInteraction(watch),
				Purpose: "Optional ScaledObject discovery for autoscaling targets", Source: watch.Source,
			}
		case controller == "variantautoscalingreconciler" && gvk == "leaderworkerset.x-k8s.io/v1/leaderworkerset":
			dependency = model.InternalDependency{
				Component: "LeaderWorkerSet (lws)", Interaction: conditionalWatchInteraction(watch),
				Purpose: "Optional scaling support for LeaderWorkerSet workloads", Source: watch.Source,
			}
		case controller == "inferencepoolreconciler" &&
			(gvk == "inference.networking.k8s.io/v1/inferencepool" ||
				gvk == "inference.networking.x-k8s.io/v1alpha2/inferencepool"):
			dependency = model.InternalDependency{
				Component: "gateway-api-inference-extension", Interaction: conditionalWatchInteraction(watch),
				Purpose: "Watch InferencePool resources for pool-based autoscaling configuration", Source: watch.Source,
			}
		case controller == "variantautoscalingreconciler" && gvk == "monitoring.coreos.com/v1/servicemonitor":
			dependency = model.InternalDependency{
				Component: "prometheus-operator", Interaction: conditionalWatchInteraction(watch),
				Purpose: "Watch ServiceMonitor resources that configure managed workload monitoring", Source: watch.Source,
			}
		}
		if dependency.Component == "" {
			if fact, exists := resourceGroups[group]; exists && fact.InternalName != "" {
				dependency = model.InternalDependency{
					Component: fact.InternalName, Interaction: conditionalWatchInteraction(watch),
					Purpose: fact.Purpose, Source: watch.Source,
				}
			}
		}
		if dependency.Component == "" {
			continue
		}
		key := dependency.Component + "\x00" + dependency.Interaction
		if !seen[key] {
			seen[key] = true
			result = append(result, dependency)
		}
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].Component < result[j].Component
	})
	return result
}

func conditionalWatchInteraction(watch model.ControllerWatch) string {
	if watch.Conditional {
		return "Controller watch (conditional)"
	}
	return "Controller watch"
}

func runtimeClientInternalDependencies(clients []model.RuntimeClient) []model.InternalDependency {
	var result []model.InternalDependency
	seen := map[string]bool{}
	for _, client := range clients {
		dependency := model.InternalDependency{}
		switch {
		case client.Target == "Prometheus" && client.Client == "Prometheus HTTP API client":
			dependency = model.InternalDependency{
				Component: "Prometheus", Interaction: "Metrics source",
				Purpose: "Required Prometheus API client used for runtime metrics queries", Source: client.Source,
			}
		case client.Target == "Model-serving endpoints" && client.Client == "HTTP metrics data source" && client.Source != "":
			dependency = model.InternalDependency{
				Component: "Model-serving endpoints", Interaction: "HTTP metrics scrape",
				Purpose: "Scrape configured metrics from discovered model-serving endpoints", Source: client.Source,
			}
		case client.Target == "llm-d inference gateway" && client.Client == "HTTP client" && client.Source != "":
			dependency = model.InternalDependency{
				Component: "llm-d inference gateway", Interaction: "HTTP client",
				Purpose: "Runtime inference requests to configured llm-d gateway endpoints", Source: client.Source,
			}
		case client.Target == "Operator Lifecycle Manager (OLM)" && client.Client == "OLM API and typed client" && client.Source != "":
			dependency = model.InternalDependency{
				Component: "Operator Lifecycle Manager (OLM)", Interaction: "Go module import (API + client)",
				Purpose: "CSV and subscription inspection for operator lifecycle operations", Source: client.Source,
			}
		}
		key := dependency.Component + "\x00" + dependency.Interaction
		if dependency.Component != "" && !seen[key] {
			seen[key] = true
			result = append(result, dependency)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Component < result[j].Component })
	return result
}

func runtimeClientIntegrationFacts(clients []model.RuntimeClient) []model.IntegrationFact {
	var result []model.IntegrationFact
	seen := map[string]bool{}
	for _, client := range clients {
		fact := model.IntegrationFact{}
		switch {
		case client.Target == "PostgreSQL" && client.Client == "pgx connection pool":
			fact = model.IntegrationFact{Component: "PostgreSQL", InteractionType: "Database client", Port: "Configured by runtime", Protocol: "TCP", Encryption: "Configured by runtime", Purpose: "Runtime relational data store", Source: client.Source}
		case client.Target == "Redis/Valkey" && client.Client == "go-redis client":
			fact = model.IntegrationFact{Component: "Redis/Valkey", InteractionType: "Exchange client", Port: "Configured by runtime", Protocol: "TCP", Encryption: "Configured by runtime", Purpose: "Runtime queue and key-value data store", Source: client.Source}
		case client.Target == "S3-compatible storage" && client.Client == "AWS SDK S3 client":
			fact = model.IntegrationFact{Component: "S3-compatible storage", InteractionType: "File storage client", Port: "Configured by runtime", Protocol: "HTTP/HTTPS", Encryption: "Configured by runtime", Purpose: "Runtime object storage", Source: client.Source}
		case client.Target == "OpenTelemetry Collector" && client.Client == "OTLP/gRPC trace exporter":
			fact = model.IntegrationFact{Component: "OpenTelemetry Collector", InteractionType: "gRPC client", Port: "Configured by runtime", Protocol: "OTLP/gRPC", Encryption: "Configured by runtime", Purpose: "Runtime trace export", Source: client.Source}
		case client.Target == "llm-d inference gateway" && client.Client == "HTTP client":
			fact = model.IntegrationFact{Component: "llm-d inference gateway", InteractionType: "HTTP client", Port: "Configured by runtime", Protocol: "HTTP/HTTPS", Encryption: "Configured by runtime", Purpose: "Runtime inference requests", Source: client.Source}
		case client.Client == "outbound gRPC client":
			fact = model.IntegrationFact{Component: client.Target, InteractionType: "gRPC client, outbound", Port: "Configured by runtime", Protocol: "gRPC", Encryption: "Configured by runtime", Purpose: "Runtime outbound gRPC client to " + client.Target, Source: client.Source}
		case client.Client == "GCS storage client":
			fact = model.IntegrationFact{Component: "Google Cloud Storage", InteractionType: "File storage client", Port: "Configured by runtime", Protocol: "HTTP/HTTPS", Encryption: "Configured by runtime", Purpose: "Runtime object storage", Source: client.Source}
		case client.Client == "Azure Blob Storage client":
			fact = model.IntegrationFact{Component: "Azure Blob Storage", InteractionType: "File storage client", Port: "Configured by runtime", Protocol: "HTTP/HTTPS", Encryption: "Configured by runtime", Purpose: "Runtime object storage", Source: client.Source}
		case client.Client == "IBM COS S3 client":
			fact = model.IntegrationFact{Component: "IBM Cloud Object Storage", InteractionType: "File storage client", Port: "Configured by runtime", Protocol: "HTTP/HTTPS", Encryption: "Configured by runtime", Purpose: "Runtime object storage", Source: client.Source}
		}
		key := fact.Component + "\x00" + fact.InteractionType
		if fact.Component != "" && !seen[key] {
			seen[key] = true
			result = append(result, fact)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Component < result[j].Component })
	return result
}

func externalConnectionIntegrationFacts(connections []model.ExternalConnection) []model.IntegrationFact {
	var result []model.IntegrationFact
	seen := map[string]bool{}
	for _, conn := range connections {
		if conn.Service == "" || !runtimeSurfaceSource(conn.Source) {
			continue
		}
		key := strings.ToLower(conn.Service) + "\x00" + strings.ToLower(conn.Type)
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, model.IntegrationFact{
			Component:       conn.Service,
			InteractionType: conn.Type,
			Port:            conn.Port,
			Protocol:        conn.Protocol,
			Encryption:      conn.Encryption,
			Purpose:         conn.Function,
			Source:           conn.Source,
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Component < result[j].Component })
	return result
}

func runtimeSurfaceSource(source string) bool {
	if strings.TrimSpace(source) == "" {
		return true
	}
	path := strings.ToLower(strings.SplitN(filepath.ToSlash(source), ":", 2)[0])
	parts := strings.Split(strings.Trim(path, "/"), "/")
	for _, part := range parts {
		switch part {
		case "conformance", "test", "tests", "testdata", "example", "examples", "sample", "samples":
			return false
		}
	}
	return !strings.HasSuffix(path, "_test.go")
}

func roleResourceSources(rbac model.RBAC) map[string]string {
	result := map[string]string{}
	roles := append(append([]model.Role{}, rbac.ClusterRoles...), rbac.Roles...)
	for _, role := range roles {
		for _, rule := range role.Rules {
			for _, group := range rule.APIGroups {
				for _, resource := range rule.Resources {
					identity := group + "/" + strings.TrimSuffix(resource, "/status")
					if result[identity] == "" {
						result[identity] = role.Source
					}
				}
			}
		}
	}
	return result
}

func addDashboardRelationships(root string, result *Result) {
	if source, ok := sourceContaining(root, "manifests/modular-architecture/federation-configmap.yaml", `"name": "perses"`); ok {
		result.Internal = append(result.Internal, model.InternalDependency{
			Component: "Perses", Interaction: "Proxy Service",
			Purpose: "Observability dashboards proxied through module federation", Source: source,
		})
	}
	if source, ok := sourceContaining(root, "dashboard-operator/charts/dashboard/values.yaml", "components.platform.opendatahub.io/managed-by: opendatahub-operator"); ok {
		result.Internal = append(result.Internal, model.InternalDependency{
			Component: "rhods-operator / opendatahub-operator", Interaction: "CRD Watch",
			Purpose: "Creates and owns the Dashboard custom resource", Source: source,
		})
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: "rhods-operator / opendatahub-operator", InteractionType: "CRD Watch (Dashboard CR)",
			Protocol: "HTTPS", Encryption: "TLS 1.2+",
			Purpose: "Operator creates Dashboard CR; dashboard-operator reconciles it", Source: source,
		})
	}
	if source, ok := sourceContaining(root, "dashboard-operator/config/webhook/manifests.yaml", "kind: Certificate"); ok {
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: "cert-manager", InteractionType: "Certificate CR",
			Protocol: "HTTPS", Encryption: "TLS 1.2+",
			Purpose: "Webhook and metrics TLS certificates", Source: source,
		})
	}
	if source, ok := sourceContaining(root, "manifests/modular-architecture/modules/gen-ai/deployment.yaml", "BFF_MAAS_SERVICE_NAME"); ok {
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: "MaaS BFF (inter-BFF)", InteractionType: "REST", Port: 8243,
			Protocol: "HTTPS", Encryption: "TLS 1.2+",
			Purpose: "Token management from gen-ai", Source: source,
		})
	}
	if source, ok := sourceContaining(root, "packages/gen-ai/bff/internal/constants/mcp.go", "TransportTypeStreamableHTTP"); ok {
		result.Integrations = append(result.Integrations, model.IntegrationFact{
			Component: "MCP Servers", InteractionType: "SSE/Streamable HTTP",
			Protocol: "SSE/streamable HTTP", Encryption: "varies",
			Purpose: "Tool discovery and invocation", Source: source,
		})
	}
}

func roleGroupSources(rbac model.RBAC) map[string]string {
	result := map[string]string{}
	roles := append(append([]model.Role{}, rbac.ClusterRoles...), rbac.Roles...)
	for _, role := range roles {
		for _, rule := range role.Rules {
			for _, group := range rule.APIGroups {
				if group != "" && result[group] == "" {
					result[group] = role.Source
				}
			}
		}
	}
	return result
}

var coreInfrastructureResources = map[string]string{
	"nodes":              "Kubernetes API (nodes)",
	"persistentvolumes":  "Kubernetes API (persistent volumes)",
	"storageclasses":     "Kubernetes API (storage classes)",
}

func coreResourceFacts(rbac model.RBAC) ([]model.InternalDependency, []model.IntegrationFact) {
	seen := map[string]bool{}
	var deps []model.InternalDependency
	var integrations []model.IntegrationFact
	emittedAPIClient := false
	for _, role := range rbac.ClusterRoles {
		for _, rule := range role.Rules {
			isCoreGroup := false
			for _, group := range rule.APIGroups {
				if group == "" {
					isCoreGroup = true
					break
				}
			}
			if !isCoreGroup {
				continue
			}
			for _, resource := range rule.Resources {
				component, isInfra := coreInfrastructureResources[resource]
				if !isInfra || seen[resource] {
					continue
				}
				seen[resource] = true
				verb := "list"
				for _, v := range rule.Verbs {
					if v == "create" || v == "update" || v == "delete" || v == "patch" {
						verb = "CRUD"
						break
					}
				}
				deps = append(deps, model.InternalDependency{
					Component: component, Interaction: verb,
					Purpose: resource + " resource access via RBAC", Source: role.Source,
				})
				if !emittedAPIClient {
					emittedAPIClient = true
					integrations = append(integrations, model.IntegrationFact{
						Component: "Kubernetes API", InteractionType: "API client",
						Port: 6443, Protocol: "HTTPS", Encryption: "TLS 1.2+",
						Purpose: "Cluster resource management via RBAC", Source: role.Source,
					})
				}
			}
		}
	}
	return deps, integrations
}

func sourceConnections(root string, input model.Input) []model.ExternalConnection {
	var result []model.ExternalConnection
	add := func(relative, needle, destination, interaction string, port any, protocol, encryption, auth, purpose string) {
		if !fileExists(filepath.Join(root, filepath.FromSlash(relative))) {
			return
		}
		result = append(result, model.ExternalConnection{
			Type: interaction, Service: destination, Target: destination, Port: port,
			Protocol: protocol, Encryption: encryption, Auth: auth, Function: purpose,
			Source: sourceLine(root, relative, needle),
		})
	}
	if hasKubernetesClient(input.Dependencies) {
		add("backend/src/plugins/kube.ts", "makeApiClient", "Kubernetes API", "REST + WebSocket", 6443, "HTTPS/WSS", "TLS 1.2+", "ServiceAccount + Impersonation", "Kubernetes resource operations")
		if len(result) == 0 {
			for _, dependency := range input.Dependencies.GoModules {
				if dependency.Module == "k8s.io/client-go" {
					result = append(result, model.ExternalConnection{
						Type: "REST + WebSocket", Service: "Kubernetes API", Target: "Kubernetes API", Port: 6443,
						Protocol: "HTTPS/WSS", Encryption: "TLS 1.2+", Auth: "ServiceAccount",
						Function: "Kubernetes resource operations", Source: dependency.Source,
					})
					break
				}
			}
		}
	}

	routes := []struct {
		Path, Destination, Interaction string
		Port                           any
		Protocol, Auth, Purpose        string
	}{
		{"backend/src/routes/api/service/pipelines/index.ts", "DataScience Pipelines API", "REST Proxy", 8443, "HTTPS", "Bearer Token", "Pipeline execution and management"},
		{"backend/src/routes/api/service/modelregistry/index.ts", "Model Registry API", "REST Proxy", 8443, "HTTPS", "Bearer Token", "Model version tracking"},
		{"backend/src/routes/api/service/model-serving/index.ts", "Model Serving (KServe)", "REST Proxy", "varies", "HTTPS", "Bearer Token", "Inference service management"},
		{"backend/src/routes/api/service/mlmd/index.ts", "ML Metadata (MLMD)", "gRPC-web Proxy", 8443, "gRPC-web", "Bearer Token", "Artifact and execution tracking"},
		{"backend/src/routes/api/service/trustyai/index.ts", "TrustyAI Service", "REST Proxy", 443, "HTTPS", "Bearer Token", "Fairness and explainability services"},
	}
	for _, route := range routes {
		add(route.Path, "fastify", route.Destination, route.Interaction, route.Port, route.Protocol, "TLS", route.Auth, route.Purpose)
	}
	add("packages/gen-ai/bff/cmd/main.go", "LLAMA_STACK_URL", "Llama Stack Server", "REST", "varies", "HTTPS", "TLS", "Bearer Token / API Key", "LLM inference, vector stores, and files")
	add("packages/maas/bff/cmd/main.go", "MAAS_API_URL", "MaaS API Server", "REST", "varies", "HTTPS", "TLS", "Bearer Token", "API keys, models, and subscriptions")
	add("packages/gen-ai/bff/cmd/main.go", "MLFLOW_URL", "MLflow Tracking Server", "REST", "varies", "HTTPS", "TLS", "Session", "Experiment and prompt management")
	add("packages/gen-ai/bff/cmd/main.go", "NEMO_GUARDRAILS_URL", "NeMo Guardrails", "REST", "varies", "HTTPS", "TLS", "API Key", "Content moderation")
	add("backend/src/utils/prometheusUtils.ts", "generatePrometheusHostURL", "Prometheus/Thanos", "REST", 9092, "HTTPS", "TLS", "Bearer Token", "Metrics queries")
	add("manifests/modular-architecture/federation-configmap.yaml", `"name": "perses"`, "Perses Service", "REST Proxy", 8080, "HTTP", "None", "user_token", "Observability dashboards")
	return result
}

func authenticationFacts(root string, input model.Input) []model.AuthenticationFact {
	result := rbacAuthenticationFacts(input.RBAC)
	result = append(result, kubernetesAPIAuthenticationFacts(input)...)
	result = append(result, secureControllerMetricsAuthenticationFacts(input)...)
	result = append(result, kubeRBACProxyAuthenticationFacts(input)...)
	result = append(result, runtimeWebhookAuthenticationFacts(input)...)
	result = append(result, accessPolicyAuthenticationFacts(input)...)
	result = append(result, workloadProbeAuthenticationFacts(input)...)
	result = append(result, unknownMetricsAuthenticationFacts(input)...)
	add := func(relative, needle, endpoint, methods, mechanism, enforcement, policy string) {
		if !fileExists(filepath.Join(root, filepath.FromSlash(relative))) {
			return
		}
		result = append(result, model.AuthenticationFact{
			Endpoint: endpoint, Methods: methods, Mechanism: mechanism,
			EnforcementPoint: enforcement, Policy: policy, Source: sourceLine(root, relative, needle),
		})
	}
	add("backend/src/utils/constants.ts", "x-forwarded-access-token", "/api/* (backend)", "ALL", "Bearer Token (x-forwarded-access-token)", "Node.js backend middleware", "Route-specific user or admin authorization")
	add("packages/gen-ai/bff/internal/api/middleware.go", "RequireAccessToService", "/gen-ai/api/v1/*", "ALL", "Bearer Token (x-forwarded-access-token)", "Go BFF middleware (RequireAccessToService)", "RBAC and namespace access")
	add("packages/maas/bff/internal/config/environment.go", "DefaultAuthTokenHeader", "/maas/api/v1/*", "ALL", "Bearer Token (x-forwarded-access-token or internal)", "Go BFF middleware", "Internal service account or user token")
	add("packages/agent-ops/bff/internal/api/middleware.go", "RequireAccessToAgent", "/agent-ops/api/v1/agents/*", "GET", "Bearer Token + SubjectAccessReview", "Go BFF middleware (RequireAccessToAgent)", "Per-agent RBAC via SSAR")
	add("backend/src/utils/proxy.ts", "Authorization", "/api/k8s/*", "ALL", "Bearer Token to K8s Impersonation", "Node.js proxy to K8s API", "User Kubernetes RBAC")
	for _, webhook := range input.Webhooks {
		if !strings.Contains(strings.ToLower(webhook.Type), "validat") {
			continue
		}
		source := ""
		if len(webhook.Sources) > 0 {
			source = webhook.Sources[0].File
			if webhook.Sources[0].Line > 0 {
				source += fmt.Sprintf(":%d", webhook.Sources[0].Line)
			}
		}
		result = append(result, model.AuthenticationFact{
			Endpoint: "Operator webhook", Methods: "CREATE", Mechanism: "Kubernetes admission",
			EnforcementPoint: "ValidatingWebhookConfiguration", Policy: "Admission validation", Source: source,
		})
		break
	}
	return result
}

func kubeRBACProxyAuthenticationFacts(input model.Input) []model.AuthenticationFact {
	controls := append([]model.RuntimeProxyControl{}, input.RuntimeProxies...)
	controls = append(controls, manifestKubeRBACProxyControls(input)...)
	var result []model.AuthenticationFact
	seen := map[string]bool{}
	for _, control := range controls {
		if !completeRuntimeProxyControl(input, control) {
			continue
		}
		key := strings.ToLower(control.Surface) + "\x00" + fmt.Sprint(control.ListenPort)
		if seen[key] {
			continue
		}
		seen[key] = true
		policy := control.AuthorizationScope
		if policy == "" {
			policy = "Kubernetes SubjectAccessReview delegation"
		}
		result = append(result, model.AuthenticationFact{
			Endpoint:  fmt.Sprintf("%s (port %d)", control.Surface, control.ListenPort),
			Methods:   valueOrString(control.Methods, "ALL"),
			Mechanism: "Bearer Token (Kubernetes TokenReview)", EnforcementPoint: "kube-rbac-proxy sidecar",
			Policy: policy, Source: control.Source,
		})
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Endpoint < result[j].Endpoint })
	return result
}

func manifestKubeRBACProxyControls(input model.Input) []model.RuntimeProxyControl {
	var result []model.RuntimeProxyControl
	for _, deployment := range input.Deployments {
		for _, proxy := range deployment.Containers {
			if proxy.Name != "kube-rbac-proxy" && proxy.Name != "odh-kube-auth-proxy" {
				continue
			}
			flags := stringArguments(proxy.Args)
			listenPort := finalAddressPort(flags["secure-listen-address"])
			if listenPort == 0 || flags["upstream"] == "" || flags["config-file"] == "" ||
				flags["tls-cert-file"] == "" || flags["tls-private-key-file"] == "" || deployment.ServiceAccount == "" {
				continue
			}
			app := ""
			for _, container := range deployment.Containers {
				if container.Name != proxy.Name && container.Name != "" {
					app = container.Name
					break
				}
			}
			if app == "" {
				continue
			}
			servicePort, serviceTargetPort := matchingProxyServicePort(input.Services, deployment, proxy, listenPort)
			if servicePort == 0 || serviceTargetPort == 0 {
				continue
			}
			secret := matchingProxyTLSSecret(input.Secrets, deployment, flags)
			if secret == "" {
				continue
			}
			role, binding := reviewBindingForServiceAccount(input.RBAC, deployment.ServiceAccount)
			if role == "" || binding == "" {
				continue
			}
			surface := humanizeSurface(app)
			methods := "REST"
			if strings.Contains(strings.ToLower(surface), "mcp") {
				methods = "HTTP"
				if !strings.HasSuffix(strings.ToLower(surface), " service") {
					surface += " Service"
				}
			}
			result = append(result, model.RuntimeProxyControl{
				Surface: surface, Methods: methods, Workload: deployment.Name, ServiceAccount: deployment.ServiceAccount,
				ListenPort: listenPort, Upstream: flags["upstream"], ConfigFile: flags["config-file"],
				TLSCertFile: flags["tls-cert-file"], TLSPrivateKeyFile: flags["tls-private-key-file"], TLSSecret: secret,
				ServicePort: servicePort, ServiceTargetPort: serviceTargetPort, ReviewRole: role, ReviewBinding: binding,
				AuthorizationScope: "Kubernetes SubjectAccessReview delegation", Source: deployment.Source,
			})
		}
	}
	return result
}

func completeRuntimeProxyControl(input model.Input, control model.RuntimeProxyControl) bool {
	if control.Surface == "" || control.Workload == "" || control.ServiceAccount == "" || control.ListenPort == 0 ||
		control.Upstream == "" || control.ConfigFile == "" || control.TLSCertFile == "" ||
		control.TLSPrivateKeyFile == "" || control.TLSSecret == "" || control.ServicePort == 0 ||
		control.ReviewRole == "" || control.ReviewBinding == "" {
		return false
	}
	if control.ServiceTargetPort != control.ListenPort {
		return false
	}
	if !reviewRoleNamed(input.RBAC, control.ReviewRole) {
		return false
	}
	for _, binding := range input.RBAC.ClusterRoleBindings {
		if binding.RoleRef != control.ReviewRole || (binding.Name != control.ReviewBinding && control.ReviewBinding != "") {
			continue
		}
		for _, subject := range binding.Subjects {
			if strings.EqualFold(subject.Kind, "ServiceAccount") && dynamicIdentityEquivalent(subject.Name, control.ServiceAccount) {
				return true
			}
		}
	}
	return false
}

func runtimeWebhookAuthenticationFacts(input model.Input) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	for _, server := range input.RuntimeWebhooks {
		_, _, secret, ok := webhookRuntimeGraph(input, server.Port)
		if !ok {
			continue
		}
		policy := fmt.Sprintf("API server validates the OpenShift service-ca serving certificate %s", secret.Name)
		if server.Conditional {
			policy += "; server is enabled conditionally by controller configuration"
		}
		result = append(result, model.AuthenticationFact{
			Endpoint: fmt.Sprintf("Webhook (port %d)", server.Port), Methods: "HTTPS",
			Mechanism: "TLS serving certificate (server identity)", EnforcementPoint: "controller-runtime webhook server",
			Policy: policy, Source: server.Source,
		})
	}
	return result
}

func webhookRuntimeGraph(input model.Input, port int) (model.Deployment, model.Service, model.Secret, bool) {
	for _, deployment := range input.Deployments {
		if !deploymentHasPort(deployment, port) {
			continue
		}
		for _, service := range input.Services {
			if !serviceTargetsPort(service, port) || (service.TargetDeployment != "" && service.TargetDeployment != deployment.Name) {
				continue
			}
			for _, secret := range input.Secrets {
				if secret.ProvisionedBy != "OpenShift service-ca operator" ||
					!referencesIdentity(secret.ReferencedBy, deployment.Name) || !referencesIdentity(secret.ReferencedBy, service.Name) {
					continue
				}
				return deployment, service, secret, true
			}
		}
	}
	return model.Deployment{}, model.Service{}, model.Secret{}, false
}

func stringArguments(arguments []string) map[string]string {
	result := map[string]string{}
	for _, argument := range arguments {
		if key, value, ok := strings.Cut(strings.TrimPrefix(argument, "--"), "="); ok {
			result[key] = value
		}
	}
	return result
}

func finalAddressPort(address string) int {
	index := strings.LastIndex(address, ":")
	if index < 0 {
		return 0
	}
	port, _ := strconv.Atoi(strings.TrimSuffix(address[index+1:], "/"))
	return port
}

func matchingProxyServicePort(services []model.Service, deployment model.Deployment, proxy model.Container, listenPort int) (int, int) {
	for _, service := range services {
		if service.TargetDeployment != "" && !dynamicIdentityEquivalent(service.TargetDeployment, deployment.Name) {
			continue
		}
		for _, port := range service.Ports {
			if fmt.Sprint(port.TargetPort) == fmt.Sprint(listenPort) {
				return scalarInt(port.Port), listenPort
			}
			if fmt.Sprint(port.TargetPort) == "https" && containerHasNamedPort(proxy, "https", listenPort) {
				return scalarInt(port.Port), listenPort
			}
		}
	}
	return 0, 0
}

func scalarInt(value any) int {
	parsed, _ := strconv.Atoi(fmt.Sprint(value))
	return parsed
}

func matchingProxyTLSSecret(secrets []model.Secret, deployment model.Deployment, flags map[string]string) string {
	if !strings.Contains(flags["tls-cert-file"], "/") || !strings.Contains(flags["tls-private-key-file"], "/") {
		return ""
	}
	for _, secret := range secrets {
		if (secret.Type == "kubernetes.io/tls" || strings.Contains(strings.ToLower(secret.Name), "tls")) &&
			referencesIdentity(secret.ReferencedBy, deployment.Name) {
			return secret.Name
		}
	}
	return ""
}

func reviewBindingForServiceAccount(rbac model.RBAC, serviceAccount string) (string, string) {
	for _, binding := range rbac.ClusterRoleBindings {
		if !reviewRoleNamed(rbac, binding.RoleRef) {
			continue
		}
		for _, subject := range binding.Subjects {
			if strings.EqualFold(subject.Kind, "ServiceAccount") && dynamicIdentityEquivalent(subject.Name, serviceAccount) {
				return binding.RoleRef, binding.Name
			}
		}
	}
	return "", ""
}

func reviewRoleNamed(rbac model.RBAC, name string) bool {
	for _, role := range rbac.ClusterRoles {
		if role.Name != name {
			continue
		}
		return roleAllowsReview(role, "authentication.k8s.io", "tokenreviews") &&
			roleAllowsReview(role, "authorization.k8s.io", "subjectaccessreviews")
	}
	return false
}

func dynamicIdentityEquivalent(left, right string) bool {
	if left == right {
		return true
	}
	leftSuffix, leftDynamic := dynamicSuffix(left)
	rightSuffix, rightDynamic := dynamicSuffix(right)
	return leftDynamic && rightDynamic && leftSuffix != "" && leftSuffix == rightSuffix
}

func dynamicSuffix(value string) (string, bool) {
	if !strings.HasPrefix(value, "{") {
		return "", false
	}
	end := strings.Index(value, "}")
	if end < 0 {
		return "", false
	}
	return value[end+1:], true
}

func containerHasNamedPort(container model.Container, name string, port int) bool {
	for _, candidate := range container.Ports {
		if strings.EqualFold(candidate.Name, name) && candidate.ContainerPort == port {
			return true
		}
	}
	return false
}

func deploymentHasPort(deployment model.Deployment, port int) bool {
	for _, container := range deployment.Containers {
		for _, candidate := range container.Ports {
			if candidate.ContainerPort == port {
				return true
			}
		}
	}
	return false
}

func serviceTargetsPort(service model.Service, port int) bool {
	for _, candidate := range service.Ports {
		if fmt.Sprint(candidate.TargetPort) == fmt.Sprint(port) {
			return true
		}
	}
	return false
}

func referencesIdentity(references []string, identity string) bool {
	for _, reference := range references {
		root := strings.Split(reference, "/")[0]
		if dynamicIdentityEquivalent(root, identity) || root == identity {
			return true
		}
	}
	return false
}

func humanizeSurface(value string) string {
	words := strings.FieldsFunc(value, func(character rune) bool { return character == '-' || character == '_' || character == '.' })
	for index, word := range words {
		lower := strings.ToLower(word)
		if lower == "api" || lower == "mcp" || lower == "rbac" {
			words[index] = strings.ToUpper(lower)
			continue
		}
		if lower != "" {
			words[index] = strings.ToUpper(lower[:1]) + lower[1:]
		}
	}
	return strings.Join(words, " ")
}

func valueOrString(value, fallback string) string {
	if value != "" {
		return value
	}
	return fallback
}

func accessPolicyAuthenticationFacts(input model.Input) []model.AuthenticationFact {
	var paths []string
	for _, ingress := range input.IngressRouting {
		if ingress.Kind != "HTTPRoute" {
			continue
		}
		for _, path := range ingress.Paths {
			if !httpEndpointMatchesIngress(input.HTTPEndpoints, path) && path != "/" && !strings.HasSuffix(path, "*") {
				path = strings.TrimSuffix(path, "/") + "/*"
			}
			paths = appendUniqueString(paths, path)
		}
	}
	if len(paths) == 0 {
		return nil
	}
	methods := publicHTTPMethods(input.HTTPEndpoints)
	if methods == "" {
		return nil
	}

	var result []model.AuthenticationFact
	for _, policy := range input.AccessPolicies {
		if policy.Kind != "Kuadrant AuthPolicy" || policy.TargetKind != "Gateway" || len(policy.Authentication) == 0 {
			continue
		}
		policyDescription := "Gateway policy authenticates requests"
		if len(policy.Authorization) > 0 {
			policyDescription += " and applies " + strings.Join(policy.Authorization, ", ")
		}
		if len(policy.Exclusions) > 0 {
			var exclusions []string
			for _, exclusion := range policy.Exclusions {
				exclusions = append(exclusions, exclusion.Methods+" "+exclusion.Path)
			}
			policyDescription += "; excludes " + strings.Join(exclusions, ", ")
		}
		result = append(result, model.AuthenticationFact{
			Endpoint: strings.Join(paths, ", "), Methods: methods,
			Mechanism:        strings.Join(policy.Authentication, " + "),
			EnforcementPoint: "Kuadrant/Authorino Gateway AuthPolicy",
			Policy:           policyDescription,
			Source:           policy.Source,
		})
	}
	return result
}

func httpEndpointMatchesIngress(endpoints []model.HTTPEndpoint, ingressPath string) bool {
	for _, endpoint := range endpoints {
		if endpoint.Path == ingressPath || (endpoint.Path != "/" && strings.HasSuffix(ingressPath, endpoint.Path)) {
			return true
		}
	}
	return false
}

func workloadProbeAuthenticationFacts(input model.Input) []model.AuthenticationFact {
	seen := map[string]bool{}
	for _, fact := range input.Authentication {
		seen[strings.ToLower(fact.Endpoint)+"\x00"+strings.ToUpper(fact.Methods)] = true
	}
	var result []model.AuthenticationFact
	for _, deployment := range input.Deployments {
		for _, container := range deployment.Containers {
			probes := []struct {
				name  string
				probe *model.Probe
			}{
				{name: "liveness", probe: container.LivenessProbe},
				{name: "readiness", probe: container.ReadinessProbe},
			}
			for _, candidate := range probes {
				probe := candidate.probe
				if probe == nil || probe.Type != "httpGet" || probe.Path == "" || len(probe.Headers) > 0 ||
					!httpEndpointExists(input.HTTPEndpoints, probe.Path, "GET") {
					continue
				}
				endpoint := workloadProbeEndpoint(container, probe)
				key := strings.ToLower(endpoint) + "\x00GET"
				if seen[key] {
					continue
				}
				seen[key] = true
				result = append(result, model.AuthenticationFact{
					Endpoint: endpoint, Methods: "GET", Mechanism: "None",
					EnforcementPoint: "N/A",
					Policy:           "Unauthenticated Kubernetes " + candidate.name + " probe endpoint",
					Source:           deployment.Source,
				})
			}
		}
	}
	return result
}

func workloadProbeEndpoint(container model.Container, probe *model.Probe) string {
	port := strings.TrimSpace(fmt.Sprint(probe.Port))
	for _, candidate := range container.Ports {
		if port == candidate.Name && candidate.ContainerPort > 0 {
			port = fmt.Sprint(candidate.ContainerPort)
			break
		}
	}
	if port == "" || port == "<nil>" {
		return probe.Path
	}
	return ":" + strings.TrimPrefix(port, ":") + probe.Path
}

func unknownMetricsAuthenticationFacts(input model.Input) []model.AuthenticationFact {
	if !httpEndpointExists(input.HTTPEndpoints, "/metrics", "Unknown") {
		return nil
	}
	for _, deployment := range input.Deployments {
		for _, container := range deployment.Containers {
			for _, port := range container.Ports {
				if !strings.EqualFold(port.Name, "metrics") || port.ContainerPort == 0 {
					continue
				}
				for _, service := range input.Services {
					if service.TargetDeployment != deployment.Name && service.Name != deployment.Name {
						continue
					}
					for _, servicePort := range service.Ports {
						if strings.EqualFold(servicePort.Name, "metrics") &&
							(fmt.Sprint(servicePort.Port) == fmt.Sprint(port.ContainerPort) ||
								fmt.Sprint(servicePort.TargetPort) == port.Name) {
							return []model.AuthenticationFact{{
								Endpoint: "/metrics", Methods: "Unknown", Mechanism: "Unknown",
								EnforcementPoint: "Application (" + deployment.Name + ")",
								Policy:           fmt.Sprintf("Dedicated metrics listener on port %d; authentication not established by source", port.ContainerPort),
								Source:           deployment.Source,
							}}
						}
					}
				}
			}
		}
	}
	return nil
}

func httpEndpointExists(endpoints []model.HTTPEndpoint, path, method string) bool {
	for _, endpoint := range endpoints {
		if endpoint.Path == path && (method == "" || strings.EqualFold(endpoint.Method, method)) {
			return true
		}
	}
	return false
}

func publicHTTPMethods(endpoints []model.HTTPEndpoint) string {
	found := map[string]bool{}
	for _, endpoint := range endpoints {
		found[strings.ToUpper(endpoint.Method)] = true
	}
	var methods []string
	for _, method := range []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"} {
		if found[method] {
			methods = append(methods, method)
		}
	}
	return strings.Join(methods, ", ")
}

func appendUniqueString(values []string, value string) []string {
	for _, existing := range values {
		if existing == value {
			return values
		}
	}
	return append(values, value)
}

func secureControllerMetricsAuthenticationFacts(input model.Input) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	seen := map[string]bool{}
	for _, control := range input.RuntimeSecurity {
		if control.Surface != "controller-runtime metrics" ||
			control.Mechanism != "Kubernetes TokenReview and SubjectAccessReview" {
			continue
		}
		for _, deployment := range input.Deployments {
			address := control.AddressDefault
			if control.AddressFlag != "" {
				resolved, found := workloadArgument(deployment, control.AddressFlag)
				if !found {
					continue
				}
				address = resolved
			}
			if address == "" || address == "0" {
				continue
			}
			secure := control.SecureDefault
			if control.SecureFlag != "" {
				if value, found := workloadArgument(deployment, control.SecureFlag); found {
					if value != "true" && value != "false" {
						continue
					}
					secure = value == "true"
				}
			}
			if !secure {
				continue
			}

			role := reviewRoleForServiceAccount(input.RBAC, deployment.ServiceAccount)
			if role.Name == "" {
				continue
			}
			service := metricsService(input.Services, deployment.Name, address)
			policy := fmt.Sprintf("RBAC via %s", role.Name)
			if service.Name == "" {
				policy += "; no selected Service exposes the endpoint"
			} else {
				policy += fmt.Sprintf("; exposed by Service %s", service.Name)
			}
			policy += "; " + controllerMetricsTLSPolicy(control, deployment, service, input.Secrets)
			endpoint := strings.TrimSuffix(address, "/") + "/metrics"
			key := strings.ToLower(endpoint) + "\x00get"
			if seen[key] {
				continue
			}
			seen[key] = true
			result = append(result, model.AuthenticationFact{
				Endpoint: endpoint, Methods: "GET",
				Mechanism:        "TokenReview + SubjectAccessReview (controller-runtime authn/authz filter)",
				EnforcementPoint: control.EnforcementPoint,
				Policy:           policy,
				Source:           control.Source,
			})
		}
	}
	return result
}

func controllerMetricsTLSPolicy(
	control model.RuntimeSecurityControl,
	deployment model.Deployment,
	service model.Service,
	secrets []model.Secret,
) string {
	if service.Name != "" && serviceHasServiceCATLS(secrets, service.Name) {
		return "TLS certificate provisioned by OpenShift service-ca"
	}
	certificatePath := control.CertificatePathDefault
	if control.CertificatePathFlag != "" {
		if value, found := workloadArgument(deployment, control.CertificatePathFlag); found {
			certificatePath = value
		}
	}
	switch control.CertificateMode {
	case "controller-runtime-default":
		return "controller-runtime generated self-signed TLS certificate"
	case "optional-external":
		if certificatePath == "" {
			return "controller-runtime generated self-signed TLS certificate"
		}
		return fmt.Sprintf("externally supplied TLS certificate from %s", certificatePath)
	default:
		return "TLS certificate source unresolved"
	}
}

func workloadArgument(deployment model.Deployment, name string) (string, bool) {
	for _, container := range deployment.Containers {
		for index, argument := range container.Args {
			trimmed := strings.TrimLeft(strings.TrimSpace(argument), "-")
			if trimmed == name {
				if index+1 < len(container.Args) {
					return strings.TrimSpace(container.Args[index+1]), true
				}
				return "true", true
			}
			if strings.HasPrefix(trimmed, name+"=") {
				return strings.TrimSpace(strings.TrimPrefix(trimmed, name+"=")), true
			}
		}
	}
	return "", false
}

func metricsService(services []model.Service, deployment, address string) model.Service {
	port := addressPort(address)
	if port == "" {
		return model.Service{}
	}
	for _, service := range services {
		if service.TargetDeployment != deployment {
			continue
		}
		for _, candidate := range service.Ports {
			if fmt.Sprint(candidate.Port) == port || fmt.Sprint(candidate.TargetPort) == port {
				return service
			}
		}
	}
	return model.Service{}
}

func addressPort(address string) string {
	withoutScheme := address
	if separator := strings.Index(withoutScheme, "://"); separator >= 0 {
		withoutScheme = withoutScheme[separator+3:]
	}
	separator := strings.LastIndex(withoutScheme, ":")
	if separator < 0 || separator == len(withoutScheme)-1 {
		return ""
	}
	return strings.TrimSuffix(withoutScheme[separator+1:], "/")
}

func serviceHasServiceCATLS(secrets []model.Secret, service string) bool {
	for _, secret := range secrets {
		if secret.Type != "kubernetes.io/tls" ||
			!strings.Contains(strings.ToLower(secret.ProvisionedBy), "service-ca") {
			continue
		}
		if stringSliceContains(secret.ReferencedBy, service) {
			return true
		}
	}
	return false
}

func reviewRoleForServiceAccount(rbac model.RBAC, serviceAccount string) model.Role {
	if serviceAccount == "" {
		return model.Role{}
	}
	roles := map[string]model.Role{}
	for _, role := range append(append([]model.Role{}, rbac.ClusterRoles...), rbac.Roles...) {
		if roleAllowsReview(role, "authentication.k8s.io", "tokenreviews") &&
			roleAllowsReview(role, "authorization.k8s.io", "subjectaccessreviews") {
			roles[role.Name] = role
		}
	}
	for _, binding := range append(append([]model.Binding{}, rbac.ClusterRoleBindings...), rbac.RoleBindings...) {
		role, exists := roles[binding.RoleRef]
		if exists && bindingHasServiceAccount(binding, serviceAccount) {
			return role
		}
	}
	return model.Role{}
}

func roleAllowsReview(role model.Role, group, resource string) bool {
	for _, rule := range role.Rules {
		if stringSliceContains(rule.APIGroups, group) && stringSliceContains(rule.Resources, resource) &&
			stringSliceContains(rule.Verbs, "create") {
			return true
		}
	}
	return false
}

func kubernetesAPIAuthenticationFacts(input model.Input) []model.AuthenticationFact {
	clientSource := ""
	for _, client := range input.RuntimeClients {
		if client.Target == "Kubernetes API" && (clientSource == "" || client.Client == "controller-runtime manager") {
			clientSource = client.Source
			if client.Client == "controller-runtime manager" {
				break
			}
		}
	}
	if clientSource == "" {
		return nil
	}

	roles := map[string]model.Role{}
	for _, role := range append(append([]model.Role{}, input.RBAC.ClusterRoles...), input.RBAC.Roles...) {
		roles[role.Name] = role
	}
	bindings := append(append([]model.Binding{}, input.RBAC.ClusterRoleBindings...), input.RBAC.RoleBindings...)
	var result []model.AuthenticationFact
	seen := map[string]bool{}
	for _, deployment := range input.Deployments {
		serviceAccount := strings.TrimSpace(deployment.ServiceAccount)
		if serviceAccount == "" || seen[serviceAccount] {
			continue
		}
		for _, binding := range bindings {
			role, roleExists := roles[binding.RoleRef]
			if !roleExists || !bindingHasServiceAccount(binding, serviceAccount) {
				continue
			}
			roleKind := binding.RoleKind
			if roleKind == "" {
				roleKind = "Role"
			}
			result = append(result, model.AuthenticationFact{
				Endpoint: "Kubernetes API", Methods: "REST",
				Mechanism:        "ServiceAccount token (in-cluster)",
				EnforcementPoint: "kube-apiserver",
				Policy:           fmt.Sprintf("RBAC enforced via %s %s; SA %s", role.Name, roleKind, serviceAccount),
				Source:           clientSource,
			})
			seen[serviceAccount] = true
			break
		}
	}
	return result
}

func bindingHasServiceAccount(binding model.Binding, serviceAccount string) bool {
	for _, subject := range binding.Subjects {
		if subject.Kind == "ServiceAccount" && dynamicIdentityEquivalent(subject.Name, serviceAccount) {
			return true
		}
	}
	return false
}

type aggregateAccess struct {
	roles map[string]model.Role
}

func rbacAuthenticationFacts(rbac model.RBAC) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	aggregates := map[string]*aggregateAccess{}
	roles := append(append([]model.Role{}, rbac.ClusterRoles...), rbac.Roles...)
	for _, role := range roles {
		tier := aggregateRoleTier(role.Labels)
		for _, rule := range role.Rules {
			if tier != "" {
				for _, group := range rule.APIGroups {
					if group == "" {
						continue
					}
					access := aggregates[group]
					if access == nil {
						access = &aggregateAccess{roles: map[string]model.Role{}}
						aggregates[group] = access
					}
					access.roles[tier] = role
				}
			}
			if stringSliceContains(rule.Resources, "secrets") && len(rule.ResourceNames) > 0 {
				endpoint := namedSecretEndpoint(rule.ResourceNames)
				result = append(result, model.AuthenticationFact{
					Endpoint: endpoint, Methods: "Kubernetes API",
					Mechanism:        "RBAC with resourceNames restriction",
					EnforcementPoint: "kube-apiserver",
					Policy:           fmt.Sprintf("%s restricts secret access to %s only", role.Name, strings.Join(rule.ResourceNames, ", ")),
					Source:           role.Source,
				})
			}
		}
	}

	groups := make([]string, 0, len(aggregates))
	for group := range aggregates {
		groups = append(groups, group)
	}
	sort.Strings(groups)
	for _, group := range groups {
		access := aggregates[group]
		if access.roles["admin"].Name == "" || access.roles["edit"].Name == "" || access.roles["view"].Name == "" {
			continue
		}
		endpoint, policy := aggregateAccessDescription(group, access.roles)
		result = append(result, model.AuthenticationFact{
			Endpoint: endpoint, Methods: "Kubernetes API",
			Mechanism:        "RBAC aggregation (aggregate-to-admin/edit/view ClusterRoles)",
			EnforcementPoint: "kube-apiserver", Policy: policy,
			Source: access.roles["admin"].Source,
		})
	}
	return result
}

func aggregateRoleTier(labels map[string]string) string {
	for _, tier := range []string{"admin", "edit", "view"} {
		key := "rbac.authorization.k8s.io/aggregate-to-" + tier
		if strings.EqualFold(strings.TrimSpace(labels[key]), "true") {
			return tier
		}
	}
	return ""
}

func aggregateAccessDescription(group string, roles map[string]model.Role) (string, string) {
	if group == "argoproj.io" {
		return "Argo Workflow CRDs (argoproj.io)", "admin: full CRUD on all Argo resources; edit: full CRUD excl. WorkflowTaskSets; view: read-only"
	}
	return "RBAC-aggregated resources (" + group + ")", fmt.Sprintf(
		"Built-in admin, edit, and view roles inherit permissions from %s, %s, and %s",
		roles["admin"].Name, roles["edit"].Name, roles["view"].Name,
	)
}

func namedSecretEndpoint(names []string) string {
	if stringSliceContains(names, "argo-workflows-agent-ca-certificates") {
		return "Argo Workflow agent secrets"
	}
	return "Named Secret access (" + strings.Join(names, ", ") + ")"
}

func stringSliceContains(values []string, wanted string) bool {
	for _, value := range values {
		if value == wanted {
			return true
		}
	}
	return false
}

func openshiftIntegrations(groups map[string]string) []model.IntegrationFact {
	mappings := map[string]model.IntegrationFact{
		"operators.coreos.com": {Component: "OLM (operators.coreos.com)", InteractionType: "CRD Watch", Protocol: "HTTPS", Encryption: "TLS 1.2+", Purpose: "Operator subscription status"},
		"console.openshift.io": {Component: "OpenShift Console", InteractionType: "CRD Watch", Protocol: "HTTPS", Encryption: "TLS 1.2+", Purpose: "Console link resources"},
		"route.openshift.io":   {Component: "OpenShift Routes", InteractionType: "CRD Watch", Protocol: "HTTPS", Encryption: "TLS 1.2+", Purpose: "Dashboard route status"},
		"user.openshift.io":    {Component: "OpenShift Users/Groups", InteractionType: "REST", Port: 6443, Protocol: "HTTPS", Encryption: "TLS 1.2+", Purpose: "User and group management"},
		"image.openshift.io":   {Component: "OpenShift Image Streams", InteractionType: "REST", Port: 6443, Protocol: "HTTPS", Encryption: "TLS 1.2+", Purpose: "Image stream access"},
	}
	var result []model.IntegrationFact
	for group, fact := range mappings {
		if source := groups[group]; source != "" {
			fact.Source = source
			result = append(result, fact)
		}
	}
	return result
}

func hasKubernetesClient(dependencies model.Dependencies) bool {
	for _, dependency := range dependencies.Packages {
		if dependency.Name == "@kubernetes/client-node" {
			return true
		}
	}
	for _, dependency := range dependencies.GoModules {
		if dependency.Module == "k8s.io/client-go" {
			return true
		}
	}
	return false
}

func sourceLine(root, relative, needle string) string {
	path := filepath.Join(root, filepath.FromSlash(relative))
	file, err := os.Open(path)
	if err != nil {
		return relative
	}
	defer file.Close()
	scanner := bufio.NewScanner(file)
	line := 0
	for scanner.Scan() {
		line++
		if needle == "" || strings.Contains(scanner.Text(), needle) {
			return fmt.Sprintf("%s:%d", relative, line)
		}
	}
	return relative + ":1"
}

func sourceContaining(root, relative, needle string) (string, bool) {
	path := filepath.Join(root, filepath.FromSlash(relative))
	content, err := os.ReadFile(path)
	if err != nil || !strings.Contains(string(content), needle) {
		return "", false
	}
	return sourceLine(root, relative, needle), true
}

func fileExists(path string) bool {
	info, err := os.Stat(path)
	return err == nil && !info.IsDir()
}
