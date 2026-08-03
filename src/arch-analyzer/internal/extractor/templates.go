package extractor

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"gopkg.in/yaml.v3"
)

var templateAction = regexp.MustCompile(`{{-?\s*(.*?)\s*-?}}`)
var templateField = regexp.MustCompile(`\.[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+`)
var safeTemplateScalar = regexp.MustCompile(`^[A-Za-z0-9_.+-]+$`)

func extractControllerTemplates(
	root string,
	paths []string,
	defaults map[string]model.SourceDefault,
) (model.Input, map[string]bool, string, error) {
	if len(paths) == 0 {
		return model.Input{}, map[string]bool{}, "not_found", nil
	}

	var objects []object
	usedDefaults := map[string]bool{}
	parseFailures := 0
	for _, path := range paths {
		loaded, err := loadTemplateObjects(root, path, defaults, usedDefaults)
		if err != nil {
			parseFailures++
			continue
		}
		objects = append(objects, loaded...)
	}
	objects = dedupeObjects(objects)
	var facts model.Input
	collect(objects, &facts)
	for index := range facts.Deployments {
		facts.Deployments[index].Kind = "Controller-created " + facts.Deployments[index].Kind
	}
	for index := range facts.Secrets {
		facts.Secrets[index].ProvisionedBy = "controller template"
	}
	for index := range facts.IngressRouting {
		facts.IngressRouting[index].Note = "Controller-created from embedded template"
	}
	coverage := "partial: conditional template branches represented as possible resources"
	if parseFailures > 0 {
		coverage += fmt.Sprintf("; %d controller templates could not be parsed", parseFailures)
	}
	return facts, usedDefaults, coverage, nil
}

func loadTemplateObjects(
	root string,
	path string,
	defaults map[string]model.SourceDefault,
	usedDefaults map[string]bool,
) ([]object, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read controller template %s: %w", path, err)
	}
	sanitized := sanitizeTemplate(stripDefinedTemplateBlocks(string(content)), defaults, usedDefaults)
	decoder := yaml.NewDecoder(strings.NewReader(sanitized))
	var objects []object
	for {
		var node yaml.Node
		err := decoder.Decode(&node)
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("parse sanitized controller template %s: %w", path, err)
		}
		if len(node.Content) == 0 {
			continue
		}
		dedupeYAMLMapping(node.Content[0])
		var data map[string]any
		if err := node.Decode(&data); err != nil {
			return nil, fmt.Errorf("decode controller template %s: %w", path, err)
		}
		if stringValue(data, "kind") == "" {
			continue
		}
		resourceName := "{registry-name}"
		resourceNamespace := "registry namespace"
		if strings.Contains(filepath.ToSlash(path), "/templates/catalog/") {
			resourceName = "model-catalog"
			resourceNamespace = "target namespace"
		}
		normalizeTemplateTokens(data, resourceName, resourceNamespace)
		relative, err := filepath.Rel(root, path)
		if err != nil {
			relative = path
		}
		objects = append(objects, object{
			data:   data,
			source: filepath.ToSlash(relative),
			line:   node.Content[0].Line,
			node:   node.Content[0],
		})
	}
	return objects, nil
}

func stripDefinedTemplateBlocks(content string) string {
	lines := strings.Split(content, "\n")
	depth := 0
	for index, line := range lines {
		insideDefinition := depth > 0
		matches := templateAction.FindAllStringSubmatch(line, -1)
		startsDefinition := false
		for _, match := range matches {
			action := strings.TrimSpace(strings.Trim(match[1], "-"))
			if strings.HasPrefix(action, "define ") || strings.HasPrefix(action, "block ") {
				startsDefinition = true
			}
			if depth > 0 || startsDefinition {
				depth += templateBlockDelta(action)
			}
		}
		if insideDefinition || depth > 0 || startsDefinition {
			lines[index] = ""
		}
	}
	return strings.Join(lines, "\n")
}

func templateBlockDelta(action string) int {
	switch {
	case strings.HasPrefix(action, "define "), strings.HasPrefix(action, "block "),
		strings.HasPrefix(action, "if "), strings.HasPrefix(action, "range "),
		strings.HasPrefix(action, "with "):
		return 1
	case action == "end":
		return -1
	default:
		return 0
	}
}

func dedupeYAMLMapping(node *yaml.Node) {
	if node == nil {
		return
	}
	switch node.Kind {
	case yaml.MappingNode:
		seen := map[string]bool{}
		filtered := make([]*yaml.Node, 0, len(node.Content))
		for index := 0; index+1 < len(node.Content); index += 2 {
			key := node.Content[index]
			value := node.Content[index+1]
			dedupeYAMLMapping(value)
			if seen[key.Value] {
				continue
			}
			seen[key.Value] = true
			filtered = append(filtered, key, value)
		}
		node.Content = filtered
	case yaml.SequenceNode, yaml.DocumentNode:
		for _, child := range node.Content {
			dedupeYAMLMapping(child)
		}
	}
}

