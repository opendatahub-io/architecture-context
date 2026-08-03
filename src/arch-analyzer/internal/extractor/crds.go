package extractor

import (
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"gopkg.in/yaml.v3"
)

var projectedFieldPattern = regexp.MustCompile(`(?i)\bprojected by (?:the )?([^\.\n]+?)(?: from (?:the )?([^\.\n]+))?\.`)
var managedComponentPattern = regexp.MustCompile(`(?i)^\s*[^.\n]+?\s+controls\s+(?:whether\s+)?(?:the\s+)?(.+?)\s+sub-component\b`)

func validCRD(crd model.CRD) bool {
	return strings.TrimSpace(crd.Group) != "" &&
		strings.TrimSpace(crd.Version) != "" &&
		strings.TrimSpace(crd.Kind) != "" &&
		strings.TrimSpace(crd.Scope) != ""
}

func validCRDCount(crds []model.CRD) int {
	count := 0
	for _, crd := range crds {
		if validCRD(crd) {
			count++
		}
	}
	return count
}

func mergeCRDFacts(manifest, source []model.CRD) []model.CRD {
	byIdentity := map[string]model.CRD{}
	for _, facts := range [][]model.CRD{manifest, source} {
		for _, crd := range facts {
			if !validCRD(crd) {
				continue
			}
			identity := crd.Group + "\x00" + crd.Version + "\x00" + crd.Kind
			if _, exists := byIdentity[identity]; !exists {
				byIdentity[identity] = crd
			}
		}
	}
	result := make([]model.CRD, 0, len(byIdentity))
	for _, crd := range byIdentity {
		result = append(result, crd)
	}
	sort.Slice(result, func(i, j int) bool {
		left := result[i].Group + "\x00" + result[i].Kind + "\x00" + result[i].Version
		right := result[j].Group + "\x00" + result[j].Kind + "\x00" + result[j].Version
		return left < right
	})
	return result
}

func collectCRDFieldProjections(item object, crd model.CRD) []model.FieldProjection {
	var result []model.FieldProjection
	spec := mapValue(item.data, "spec")
	for _, rawVersion := range sliceValue(spec, "versions") {
		version, ok := rawVersion.(map[string]any)
		if !ok {
			continue
		}
		schema := mapValue(version, "schema", "openAPIV3Schema")
		result = append(result, projectedSchemaFields(item, crd, schema, "")...)
	}
	if schema := mapValue(spec, "validation", "openAPIV3Schema"); schema != nil {
		result = append(result, projectedSchemaFields(item, crd, schema, "")...)
	}
	return dedupeFieldProjections(result)
}

func collectManagedComponentContracts(item object, crd model.CRD) []model.ManagedComponentContract {
	var result []model.ManagedComponentContract
	spec := mapValue(item.data, "spec")
	for _, rawVersion := range sliceValue(spec, "versions") {
		version, ok := rawVersion.(map[string]any)
		if !ok {
			continue
		}
		schema := mapValue(version, "schema", "openAPIV3Schema")
		result = append(result, managedSchemaFields(item, crd, schema, "")...)
	}
	if schema := mapValue(spec, "validation", "openAPIV3Schema"); schema != nil {
		result = append(result, managedSchemaFields(item, crd, schema, "")...)
	}
	return dedupeManagedComponentContracts(result)
}

