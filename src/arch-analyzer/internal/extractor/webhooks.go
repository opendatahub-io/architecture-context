package extractor

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"gopkg.in/yaml.v3"
)

var kubebuilderWebhookMarker = regexp.MustCompile(`\+kubebuilder:webhook:([^\n]+)`)
var kubebuilderWebhookField = regexp.MustCompile(`(\w+)=([^,]+)`)

// discoverSourceWebhooks finds deterministic webhook declarations that are not
// necessarily rendered into a WebhookConfiguration manifest. It intentionally
// reports only literal kubebuilder markers and CRD conversion declarations;
// dynamic registration remains an explicit coverage limitation.
func discoverSourceWebhooks(root string, component string) ([]model.Webhook, string) {
	var result []model.Webhook
	seen := map[string]bool{}
	walkErr := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if entry.IsDir() {
			if path != root && ignoredWebhookDirectory(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if ignoredWebhookFile(path) {
			return nil
		}
		relative, relErr := filepath.Rel(root, path)
		if relErr != nil {
			return nil
		}
		switch strings.ToLower(filepath.Ext(path)) {
		case ".go":
			result = append(result, parseKubebuilderWebhooks(path, relative, component, seen)...)
		case ".yaml", ".yml":
			result = append(result, parseConversionWebhooks(path, relative, component, seen)...)
		}
		return nil
	})
	if walkErr != nil {
		return result, fmt.Sprintf("partial: source walk failed: %v", walkErr)
	}
	sort.SliceStable(result, func(i, j int) bool {
		if result[i].Sources[0].File == result[j].Sources[0].File {
			return result[i].Sources[0].Line < result[j].Sources[0].Line
		}
		return result[i].Sources[0].File < result[j].Sources[0].File
	})
	return result, "partial: literal kubebuilder markers and CRD conversion declarations only; dynamic webhook registration not resolved"
}

func ignoredWebhookDirectory(name string) bool {
	switch name {
	case ".git", "vendor", "test", "tests", "install", "prefetched-manifests":
		return true
	default:
		return false
	}
}

func ignoredWebhookFile(path string) bool {
	return strings.HasSuffix(path, "_test.go")
}

func parseKubebuilderWebhooks(path, relative, component string, seen map[string]bool) []model.Webhook {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	var result []model.Webhook
	for lineNumber, line := range strings.Split(string(content), "\n") {
		match := kubebuilderWebhookMarker.FindStringSubmatch(line)
		if len(match) != 2 {
			continue
		}
		fields := parseWebhookMarkerFields(match[1])
		pathValue := fields["path"]
		if pathValue == "" {
			continue
		}
		mutating := strings.EqualFold(fields["mutating"], "true")
		webhookType := "validating"
		if mutating {
			webhookType = "mutating"
		}
		name := fields["name"]
		if name == "" {
			name = fmt.Sprintf("%s:%d", relative, lineNumber+1)
		}
		key := component + "\x00" + name + "\x00" + pathValue
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, model.Webhook{
			Name:          name,
			Type:          webhookType,
			Path:          pathValue,
			FailurePolicy: fields["failurePolicy"],
			Rules:         markerWebhookRules(fields),
			Sources: []model.WebhookSource{{
				Type: "kubebuilder_marker", File: filepath.ToSlash(relative), Line: lineNumber + 1,
			}},
		})
	}
	return result
}

func parseWebhookMarkerFields(value string) map[string]string {
	result := map[string]string{}
	for _, match := range kubebuilderWebhookField.FindAllStringSubmatch(value, -1) {
		result[match[1]] = strings.TrimSpace(match[2])
	}
	return result
}

func markerWebhookRules(fields map[string]string) []model.WebhookRule {
	groups := splitWebhookField(fields["groups"])
	versions := splitWebhookField(fields["versions"])
	resources := splitWebhookField(fields["resources"])
	operations := splitWebhookField(fields["verbs"])
	for i := range operations {
		operations[i] = strings.ToUpper(operations[i])
	}
	if len(resources) == 0 {
		return nil
	}
	return []model.WebhookRule{{
		APIGroups: groups, APIVersions: versions, Resources: resources, Operations: operations,
	}}
}

