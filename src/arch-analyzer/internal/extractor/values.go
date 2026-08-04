package extractor

import (
	"fmt"
)

func mapValue(data map[string]any, keys ...string) map[string]any {
	current := data
	for _, key := range keys {
		value, ok := current[key].(map[string]any)
		if !ok {
			return nil
		}
		current = value
	}
	return current
}

func sliceValue(data map[string]any, keys ...string) []any {
	if len(keys) == 0 {
		return nil
	}
	parent := data
	if len(keys) > 1 {
		parent = mapValue(data, keys[:len(keys)-1]...)
	}
	if parent == nil {
		return nil
	}
	value, _ := parent[keys[len(keys)-1]].([]any)
	return value
}

func stringValue(data map[string]any, key string) string {
	value, ok := data[key]
	if !ok || value == nil {
		return ""
	}
	return fmt.Sprint(value)
}

func nestedString(data map[string]any, keys ...string) string {
	if len(keys) == 0 {
		return ""
	}
	parent := data
	if len(keys) > 1 {
		parent = mapValue(data, keys[:len(keys)-1]...)
	}
	if parent == nil {
		return ""
	}
	return stringValue(parent, keys[len(keys)-1])
}

func stringsValue(value any) []string {
	raw, ok := value.([]any)
	if !ok {
		return nil
	}
	result := make([]string, 0, len(raw))
	for _, item := range raw {
		result = append(result, fmt.Sprint(item))
	}
	return result
}

func source(object object) string {
	if object.line <= 0 {
		return object.source
	}
	return fmt.Sprintf("%s:%d", object.source, object.line)
}

func appendUnique(values []string, additions ...string) []string {
	seen := make(map[string]bool, len(values)+len(additions))
	for _, value := range values {
		seen[value] = true
	}
	for _, value := range additions {
		if value != "" && !seen[value] {
			values = append(values, value)
			seen[value] = true
		}
	}
	return values
}
