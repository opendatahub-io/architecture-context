package extractor

import (
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func collectCRD(item object, input *model.Input) {
	spec := mapValue(item.data, "spec")
	version := ""
	for _, raw := range sliceValue(spec, "versions") {
		candidate, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		if version == "" || candidate["storage"] == true {
			version = stringValue(candidate, "name")
		}
		if candidate["storage"] == true {
			break
		}
	}
	if version == "" {
		version = stringValue(spec, "version")
	}
	crd := model.CRD{
		Group:   stringValue(spec, "group"),
		Version: version,
		Kind:    nestedString(spec, "names", "kind"),
		Scope:   stringValue(spec, "scope"),
		Source:  source(item),
	}
	if !validCRD(crd) {
		return
	}
	input.CRDs = append(input.CRDs, crd)
	input.FieldProjections = append(input.FieldProjections, collectCRDFieldProjections(item, crd)...)
	input.ManagedComponents = append(input.ManagedComponents, collectManagedComponentContracts(item, crd)...)
}

func collectWorkload(item object, input *model.Input, secrets map[string]*model.Secret) {
	podSpec := mapValue(item.data, "spec", "template", "spec")
	workloadName := nestedString(item.data, "metadata", "name")
	workload := model.Deployment{
		Name:           workloadName,
		Kind:           stringValue(item.data, "kind"),
		Source:         source(item),
		ServiceAccount: stringValue(podSpec, "serviceAccountName"),
	}
	for _, raw := range sliceValue(podSpec, "containers") {
		containerData, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		container := model.Container{
			Name: stringValue(containerData, "name"), Image: stringValue(containerData, "image"),
			Args: stringsValue(containerData["args"]),
		}
		for _, rawPort := range sliceValue(containerData, "ports") {
			port, ok := rawPort.(map[string]any)
			if !ok {
				continue
			}
			container.Ports = append(container.Ports, model.ContainerPort{
				Name:          stringValue(port, "name"),
				ContainerPort: intValue(port["containerPort"]),
				Protocol:      defaultString(stringValue(port, "protocol"), "TCP"),
			})
		}
		for _, rawFrom := range sliceValue(containerData, "envFrom") {
			from, ok := rawFrom.(map[string]any)
			if !ok {
				continue
			}
			if name := nestedString(from, "secretRef", "name"); name != "" {
				container.EnvFromSecrets = appendUnique(container.EnvFromSecrets, name)
				referenceSecret(secrets, name, workloadName+"/"+container.Name, source(item))
			}
			if name := nestedString(from, "configMapRef", "name"); name != "" {
				container.EnvFromConfigMaps = appendUnique(container.EnvFromConfigMaps, name)
			}
		}
		for _, rawEnv := range sliceValue(containerData, "env") {
			env, ok := rawEnv.(map[string]any)
			if !ok {
				continue
			}
			if name := nestedString(env, "valueFrom", "secretKeyRef", "name"); name != "" {
				container.EnvFromSecrets = appendUnique(container.EnvFromSecrets, name)
				referenceSecret(secrets, name, workloadName+"/"+container.Name, source(item))
			}
		}
		container.LivenessProbe = collectProbe(mapValue(containerData, "livenessProbe"))
		container.ReadinessProbe = collectProbe(mapValue(containerData, "readinessProbe"))
		workload.Containers = append(workload.Containers, container)
	}
	for _, rawVolume := range sliceValue(podSpec, "volumes") {
		volume, ok := rawVolume.(map[string]any)
		if !ok {
			continue
		}
		if name := nestedString(volume, "secret", "secretName"); name != "" {
			referenceSecret(secrets, name, workloadName, source(item))
		}
	}
	input.Deployments = append(input.Deployments, workload)
}

func collectProbe(data map[string]any) *model.Probe {
	if data == nil {
		return nil
	}
	if probe := mapValue(data, "httpGet"); probe != nil {
		result := &model.Probe{Type: "httpGet", Path: stringValue(probe, "path"), Port: probe["port"]}
		for _, raw := range sliceValue(probe, "httpHeaders") {
			header, ok := raw.(map[string]any)
			if ok {
				result.Headers = append(result.Headers, model.HTTPHeader{
					Name: stringValue(header, "name"), Value: stringValue(header, "value"),
				})
			}
		}
		return result
	}
	if probe := mapValue(data, "tcpSocket"); probe != nil {
		return &model.Probe{Type: "tcpSocket", Port: probe["port"]}
	}
	if mapValue(data, "exec") != nil {
		return &model.Probe{Type: "exec"}
	}
	return nil
}

var policyExclusionPattern = regexp.MustCompile(`request\.path\s*!=\s*["']([^"']+)["']\s*\|\|\s*request\.method\s*!=\s*["']([^"']+)["']`)

func collectAccessPolicy(item object) model.AccessPolicy {
	spec := mapValue(item.data, "spec")
	policy := model.AccessPolicy{
		Name: nestedString(item.data, "metadata", "name"), Kind: "Kuadrant AuthPolicy",
		TargetKind: nestedString(spec, "targetRef", "kind"),
		TargetName: nestedString(spec, "targetRef", "name"), Source: source(item),
	}
	rules := mapValue(spec, "rules")
	if len(rules) == 0 {
		rules = mapValue(spec, "defaults", "rules")
	}
	policy.Authentication = accessPolicyAuthentication(mapValue(rules, "authentication"))
	for name := range mapValue(rules, "authorization") {
		policy.Authorization = append(policy.Authorization, name)
	}
	sort.Strings(policy.Authorization)
	policy.Exclusions = append(policy.Exclusions, accessPolicyExclusions(sliceValue(spec, "when"))...)
	policy.Exclusions = append(policy.Exclusions, accessPolicyExclusions(sliceValue(spec, "defaults", "when"))...)
	return policy
}

func accessPolicyAuthentication(authentication map[string]any) []string {
	mechanisms := map[string]bool{}
	for name, raw := range authentication {
		if strings.Contains(strings.ToLower(name), "api-key") {
			mechanisms["API key"] = true
		}
		walkPolicyValue(raw, func(key string) {
			switch key {
			case "kubernetesTokenReview":
				mechanisms["Kubernetes TokenReview"] = true
			case "jwt":
				mechanisms["OIDC JWT"] = true
			}
		})
	}
	result := make([]string, 0, len(mechanisms))
	for mechanism := range mechanisms {
		result = append(result, mechanism)
	}
	sort.Strings(result)
	return result
}

func walkPolicyValue(value any, visit func(string)) {
	switch typed := value.(type) {
	case map[string]any:
		for key, nested := range typed {
			visit(key)
			walkPolicyValue(nested, visit)
		}
	case []any:
		for _, nested := range typed {
			walkPolicyValue(nested, visit)
		}
	}
}

func accessPolicyExclusions(conditions []any) []model.PolicyExclusion {
	var result []model.PolicyExclusion
	for _, raw := range conditions {
		condition, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		matches := policyExclusionPattern.FindStringSubmatch(stringValue(condition, "predicate"))
		if len(matches) == 3 {
			result = append(result, model.PolicyExclusion{Path: matches[1], Methods: strings.ToUpper(matches[2])})
		}
	}
	return result
}

func collectService(item object, objects []object, input *model.Input, secrets map[string]*model.Secret) {
	spec := mapValue(item.data, "spec")
	service := model.Service{
		Name:             nestedString(item.data, "metadata", "name"),
		Source:           source(item),
		Type:             defaultString(stringValue(spec, "type"), "ClusterIP"),
		TargetDeployment: targetWorkload(spec, objects),
	}
	for _, raw := range sliceValue(spec, "ports") {
		port, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		targetPort := port["targetPort"]
		if targetPort == nil {
			targetPort = port["port"]
		}
		service.Ports = append(service.Ports, model.ServicePort{
			Name:        stringValue(port, "name"),
			Port:        port["port"],
			TargetPort:  targetPort,
			Protocol:    defaultString(stringValue(port, "protocol"), "TCP"),
			AppProtocol: stringValue(port, "appProtocol"),
		})
	}
	input.Services = append(input.Services, service)
	if nestedString(item.data, "metadata", "annotations", "prometheus.io/scrape") == "true" {
		port := nestedString(item.data, "metadata", "annotations", "prometheus.io/port")
		path := nestedString(item.data, "metadata", "annotations", "prometheus.io/path")
		purpose := "Metrics collection via prometheus.io/scrape annotation"
		if path != "" {
			purpose += " at " + path
		}
		var portValue any
		if port != "" {
			portValue = port
		}
		input.IntegrationPoints = append(input.IntegrationPoints, model.IntegrationFact{
			Component: "Prometheus", InteractionType: "Inbound scrape",
			Port: portValue, Protocol: "HTTP", Purpose: purpose, Source: source(item),
		})
		input.Dependencies.Internal = append(input.Dependencies.Internal, model.InternalDependency{
			Component: "Prometheus", Interaction: "monitoring",
			Purpose: "Metrics scraping via service annotations", Source: source(item),
		})
	}
	if name := nestedString(item.data, "metadata", "annotations", "service.beta.openshift.io/serving-cert-secret-name"); name != "" {
		secret, exists := secrets[name]
		if !exists {
			secret = &model.Secret{Name: name}
			secrets[name] = secret
		}
		secret.Type = "kubernetes.io/tls"
		secret.ProvisionedBy = "OpenShift service-ca operator"
		secret.Source = source(item)
		secret.ReferencedBy = appendUnique(secret.ReferencedBy, service.Name)
	}
}

func targetWorkload(serviceSpec map[string]any, objects []object) string {
	selector := mapValue(serviceSpec, "selector")
	if len(selector) == 0 {
		return ""
	}
	for _, candidate := range objects {
		kind := stringValue(candidate.data, "kind")
		if kind != "Deployment" && kind != "StatefulSet" && kind != "DaemonSet" {
			continue
		}
		labels := mapValue(candidate.data, "spec", "template", "metadata", "labels")
		matches := true
		for key, value := range selector {
			if fmt.Sprint(labels[key]) != fmt.Sprint(value) {
				matches = false
				break
			}
		}
		if matches {
			return nestedString(candidate.data, "metadata", "name")
		}
	}
	return ""
}

func collectRole(item object) model.Role {
	role := model.Role{
		Name:   nestedString(item.data, "metadata", "name"),
		Labels: stringMap(mapValue(item.data, "metadata", "labels")),
		Source: source(item),
	}
	for _, raw := range sliceValue(item.data, "rules") {
		rule, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		role.Rules = append(role.Rules, model.RoleRule{
			APIGroups:     stringsValue(rule["apiGroups"]),
			Resources:     stringsValue(rule["resources"]),
			ResourceNames: stringsValue(rule["resourceNames"]),
			Verbs:         stringsValue(rule["verbs"]),
		})
	}
	return role
}

func stringMap(data map[string]any) map[string]string {
	if len(data) == 0 {
		return nil
	}
	result := make(map[string]string, len(data))
	for key, value := range data {
		result[key] = fmt.Sprint(value)
	}
	return result
}

func collectBinding(item object) model.Binding {
	binding := model.Binding{
		Name:      nestedString(item.data, "metadata", "name"),
		Namespace: nestedString(item.data, "metadata", "namespace"),
		RoleRef:   nestedString(item.data, "roleRef", "name"),
		RoleKind:  nestedString(item.data, "roleRef", "kind"),
		Source:    source(item),
	}
	for _, raw := range sliceValue(item.data, "subjects") {
		subject, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		binding.Subjects = append(binding.Subjects, model.Subject{
			Kind:      stringValue(subject, "kind"),
			Name:      stringValue(subject, "name"),
			Namespace: stringValue(subject, "namespace"),
		})
	}
	return binding
}

func collectConfigMapAnnotations(item object, input *model.Input) {
	if nestedString(item.data, "metadata", "annotations", "service.beta.openshift.io/inject-cabundle") == "true" {
		input.Dependencies.Internal = append(input.Dependencies.Internal, model.InternalDependency{
			Component: "OpenShift Service CA", Interaction: "CA bundle injection",
			Purpose:   "TLS certificate trust via service-ca operator annotation",
			Source:    source(item),
		})
	}
}

func referenceSecret(secrets map[string]*model.Secret, name, referencedBy, evidence string) {
	secret, ok := secrets[name]
	if !ok {
		secret = &model.Secret{Name: name, Type: "referenced", Source: evidence}
		secrets[name] = secret
	}
	secret.ReferencedBy = appendUnique(secret.ReferencedBy, referencedBy)
}

func collectDeclaredSecret(item object, secrets map[string]*model.Secret) {
	name := nestedString(item.data, "metadata", "name")
	secret, ok := secrets[name]
	if !ok {
		secret = &model.Secret{Name: name}
		secrets[name] = secret
	}
	secret.Type = defaultString(stringValue(item.data, "type"), "Opaque")
	secret.ProvisionedBy = "manifest"
	secret.Source = source(item)
}

func collectIngress(item object) model.Ingress {
	kind := stringValue(item.data, "kind")
	result := model.Ingress{Kind: kind, Name: nestedString(item.data, "metadata", "name"), Source: source(item)}
	spec := mapValue(item.data, "spec")
	switch kind {
	case "Ingress":
		result.TLS = len(sliceValue(spec, "tls")) > 0
		result.Protocol = "HTTP"
		if result.TLS {
			result.Protocol = "HTTPS"
		}
		for _, rawRule := range sliceValue(spec, "rules") {
			rule, _ := rawRule.(map[string]any)
			if result.Host == "" {
				result.Host = stringValue(rule, "host")
			}
			for _, rawPath := range sliceValue(rule, "http", "paths") {
				path, _ := rawPath.(map[string]any)
				result.Paths = appendUnique(result.Paths, stringValue(path, "path"))
				if result.Backend == "" {
					result.Backend = nestedString(path, "backend", "service", "name")
				}
			}
		}
	case "Route":
		result.Host = stringValue(spec, "host")
		result.Backend = nestedString(spec, "to", "name")
		result.TLS = mapValue(spec, "tls") != nil
		result.Protocol = "HTTP"
		if result.TLS {
			result.Protocol = "HTTPS"
		}
	case "HTTPRoute":
		result.Protocol = "Unknown"
		hostnames := stringsValue(spec["hostnames"])
		if len(hostnames) > 0 {
			result.Host = hostnames[0]
		}
		for _, rawRule := range sliceValue(spec, "rules") {
			rule, _ := rawRule.(map[string]any)
			for _, rawMatch := range sliceValue(rule, "matches") {
				match, _ := rawMatch.(map[string]any)
				result.Paths = appendUnique(result.Paths, nestedString(match, "path", "value"))
			}
			for _, rawBackend := range sliceValue(rule, "backendRefs") {
				backend, _ := rawBackend.(map[string]any)
				if result.Backend == "" {
					result.Backend = stringValue(backend, "name")
				}
			}
		}
	case "Gateway":
		result.Protocol = "Unknown"
		for _, rawListener := range sliceValue(spec, "listeners") {
			listener, _ := rawListener.(map[string]any)
			if result.Host == "" {
				result.Host = stringValue(listener, "hostname")
			}
			if strings.EqualFold(stringValue(listener, "protocol"), "HTTPS") || strings.EqualFold(stringValue(listener, "protocol"), "TLS") {
				result.TLS = true
				result.Protocol = strings.ToUpper(stringValue(listener, "protocol"))
			}
		}
	}
	return result
}

func collectWebhooks(item object, input *model.Input) {
	webhookType := strings.TrimSuffix(stringValue(item.data, "kind"), "WebhookConfiguration")
	for _, raw := range sliceValue(item.data, "webhooks") {
		data, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		webhook := model.Webhook{
			Name:          stringValue(data, "name"),
			Type:          webhookType,
			FailurePolicy: stringValue(data, "failurePolicy"),
			ServiceRef:    nestedString(data, "clientConfig", "service", "name"),
			Path:          nestedString(data, "clientConfig", "service", "path"),
			Port:          valueAt(data, "clientConfig", "service", "port"),
			Sources:       []model.WebhookSource{{Type: "manifest", File: item.source, Line: item.line}},
		}
		for _, rawRule := range sliceValue(data, "rules") {
			rule, _ := rawRule.(map[string]any)
			webhook.Rules = append(webhook.Rules, model.WebhookRule{
				APIGroups:   stringsValue(rule["apiGroups"]),
				APIVersions: stringsValue(rule["apiVersions"]),
				Resources:   stringsValue(rule["resources"]),
				Operations:  stringsValue(rule["operations"]),
			})
		}
		input.Webhooks = append(input.Webhooks, webhook)
	}
}

func valueAt(data map[string]any, keys ...string) any {
	if len(keys) == 0 {
		return nil
	}
	parent := mapValue(data, keys[:len(keys)-1]...)
	if parent == nil {
		return nil
	}
	return parent[keys[len(keys)-1]]
}

func intValue(value any) int {
	switch number := value.(type) {
	case int:
		return number
	case int64:
		return int(number)
	case float64:
		return int(number)
	default:
		return 0
	}
}

func defaultString(value, fallback string) string {
	if value == "" {
		return fallback
	}
	return value
}
