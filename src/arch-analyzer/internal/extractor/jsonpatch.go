package extractor

import (
	"fmt"
	"strconv"
	"strings"
)

func applyJSONOperation(document map[string]any, operation map[string]any) error {
	op := stringValue(operation, "op")
	path := stringValue(operation, "path")
	if path == "" || !strings.HasPrefix(path, "/") {
		return fmt.Errorf("invalid path %q", path)
	}
	tokens := strings.Split(strings.TrimPrefix(path, "/"), "/")
	for index := range tokens {
		tokens[index] = strings.ReplaceAll(strings.ReplaceAll(tokens[index], "~1", "/"), "~0", "~")
	}
	_, err := mutateJSONValue(document, tokens, op, operation["value"])
	return err
}

func mutateJSONValue(current any, tokens []string, operation string, value any) (any, error) {
	if len(tokens) == 0 {
		return current, fmt.Errorf("cannot patch document root")
	}
	last := len(tokens) == 1
	switch typed := current.(type) {
	case map[string]any:
		key := tokens[0]
		if last {
			switch operation {
			case "add", "replace":
				typed[key] = value
			case "remove":
				delete(typed, key)
			default:
				return current, fmt.Errorf("unsupported operation %q", operation)
			}
			return typed, nil
		}
		next, ok := typed[key]
		if !ok {
			return current, fmt.Errorf("path segment %q does not exist", key)
		}
		updated, err := mutateJSONValue(next, tokens[1:], operation, value)
		if err != nil {
			return current, err
		}
		typed[key] = updated
		return typed, nil
	case []any:
		index, err := jsonPatchIndex(tokens[0], len(typed), operation == "add" && last)
		if err != nil {
			return current, err
		}
		if last {
			switch operation {
			case "add":
				if index == len(typed) {
					typed = append(typed, value)
				} else {
					typed = append(typed[:index], append([]any{value}, typed[index:]...)...)
				}
			case "replace":
				typed[index] = value
			case "remove":
				typed = append(typed[:index], typed[index+1:]...)
			default:
				return current, fmt.Errorf("unsupported operation %q", operation)
			}
			return typed, nil
		}
		updated, err := mutateJSONValue(typed[index], tokens[1:], operation, value)
		if err != nil {
			return current, err
		}
		typed[index] = updated
		return typed, nil
	default:
		return current, fmt.Errorf("path traverses scalar at %q", tokens[0])
	}
}

func jsonPatchIndex(token string, length int, allowEnd bool) (int, error) {
	if token == "-" && allowEnd {
		return length, nil
	}
	index, err := strconv.Atoi(token)
	if err != nil || index < 0 || index >= length {
		return 0, fmt.Errorf("invalid array index %q", token)
	}
	return index, nil
}