func sanitizeTemplate(content string, defaults map[string]model.SourceDefault, usedDefaults map[string]bool) string {
	lines := strings.Split(content, "\n")
	for index, line := range lines {
		trimmed := strings.TrimSpace(line)
		matches := templateAction.FindAllStringSubmatch(trimmed, -1)
		if len(matches) == 1 && matches[0][0] == trimmed && controlTemplateAction(matches[0][1]) {
			lines[index] = ""
			continue
		}
		lines[index] = templateAction.ReplaceAllStringFunc(line, func(action string) string {
			match := templateAction.FindStringSubmatch(action)
			if len(match) < 2 {
				return "ARCH_TEMPLATE_VALUE"
			}
			return templateToken(match[1], defaults, usedDefaults)
		})
	}
	return strings.Join(lines, "\n")
}

func controlTemplateAction(action string) bool {
	action = strings.TrimSpace(strings.Trim(action, "-"))
	for _, prefix := range []string{"if ", "else", "end", "range ", "with ", "define ", "block ", "template "} {
		if strings.HasPrefix(action, prefix) {
			return true
		}
	}
	return strings.HasPrefix(action, "$") && (strings.Contains(action, ":=") || strings.Contains(action, " = "))
}

func templateToken(action string, defaults map[string]model.SourceDefault, usedDefaults map[string]bool) string {
	action = strings.TrimSpace(strings.Trim(action, "-"))
	if value, ok := resolvedTemplateDefault(action, defaults, usedDefaults); ok {
		return value
	}
	switch {
	case controlTemplateAction(action):
		return "ARCH_CONDITIONAL_VALUE"
	case strings.Contains(action, ".HTTPRouteNamespace"):
		return "ARCH_HTTP_ROUTE_NAMESPACE"
	case strings.Contains(action, ".GatewayNamespace"):
		return "ARCH_GATEWAY_NAMESPACE"
	case strings.Contains(action, ".GatewayName"):
		return "ARCH_GATEWAY_NAME"
	case strings.Contains(action, ".Domain"):
		return "ARCH_DOMAIN"
	case strings.Contains(action, ".Namespace"):
		return "ARCH_NAMESPACE"
	case strings.Contains(action, ".Spec.KubeRBACProxy.Port"):
		return "ARCH_PROXY_PORT"
	case strings.Contains(action, ".Spec.Rest.Port"):
		return "ARCH_REST_PORT"
	case strings.Contains(strings.ToLower(action), "image"):
		return "ARCH_IMAGE"
	case action == ".Name":
		return "ARCH_NAME"
	case strings.Contains(action, "$key"):
		return "ARCH_TEMPLATE_KEY"
	default:
		return "ARCH_TEMPLATE_VALUE"
	}
}

func resolvedTemplateDefault(
	action string,
	defaults map[string]model.SourceDefault,
	usedDefaults map[string]bool,
) (string, bool) {
	for _, candidate := range templateField.FindAllString(action, -1) {
		path := strings.TrimPrefix(candidate, ".")
		resolved, ok := defaults[path]
		if !ok || resolved.Value == "" {
			continue
		}
		usedDefaults[path] = true
		if safeTemplateScalar.MatchString(resolved.Value) {
			return resolved.Value, true
		}
		return strconv.Quote(resolved.Value), true
	}
	return "", false
}

func normalizeTemplateTokens(value any, resourceName, resourceNamespace string) any {
	switch typed := value.(type) {
	case map[string]any:
		for key, item := range typed {
			typed[key] = normalizeTemplateTokens(item, resourceName, resourceNamespace)
		}
		return typed
	case []any:
		for index := range typed {
			typed[index] = normalizeTemplateTokens(typed[index], resourceName, resourceNamespace)
		}
		return typed
	case string:
		replacer := strings.NewReplacer(
			"ARCH_HTTP_ROUTE_NAMESPACE", "{http-route-namespace}",
			"ARCH_GATEWAY_NAMESPACE", "{gateway-namespace}",
			"ARCH_GATEWAY_NAME", "{gateway-name}",
			"ARCH_DOMAIN", "{domain}",
			"ARCH_NAMESPACE", resourceNamespace,
			"ARCH_PROXY_PORT", "{proxy-port}",
			"ARCH_REST_PORT", "{rest-port}",
			"ARCH_IMAGE", "{image}",
			"ARCH_NAME", resourceName,
			"ARCH_CONDITIONAL_VALUE", "{conditional}",
			"ARCH_TEMPLATE_VALUE", "{template-value}",
			"ARCH_TEMPLATE_KEY", "{template-key}",
		)
		return replacer.Replace(typed)
	default:
		return value
	}
}