func managedSchemaFields(item object, crd model.CRD, schema map[string]any, prefix string) []model.ManagedComponentContract {
	properties := mapValue(schema, "properties")
	keys := make([]string, 0, len(properties))
	for key := range properties {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	var result []model.ManagedComponentContract
	for _, key := range keys {
		property, ok := properties[key].(map[string]any)
		if !ok {
			continue
		}
		field := key
		if prefix != "" {
			field = prefix + "." + key
		}
		state := mapValue(property, "properties", "managementState")
		description := stringValue(property, "description")
		match := managedComponentPattern.FindStringSubmatch(description)
		if len(match) == 2 && enumContains(state, "Managed") && enumContains(state, "Removed") {
			line := yamlMappingValueLine(item.node, "description", description)
			if line <= 0 {
				line = item.line
			}
			result = append(result, model.ManagedComponentContract{
				APIGroup: crd.Group, Kind: crd.Kind,
				Field: field + ".managementState", Component: strings.TrimSpace(match[1]),
				ManagedState: "Managed", RemovedState: "Removed",
				Source: fmt.Sprintf("%s:%d", item.source, line),
			})
		}
		result = append(result, managedSchemaFields(item, crd, property, field)...)
	}
	return result
}

func enumContains(schema map[string]any, value string) bool {
	for _, candidate := range sliceValue(schema, "enum") {
		if strings.EqualFold(fmt.Sprint(candidate), value) {
			return true
		}
	}
	return false
}

func dedupeManagedComponentContracts(contracts []model.ManagedComponentContract) []model.ManagedComponentContract {
	seen := map[string]bool{}
	result := make([]model.ManagedComponentContract, 0, len(contracts))
	for _, contract := range contracts {
		key := contract.APIGroup + "\x00" + contract.Kind + "\x00" + strings.ToLower(contract.Field)
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, contract)
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].APIGroup+result[i].Kind+result[i].Field < result[j].APIGroup+result[j].Kind+result[j].Field
	})
	return result
}

func projectedSchemaFields(item object, crd model.CRD, schema map[string]any, prefix string) []model.FieldProjection {
	properties := mapValue(schema, "properties")
	keys := make([]string, 0, len(properties))
	for key := range properties {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	var result []model.FieldProjection
	for _, key := range keys {
		property, ok := properties[key].(map[string]any)
		if !ok {
			continue
		}
		field := key
		if prefix != "" {
			field = prefix + "." + key
		}
		description := stringValue(property, "description")
		if match := projectedFieldPattern.FindStringSubmatch(description); len(match) == 3 {
			line := yamlMappingValueLine(item.node, "description", description)
			if line <= 0 {
				line = item.line
			}
			result = append(result, model.FieldProjection{
				APIGroup: crd.Group, Kind: crd.Kind, Field: field,
				Projector: strings.TrimSpace(match[1]), UpstreamSource: strings.TrimSpace(match[2]),
				Description: strings.TrimSpace(description),
				Source:      fmt.Sprintf("%s:%d", item.source, line),
			})
		}
		result = append(result, projectedSchemaFields(item, crd, property, field)...)
		if items := mapValue(property, "items"); items != nil {
			result = append(result, projectedSchemaFields(item, crd, items, field+"[]")...)
		}
	}
	return result
}

func yamlMappingValueLine(node *yaml.Node, key, value string) int {
	if node == nil {
		return 0
	}
	if node.Kind == yaml.MappingNode {
		for index := 0; index+1 < len(node.Content); index += 2 {
			name, candidate := node.Content[index], node.Content[index+1]
			if name.Value == key && candidate.Value == value {
				return candidate.Line
			}
			if line := yamlMappingValueLine(candidate, key, value); line > 0 {
				return line
			}
		}
		return 0
	}
	for _, child := range node.Content {
		if line := yamlMappingValueLine(child, key, value); line > 0 {
			return line
		}
	}
	return 0
}

func dedupeFieldProjections(projections []model.FieldProjection) []model.FieldProjection {
	seen := map[string]bool{}
	result := make([]model.FieldProjection, 0, len(projections))
	for _, projection := range projections {
		key := strings.Join([]string{
			projection.APIGroup, projection.Kind, projection.Field,
			strings.ToLower(projection.Projector), strings.ToLower(projection.UpstreamSource),
		}, "\x00")
		if seen[key] {
			continue
		}
		seen[key] = true
		result = append(result, projection)
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].APIGroup+result[i].Kind+result[i].Field < result[j].APIGroup+result[j].Kind+result[j].Field
	})
	return result
}
