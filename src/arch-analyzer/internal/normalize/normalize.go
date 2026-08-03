package normalize

import (
	"fmt"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type Options struct {
	Distribution string
	GeneratedBy  string
}

func Input(input model.Input, options Options) model.Document {
	if options.Distribution == "" {
		options.Distribution = "Both"
	}
	if options.GeneratedBy == "" {
		options.GeneratedBy = "arch-analyzer"
	}

	sources := newSourceIndex()
	document := model.Document{
		Component:            input.Component,
		Purpose:              valueOr(input.Summary, "Pending synthesis from source-backed facts."),
		DataCoverage:         input.DataCoverage,
		CategoryCoverage:     input.CategoryCoverage,
		SynthesisEvidence:    input.SynthesisEvidence,
		CrossCuttingEvidence: input.CrossCuttingEvidence,
		Metadata: model.Metadata{
			Repository:     repositoryURL(input.Repo),
			Version:        valueOr(input.CommitSHA, "Unknown"),
			Distribution:   options.Distribution,
			DeploymentType: deploymentType(input),
			GeneratedBy:    options.GeneratedBy,
		},
	}
	for _, ref := range input.CrossReferences {
		document.CrossReferences = append(document.CrossReferences, model.CrossReference{Kind: ref.Kind, From: ref.From, To: ref.To, Relationship: ref.Relationship, Details: ref.Details})
	}
	for _, finding := range input.CoverageFindings {
		document.CoverageFindings = append(document.CoverageFindings, model.CoverageFinding{Category: finding.Category, Status: finding.Status, Finding: finding.Finding})
	}
	for _, component := range input.SourceComponents {
		document.ArchitectureComponents = append(document.ArchitectureComponents, model.ArchitectureComponent{
			Component: component.Name,
			Type:      component.Type,
			Purpose:   component.Purpose,
		})
		sources.add(component.Source, "Architecture Components")
	}
	for _, entrypoint := range input.Entrypoints {
		document.ArchitectureComponents = append(document.ArchitectureComponents, model.ArchitectureComponent{
			Component: entrypoint.Name,
			Type:      valueOr(entrypoint.Type, "Entrypoint"),
			Purpose:   valueOr(entrypoint.Command, entrypoint.Runtime+" entrypoint"),
		})
		sources.add(entrypoint.Source, "Architecture Components")
	}

	for _, deployment := range input.Deployments {
		purposeParts := make([]string, 0, len(deployment.Containers))
		for _, container := range deployment.Containers {
			detail := container.Name
			if container.Image != "" {
				detail += " (" + container.Image + ")"
			}
			purposeParts = append(purposeParts, detail)
			addProbeEndpoints(&document, sources, deployment.Source, container)
		}
		document.ArchitectureComponents = append(document.ArchitectureComponents, model.ArchitectureComponent{
			Component: deployment.Name,
			Type:      valueOr(deployment.Kind, "Kubernetes workload"),
			Purpose:   valueOr(strings.Join(purposeParts, ", "), "Extracted workload"),
		})
		sources.add(deployment.Source, "Architecture Components")
	}
	if len(document.ArchitectureComponents) == 0 {
		for _, dockerfile := range input.Dockerfiles {
			document.ArchitectureComponents = append(document.ArchitectureComponents, model.ArchitectureComponent{
				Component: dockerfile.Path,
				Type:      "Container image",
				Purpose:   valueOr(dockerfile.BaseImage, "Container build"),
			})
			sources.add(dockerfile.Path, "Architecture Components")
		}
	}

	for _, crd := range input.CRDs {
		document.CRDs = append(document.CRDs, model.CRDRow{
			Group: crd.Group, Version: crd.Version, Kind: crd.Kind, Scope: crd.Scope,
			APIRole: crdAPIRole(crd.Group),
			Purpose: "Custom resource managed by " + input.Component,
		})
		sources.add(crd.Source, "APIs Exposed")
	}
	for _, runtime := range input.ServingRuntimes {
		document.ServingRuntimes = append(document.ServingRuntimes, model.ServingRuntimeRow{
			Name:                  runtime.Name,
			Kind:                  runtime.Kind,
			APIGroup:              runtime.APIGroup,
			Version:               runtime.Version,
			Scope:                 runtime.Scope,
			SupportedModelFormats: strings.Join(unique(runtime.SupportedModelFormats), ", "),
			ContainerImages:       strings.Join(unique(runtime.ContainerImages), ", "),
			BuiltInAdapter:        runtime.BuiltInAdapter,
			Source:                runtime.Source,
		})
		sources.add(runtime.Source, "APIs Exposed")
	}
	for _, endpoint := range input.HTTPEndpoints {
		document.HTTPEndpoints = append(document.HTTPEndpoints, model.HTTPEndpointRow{
			Path: endpoint.Path, Method: valueOr(endpoint.Method, "Unknown"),
			Port: scalar(endpoint.Port), Protocol: valueOr(endpoint.Protocol, "HTTP"),
			Transport:  valueOr(endpoint.Transport, "Unknown"),
			Encryption: valueOr(endpoint.Encryption, "Unknown"), Auth: valueOr(endpoint.Auth, "Unknown"),
			Owner:   endpoint.Owner,
			Purpose: valueOr(endpoint.Description, "Extracted HTTP endpoint"),
		})
		sources.add(endpoint.Source, "APIs Exposed")
	}
	for _, service := range input.GRPCServices {
		document.GRPCServices = append(document.GRPCServices, model.GRPCServiceRow{
			Service: service.Service, Port: scalar(service.Port),
			Protocol:   valueOr(service.Protocol, "gRPC"),
			Transport:  valueOr(service.Transport, "Unknown"),
			Encryption: valueOr(service.Encryption, "Unknown"),
			Auth:       valueOr(service.Auth, "Unknown"),
			Owner:      service.Owner,
			Purpose:    valueOr(service.Purpose, "Extracted gRPC service"),
		})
		sources.add(service.Source, "APIs Exposed")
	}

	for _, dependency := range input.Dependencies.GoModules {
		document.ExternalDependencies = append(document.ExternalDependencies, model.ExternalDependencyRow{
			Component: dependency.Module, Version: dependency.Version, Required: "Yes", Role: valueOr(dependency.Role, dependency.Category),
			Purpose: valueOr(dependency.Purpose, valueOr(dependency.Category, "Go module dependency")),
		})
		sources.add(valueOr(dependency.Source, "go.mod"), "Dependencies")
	}
	for _, dependency := range input.Dependencies.Packages {
		document.ExternalDependencies = append(document.ExternalDependencies, model.ExternalDependencyRow{
			Component: dependency.Name, Version: dependency.Version, Required: "Yes", Role: valueOr(dependency.Role, "Unknown"),
			Purpose: valueOr(dependency.Purpose, dependency.Ecosystem+" package dependency"),
		})
		sources.add(dependency.Source, "Dependencies")
	}
	for _, dependency := range input.Dependencies.Internal {
		document.InternalDependencies = append(document.InternalDependencies, model.InternalDependencyRow{
			Component: dependency.Component, InteractionType: dependency.Interaction,
			Role:    valueOr(dependency.Role, "Unknown"),
			Purpose: valueOr(dependency.Purpose, "Internal ODH/RHOAI dependency"),
		})
		sources.add(dependency.Source, "Dependencies")
	}
	for _, resolvedDefault := range input.SourceDefaults {
		for _, source := range resolvedDefault.Sources {
			sources.add(source, "Network Architecture")
		}
	}

	for _, service := range input.Services {
		if len(service.Ports) == 0 {
			document.Services = append(document.Services, model.ServiceRow{
				Name: service.Name, Type: valueOr(service.Type, "Unknown"), Exposure: "Internal",
				Encryption: valueOr(service.Encryption, "Unknown"), Auth: valueOr(service.Auth, "Unknown"),
			})
		}
		for _, port := range service.Ports {
			serviceName := service.Name
			if service.Name == "odh-dashboard" || service.Name == "rhods-dashboard" {
				if port.Name == "dashboard-ui" {
					serviceName = "odh-dashboard / rhods-dashboard"
				} else if port.Name != "" {
					serviceName = "odh-dashboard (" + port.Name + ")"
				}
			}
			document.Services = append(document.Services, model.ServiceRow{
				Name: serviceName, Type: valueOr(service.Type, "Unknown"),
				Port: withProtocol(port.Port, port.Protocol), TargetPort: scalar(port.TargetPort),
				Protocol: serviceProtocol(port), Encryption: valueOr(port.Encryption, valueOr(service.Encryption, "Unknown")),
				Auth: valueOr(port.Auth, valueOr(service.Auth, "Unknown")), Exposure: valueOr(service.Exposure, "Internal"),
			})
		}
		sources.add(service.Source, "Network Architecture")
	}
	for _, ingress := range input.IngressRouting {
		protocol := valueOr(ingress.Protocol, "HTTP")
		encryption := "Unknown"
		if ingress.TLS {
			protocol = "HTTPS"
			encryption = "TLS"
		}
		document.Ingress = append(document.Ingress, model.IngressRow{
			Name: canonicalDashboardResource(ingress.Name), Type: ingress.Kind, Hosts: ingress.Host,
			Protocol: protocol, Encryption: encryption, TLSMode: "Unknown", Exposure: "External",
		})
		sources.add(ingress.Source, "Network Architecture")
	}
	for _, connection := range input.ExternalConnections {
		destination := valueOr(connection.Target, connection.Service)
		document.Egress = append(document.Egress, model.EgressRow{
			Destination: destination, Port: scalar(connection.Port),
			Protocol: valueOr(connection.Protocol, connection.Type), Encryption: valueOr(connection.Encryption, "Unknown"),
			Auth:    valueOr(connection.Auth, "Unknown"),
			Purpose: valueOr(connection.Function, "External "+connection.Type+" connection"),
		})
		sources.add(connection.Source, "Network Architecture")
		document.IntegrationPoints = append(document.IntegrationPoints, model.IntegrationPointRow{
			Component: destination, InteractionType: valueOr(connection.Type, "External connection"),
			Port: scalar(connection.Port), Protocol: connection.Protocol,
			Encryption: valueOr(connection.Encryption, "Unknown"), Purpose: connection.Function,
		})
		sources.add(connection.Source, "Integration Points")
	}

	roles := append(append([]model.Role{}, input.RBAC.ClusterRoles...), input.RBAC.Roles...)
	for _, role := range roles {
		for _, rule := range role.Rules {
			document.ClusterRoles = append(document.ClusterRoles, model.ClusterRoleRow{
				Name: canonicalDashboardResource(role.Name), APIGroup: strings.Join(unique(rule.APIGroups), ", "),
				Resources: strings.Join(unique(rule.Resources), ", "), Verbs: strings.Join(unique(rule.Verbs), ", "),
			})
		}
		sources.add(role.Source, "Security")
	}
	addBinding := func(binding model.Binding, clusterScoped bool) {
		var names, namespaces []string
		for _, subject := range binding.Subjects {
			name := canonicalDashboardResource(subject.Name)
			if subject.Kind != "" && !strings.EqualFold(subject.Kind, "ServiceAccount") {
				name = subject.Kind + "/" + name
			}
			names = append(names, name)
			if subject.Namespace != "" {
				namespaces = append(namespaces, subject.Namespace)
			}
		}
		namespace := valueOr(binding.Namespace, strings.Join(unique(namespaces), ", "))
		if clusterScoped && namespace == "" {
			namespace = "Cluster-scoped"
		}
		role := canonicalDashboardResource(binding.RoleRef)
		if binding.RoleKind != "" {
			role += " (" + binding.RoleKind + ")"
		}
		document.RoleBindings = append(document.RoleBindings, model.RoleBindingRow{
			Name: canonicalDashboardResource(binding.Name), Namespace: namespace,
			Role: role, ServiceAccount: strings.Join(unique(names), ", "),
		})
		sources.add(binding.Source, "Security")
	}
	for _, binding := range input.RBAC.ClusterRoleBindings {
		addBinding(binding, true)
	}
	for _, binding := range input.RBAC.RoleBindings {
		addBinding(binding, false)
	}
	for _, secret := range input.Secrets {
		document.Secrets = append(document.Secrets, model.SecretRow{
			Name: secret.Name, Type: valueOr(secret.Type, "Unknown"),
			Purpose:       strings.Join(secret.ReferencedBy, ", "),
			ProvisionedBy: valueOr(secret.ProvisionedBy, "Unknown"), AutoRotate: "Unknown",
		})
		sources.add(secret.Source, "Security")
	}

	for _, webhook := range input.Webhooks {
		var resources, operations []string
		for _, rule := range webhook.Rules {
			resources = append(resources, rule.Resources...)
			operations = append(operations, rule.Operations...)
		}
		document.Webhooks = append(document.Webhooks, model.WebhookRow{
			Name: webhook.Name, Type: webhook.Type, Path: webhook.Path, Port: scalar(webhook.Port),
			FailurePolicy: webhook.FailurePolicy, Resources: strings.Join(unique(resources), ", "),
			Operations: strings.Join(unique(operations), ", "), Purpose: webhook.Purpose,
		})
		if webhook.Path != "" {
			document.HTTPEndpoints = append(document.HTTPEndpoints, model.HTTPEndpointRow{
				Path: webhook.Path, Method: "POST", Port: scalar(webhook.Port), Protocol: "HTTPS", Transport: "Unknown",
				Encryption: "TLS", Auth: "Kubernetes admission", Purpose: valueOr(webhook.Purpose, webhook.Type+" admission webhook"),
			})
		}
		for _, source := range webhook.Sources {
			sources.addWithLine(source.File, source.Line, "APIs Exposed, Security")
		}
	}

	explicitIntegrationKeys := make(map[string]bool, len(input.IntegrationPoints))
	for _, integration := range input.IntegrationPoints {
		explicitIntegrationKeys[integration.Component+"\x00"+integration.InteractionType] = true
	}
	for _, dependency := range input.Dependencies.Internal {
		if explicitIntegrationKeys[dependency.Component+"\x00"+dependency.Interaction] {
			continue
		}
		document.IntegrationPoints = append(document.IntegrationPoints, model.IntegrationPointRow{
			Component: dependency.Component, InteractionType: dependency.Interaction,
			Purpose: valueOr(dependency.Purpose, "Internal dependency"), Encryption: "Unknown",
		})
	}
	for _, watch := range input.ControllerWatches {
		document.IntegrationPoints = append(document.IntegrationPoints, model.IntegrationPointRow{
			Component: watch.GVK, InteractionType: "Controller watch (" + watch.Type + ")",
			Protocol: "Kubernetes API", Encryption: "TLS",
			Purpose: valueOr(watch.Controller, "Controller reconciliation"),
		})
		sources.add(watch.Source, "Integration Points")
	}
	for _, ref := range input.ComponentRefs {
		document.IntegrationPoints = append(document.IntegrationPoints, model.IntegrationPointRow{
			Component: ref.Component, InteractionType: valueOr(ref.Interaction, ref.Type),
			Encryption: "Unknown", Purpose: ref.Reference,
		})
		sources.add(ref.Source, "Integration Points")
	}
	for _, webhook := range input.ExternalWebhooks {
		document.IntegrationPoints = append(document.IntegrationPoints, model.IntegrationPointRow{
			Component: webhook.Component, InteractionType: "External admission webhook",
			Protocol: "HTTPS", Encryption: "TLS", Purpose: webhook.Webhook,
		})
	}
	for _, integration := range input.IntegrationPoints {
		document.IntegrationPoints = append(document.IntegrationPoints, model.IntegrationPointRow{
			Component: integration.Component, InteractionType: integration.InteractionType,
			Role: integration.Role,
			Port: scalar(integration.Port), Protocol: integration.Protocol,
			Encryption: valueOr(integration.Encryption, "Unknown"), Purpose: integration.Purpose,
		})
		sources.add(integration.Source, "Integration Points")
	}
	for _, authentication := range input.Authentication {
		document.Authentication = append(document.Authentication, model.AuthenticationRow{
			Endpoint: authentication.Endpoint, Methods: authentication.Methods,
			Mechanism: authentication.Mechanism, EnforcementPoint: authentication.EnforcementPoint,
			Policy: authentication.Policy,
		})
		sources.add(authentication.Source, "Security")
	}
	document.SecurityEvidence = append(document.SecurityEvidence, input.SecurityEvidence...)
	for _, evidence := range input.SecurityEvidence {
		sources.add(evidence.Source, "Security")
		for _, source := range evidence.Sources {
			sources.add(source, "Security")
		}
	}
	document.RecentChanges = append(document.RecentChanges, input.RecentChanges...)

	document.Metadata.Languages = languages(input, sources)
	document.Sources = sources.rows()
	document.Contract = input.ContextContract
	sortDocument(&document)
	return document
}

func canonicalDashboardResource(name string) string {
	switch name {
	case "rhods-dashboard":
		return "odh-dashboard"
	case "rhods-dashboard-auth-delegator":
		return "odh-dashboard-auth-delegator"
	case "rhods-dashboard-monitoring":
		return "odh-dashboard-cluster-monitoring"
	default:
		return name
	}
}

func addProbeEndpoints(document *model.Document, sources *sourceIndex, source string, container model.Container) {
	for _, probe := range []*model.Probe{container.LivenessProbe, container.ReadinessProbe} {
		if probe == nil || probe.Path == "" {
			continue
		}
		document.HTTPEndpoints = append(document.HTTPEndpoints, model.HTTPEndpointRow{
			Path: probe.Path, Method: "GET", Port: scalar(probe.Port), Protocol: "HTTP",
			Encryption: "Unknown", Auth: "Unknown", Purpose: probe.Type + " probe",
		})
		sources.add(source, "APIs Exposed")
	}
}

func repositoryURL(repo string) string {
	if repo == "" {
		return "Unknown"
	}
	if strings.Contains(repo, "://") {
		return repo
	}
	return "https://github.com/" + strings.TrimSuffix(repo, ".git")
}

func deploymentType(input model.Input) string {
	var roles []string
	if len(input.CRDs) > 0 || len(input.ControllerWatches) > 0 {
		roles = append(roles, "Kubernetes Operator / Controller")
	}
	hasSDK := false
	hasSidecarUtility := false
	for _, component := range input.SourceComponents {
		lowerType := strings.ToLower(component.Type)
		if strings.Contains(lowerType, "python sdk") {
			hasSDK = true
		}
		if strings.Contains(lowerType, "sidecar") || strings.Contains(lowerType, "init container") {
			hasSidecarUtility = true
		}
	}
	if hasSDK {
		roles = appendDeploymentRole(roles, "Python SDK")
	}
	if hasSidecarUtility {
		roles = appendDeploymentRole(roles, "Sidecar utilities")
	}
	if len(roles) > 0 {
		return strings.Join(roles, " + ")
	}
	if len(input.Deployments) > 0 {
		return "Kubernetes Workload"
	}
	if len(input.SourceComponents) > 0 {
		return "Application Service"
	}
	if len(input.Dockerfiles) > 0 {
		return "Container Image"
	}
	return "Unknown"
}

func appendDeploymentRole(roles []string, role string) []string {
	for _, existing := range roles {
		if existing == role {
			return roles
		}
	}
	return append(roles, role)
}

func languages(input model.Input, sources *sourceIndex) string {
	seen := map[string]bool{}
	if input.Dependencies.GoVersion != "" || len(input.Dependencies.GoModules) > 0 {
		seen["Go"] = true
	}
	pythonRuntimeEvidence := false
	for _, dependency := range input.Dependencies.Packages {
		if dependency.Ecosystem == "Python" && strings.EqualFold(dependency.Name, "Python") {
			pythonRuntimeEvidence = true
		}
	}
	for _, component := range input.SourceComponents {
		if strings.Contains(strings.ToLower(component.Type), "python") &&
			!isNonRuntimeSource(component.Source) {
			pythonRuntimeEvidence = true
		}
	}
	for _, dependency := range input.Dependencies.Packages {
		if dependency.Ecosystem == "Cargo" {
			seen["Rust"] = true
		}
		if dependency.Ecosystem == "npm" {
			seen["TypeScript"] = true
		}
	}
	for file := range sources.items {
		switch strings.ToLower(filepath.Ext(strings.Split(file, ":")[0])) {
		case ".go":
			seen["Go"] = true
		case ".py":
			if !isNonRuntimeSource(file) {
				pythonRuntimeEvidence = true
			}
		case ".ts", ".tsx":
			seen["TypeScript"] = true
		case ".rs":
			seen["Rust"] = true
		}
	}
	if pythonRuntimeEvidence {
		seen["Python"] = true
	}
	for _, dockerfile := range input.Dockerfiles {
		if strings.Contains(strings.ToLower(dockerfile.BaseImage), "rust") {
			seen["Rust"] = true
		}
	}
	var result []string
	for language := range seen {
		result = append(result, language)
	}
	sort.Strings(result)
	return valueOr(strings.Join(result, ", "), "Unknown")
}

func isNonRuntimeSource(raw string) bool {
	file, _ := splitSource(raw)
	for _, part := range strings.Split(filepath.ToSlash(file), "/") {
		switch strings.ToLower(part) {
		case "test", "tests", "testdata", "example", "examples", "fixture", "fixtures":
			return true
		}
		if strings.Contains(strings.ToLower(part), "sample") {
			return true
		}
	}
	return false
}

func scalar(value any) string {
	if value == nil {
		return ""
	}
	switch typed := value.(type) {
	case float64:
		if typed == float64(int64(typed)) {
			return strconv.FormatInt(int64(typed), 10)
		}
		return strconv.FormatFloat(typed, 'f', -1, 64)
	case string:
		return typed
	default:
		return fmt.Sprint(typed)
	}
}

func withProtocol(value any, protocol string) string {
	port := scalar(value)
	if port == "" || protocol == "" {
		return port
	}
	return port + "/" + protocol
}

func serviceProtocol(port model.ServicePort) string {
	if strings.Contains(strings.ToLower(port.Name), "postgres") || scalar(port.Port) == "5432" {
		return "PostgreSQL"
	}
	if port.AppProtocol != "" && !strings.EqualFold(port.AppProtocol, "tcp") && !strings.EqualFold(port.AppProtocol, "udp") {
		return strings.ToUpper(port.AppProtocol)
	}
	return valueOr(port.Protocol, "Unknown")
}

func valueOr(value, fallback string) string {
	if strings.TrimSpace(value) == "" {
		return fallback
	}
	return value
}

func unique(values []string) []string {
	seen := map[string]bool{}
	result := make([]string, 0, len(values))
	for _, value := range values {
		if value == "" || seen[value] {
			continue
		}
		seen[value] = true
		result = append(result, value)
	}
	sort.Strings(result)
	return result
}

func sortDocument(document *model.Document) {
	document.ArchitectureComponents = mergeArchitectureComponents(document.ArchitectureComponents)
	document.CRDs = mergeCRDRows(document.CRDs)
	document.HTTPEndpoints = dedupePrefer(
		document.HTTPEndpoints,
		func(row model.HTTPEndpointRow) string { return strings.ToUpper(row.Method) + "\x00" + row.Path },
		func(row model.HTTPEndpointRow) int { return factQuality(row.Port, row.Protocol, row.Purpose) },
	)
	document.GRPCServices = dedupe(document.GRPCServices, func(row model.GRPCServiceRow) string {
		return row.Service
	})
	document.ExternalDependencies = dedupe(document.ExternalDependencies, func(row model.ExternalDependencyRow) string {
		return row.Component
	})
	document.InternalDependencies = dedupe(document.InternalDependencies, func(row model.InternalDependencyRow) string {
		return row.Component + "\x00" + row.InteractionType
	})
	document.Services = dedupe(document.Services, func(row model.ServiceRow) string {
		return row.Name + "\x00" + row.Port
	})
	document.Ingress = dedupe(document.Ingress, func(row model.IngressRow) string {
		return row.Type + "\x00" + row.Name + "\x00" + row.Hosts
	})
	document.Egress = dedupe(document.Egress, func(row model.EgressRow) string {
		return row.Destination + "\x00" + row.Port + "\x00" + row.Protocol
	})
	document.ClusterRoles = mergeClusterRoleRows(document.ClusterRoles)
	document.ClusterRoles = dedupe(document.ClusterRoles, func(row model.ClusterRoleRow) string {
		return row.Name + "\x00" + row.APIGroup + "\x00" + row.Resources + "\x00" + row.Verbs
	})
	document.RoleBindings = dedupe(document.RoleBindings, func(row model.RoleBindingRow) string {
		return row.Name + "\x00" + row.Namespace + "\x00" + row.Role + "\x00" + row.ServiceAccount
	})
	document.Secrets = dedupe(document.Secrets, func(row model.SecretRow) string {
		return row.Name
	})
	document.Webhooks = dedupe(document.Webhooks, func(row model.WebhookRow) string {
		return row.Name + "\x00" + row.Path
	})
	document.ServingRuntimes = dedupe(document.ServingRuntimes, func(row model.ServingRuntimeRow) string {
		return row.APIGroup + "\x00" + row.Version + "\x00" + row.Kind + "\x00" + row.Name
	})
	document.IntegrationPoints = dedupe(document.IntegrationPoints, func(row model.IntegrationPointRow) string {
		return row.Component + "\x00" + row.InteractionType + "\x00" + row.Purpose
	})

	sort.Slice(document.ArchitectureComponents, func(i, j int) bool {
		return document.ArchitectureComponents[i].Component < document.ArchitectureComponents[j].Component
	})
	sort.Slice(document.CRDs, func(i, j int) bool {
		left := document.CRDs[i]
		right := document.CRDs[j]
		return left.APIRole+"\x00"+left.Group+"\x00"+left.Version+"\x00"+left.Kind <
			right.APIRole+"\x00"+right.Group+"\x00"+right.Version+"\x00"+right.Kind
	})
	sort.Slice(document.ServingRuntimes, func(i, j int) bool {
		left := document.ServingRuntimes[i]
		right := document.ServingRuntimes[j]
		return left.APIGroup+"\x00"+left.Version+"\x00"+left.Kind+"\x00"+left.Name <
			right.APIGroup+"\x00"+right.Version+"\x00"+right.Kind+"\x00"+right.Name
	})
	sort.Slice(document.HTTPEndpoints, func(i, j int) bool {
		return document.HTTPEndpoints[i].Path+document.HTTPEndpoints[i].Method < document.HTTPEndpoints[j].Path+document.HTTPEndpoints[j].Method
	})
	sort.Slice(document.GRPCServices, func(i, j int) bool {
		return document.GRPCServices[i].Service < document.GRPCServices[j].Service
	})
	sort.Slice(document.Services, func(i, j int) bool {
		return document.Services[i].Name+document.Services[i].Port < document.Services[j].Name+document.Services[j].Port
	})
	sort.Slice(document.IntegrationPoints, func(i, j int) bool {
		left := document.IntegrationPoints[i]
		right := document.IntegrationPoints[j]
		return left.Component+"\x00"+left.InteractionType+"\x00"+left.Port+"\x00"+left.Protocol+"\x00"+left.Encryption+"\x00"+left.Purpose <
			right.Component+"\x00"+right.InteractionType+"\x00"+right.Port+"\x00"+right.Protocol+"\x00"+right.Encryption+"\x00"+right.Purpose
	})
}

func mergeCRDRows(rows []model.CRDRow) []model.CRDRow {
	positions := map[string]int{}
	versions := map[string]map[string]bool{}
	result := make([]model.CRDRow, 0, len(rows))
	for _, row := range rows {
		key := row.Group + "\x00" + row.Kind + "\x00" + row.Scope + "\x00" + row.APIRole
		position, exists := positions[key]
		if !exists {
			position = len(result)
			positions[key] = position
			versions[key] = map[string]bool{}
			result = append(result, row)
		}
		for _, version := range strings.Split(row.Version, ",") {
			if version = strings.TrimSpace(version); version != "" {
				versions[key][version] = true
			}
		}
		if result[position].Purpose == "" && row.Purpose != "" {
			result[position].Purpose = row.Purpose
		}
		if result[position].APIRole == "" && row.APIRole != "" {
			result[position].APIRole = row.APIRole
		}
	}
	for key, position := range positions {
		values := make([]string, 0, len(versions[key]))
		for version := range versions[key] {
			values = append(values, version)
		}
		sort.Strings(values)
		result[position].Version = strings.Join(values, ", ")
	}
	return result
}

func crdAPIRole(group string) string {
	normalized := strings.ToLower(strings.TrimSpace(group))
	switch {
	case normalized == "":
		return "Unknown"
	case strings.HasPrefix(normalized, "config."):
		return "Configuration API"
	case strings.HasPrefix(normalized, "visibility."):
		return "Visibility API"
	default:
		return "Core API"
	}
}

func dedupe[T any](items []T, key func(T) string) []T {
	seen := map[string]bool{}
	result := make([]T, 0, len(items))
	for _, item := range items {
		identity := key(item)
		if seen[identity] {
			continue
		}
		seen[identity] = true
		result = append(result, item)
	}
	return result
}

func dedupePrefer[T any](items []T, key func(T) string, quality func(T) int) []T {
	positions := map[string]int{}
	result := make([]T, 0, len(items))
	for _, item := range items {
		identity := key(item)
		position, exists := positions[identity]
		if !exists {
			positions[identity] = len(result)
			result = append(result, item)
			continue
		}
		if quality(item) >= quality(result[position]) {
			result[position] = item
		}
	}
	return result
}

func mergeClusterRoleRows(items []model.ClusterRoleRow) []model.ClusterRoleRow {
	positions := map[string]int{}
	result := make([]model.ClusterRoleRow, 0, len(items))
	for _, item := range items {
		key := item.Name + "\x00" + item.APIGroup + "\x00" + item.Verbs
		position, exists := positions[key]
		if !exists {
			positions[key] = len(result)
			result = append(result, item)
			continue
		}
		resources := append(
			strings.Split(result[position].Resources, ", "),
			strings.Split(item.Resources, ", ")...,
		)
		result[position].Resources = strings.Join(unique(resources), ", ")
	}
	return result
}

func mergeArchitectureComponents(items []model.ArchitectureComponent) []model.ArchitectureComponent {
	type aggregate struct {
		types    []string
		purposes []string
	}
	byName := map[string]*aggregate{}
	var order []string
	for _, item := range items {
		entry := byName[item.Component]
		if entry == nil {
			entry = &aggregate{}
			byName[item.Component] = entry
			order = append(order, item.Component)
		}
		entry.types = append(entry.types, item.Type)
		entry.purposes = append(entry.purposes, item.Purpose)
	}
	result := make([]model.ArchitectureComponent, 0, len(order))
	for _, name := range order {
		entry := byName[name]
		result = append(result, model.ArchitectureComponent{
			Component: name,
			Type:      strings.Join(unique(entry.types), ", "),
			Purpose:   strings.Join(unique(entry.purposes), "; "),
		})
	}
	return result
}

func factQuality(values ...string) int {
	score := 0
	for _, value := range values {
		normalized := strings.ToLower(strings.TrimSpace(value))
		if normalized == "" || normalized == "unknown" || strings.Contains(value, "<") {
			continue
		}
		score++
	}
	return score
}

type sourceEntry struct {
	lines    map[string]bool
	sections map[string]bool
}

type sourceIndex struct {
	items map[string]*sourceEntry
}

func newSourceIndex() *sourceIndex {
	return &sourceIndex{items: map[string]*sourceEntry{}}
}

func (index *sourceIndex) add(raw, section string) {
	file, line := splitSource(raw)
	index.addWithLine(file, parseLine(line), section)
}

func (index *sourceIndex) addWithLine(file string, line int, section string) {
	file = strings.TrimSpace(file)
	if file == "" {
		return
	}
	entry := index.items[file]
	if entry == nil {
		entry = &sourceEntry{lines: map[string]bool{}, sections: map[string]bool{}}
		index.items[file] = entry
	}
	if line > 0 {
		entry.lines[strconv.Itoa(line)] = true
	}
	for _, part := range strings.Split(section, ",") {
		if part = strings.TrimSpace(part); part != "" {
			entry.sections[part] = true
		}
	}
}

func (index *sourceIndex) rows() []model.SourceRow {
	rows := make([]model.SourceRow, 0, len(index.items))
	for file, entry := range index.items {
		var lines, sections []string
		for line := range entry.lines {
			lines = append(lines, line)
		}
		for section := range entry.sections {
			sections = append(sections, section)
		}
		sort.Strings(lines)
		sort.Strings(sections)
		rows = append(rows, model.SourceRow{File: file, Lines: valueOr(strings.Join(lines, ", "), "Unknown"), Sections: strings.Join(sections, ", ")})
	}
	sort.Slice(rows, func(i, j int) bool { return rows[i].File < rows[j].File })
	return rows
}

func splitSource(source string) (string, string) {
	position := strings.LastIndex(source, ":")
	if position < 0 {
		return source, ""
	}
	if _, err := strconv.Atoi(source[position+1:]); err != nil {
		return source, ""
	}
	return source[:position], source[position+1:]
}

func parseLine(line string) int {
	value, _ := strconv.Atoi(line)
	return value
}