func splitWebhookField(value string) []string {
	if value == "" {
		return nil
	}
	parts := strings.Split(value, ";")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		if trimmed := strings.TrimSpace(part); trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

type conversionWebhookDocument struct {
	Kind     string `yaml:"kind"`
	Metadata struct {
		Name string `yaml:"name"`
	} `yaml:"metadata"`
	Spec struct {
		Conversion struct {
			Strategy string `yaml:"strategy"`
			Webhook  struct {
				ClientConfig struct {
					Service struct {
						Name string `yaml:"name"`
						Path string `yaml:"path"`
					} `yaml:"service"`
				} `yaml:"clientConfig"`
				ConversionReviewVersions []string `yaml:"conversionReviewVersions"`
			} `yaml:"webhook"`
		} `yaml:"conversion"`
	} `yaml:"spec"`
}

func parseConversionWebhooks(path, relative, component string, seen map[string]bool) []model.Webhook {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil
	}
	decoder := yaml.NewDecoder(strings.NewReader(string(content)))
	var result []model.Webhook
	for document := 1; ; document++ {
		var parsed conversionWebhookDocument
		if err := decoder.Decode(&parsed); err != nil {
			break
		}
		if parsed.Kind != "CustomResourceDefinition" || parsed.Spec.Conversion.Strategy != "Webhook" {
			continue
		}
		name := parsed.Metadata.Name
		if name == "" {
			continue
		}
		pathValue := parsed.Spec.Conversion.Webhook.ClientConfig.Service.Path
		if pathValue == "" {
			pathValue = "/convert"
		}
		key := component + "\x00conversion." + name + "\x00" + pathValue
		if seen[key] {
			continue
		}
		seen[key] = true
		parts := strings.SplitN(name, ".", 2)
		resource, group := parts[0], ""
		if len(parts) == 2 {
			group = parts[1]
		}
		result = append(result, model.Webhook{
			Name: name, Type: "conversion", Path: pathValue,
			Rules: []model.WebhookRule{{
				APIGroups: []string{group}, APIVersions: parsed.Spec.Conversion.Webhook.ConversionReviewVersions,
				Resources: []string{resource}, Operations: []string{"CONVERT"},
			}},
			Sources: []model.WebhookSource{{Type: "crd_conversion", File: filepath.ToSlash(relative), Line: yamlSourceLine(string(content), document)}},
		})
	}
	return result
}

func mergeSourceWebhooks(existing, discovered []model.Webhook) []model.Webhook {
	byName := map[string]int{}
	byPath := map[string]int{}
	for index, webhook := range existing {
		if webhook.Name != "" {
			byName[webhook.Name] = index
		}
		if webhook.Path != "" {
			byPath[webhook.Path] = index
		}
	}
	for _, webhook := range discovered {
		index, found := byName[webhook.Name]
		if !found && webhook.Path != "" {
			index, found = byPath[webhook.Path]
		}
		if found {
			existing[index].Sources = mergeWebhookSources(existing[index].Sources, webhook.Sources)
			if len(existing[index].Rules) == 0 {
				existing[index].Rules = webhook.Rules
			}
			continue
		}
		index = len(existing)
		existing = append(existing, webhook)
		if webhook.Name != "" {
			byName[webhook.Name] = index
		}
		if webhook.Path != "" {
			byPath[webhook.Path] = index
		}
	}
	return existing
}

func mergeWebhookSources(existing, discovered []model.WebhookSource) []model.WebhookSource {
	result := append([]model.WebhookSource{}, existing...)
	seen := map[string]bool{}
	for _, source := range result {
		seen[fmt.Sprintf("%s:%d", source.File, source.Line)] = true
	}
	for _, source := range discovered {
		key := fmt.Sprintf("%s:%d", source.File, source.Line)
		if !seen[key] {
			result = append(result, source)
			seen[key] = true
		}
	}
	return result
}

func yamlSourceLine(content string, document int) int {
	lines := strings.Split(content, "\n")
	seen := 0
	for index, line := range lines {
		if strings.TrimSpace(line) == "---" {
			seen++
		}
		if seen+1 == document && strings.TrimSpace(line) == "kind: CustomResourceDefinition" {
			return index + 1
		}
	}
	return 1
}
