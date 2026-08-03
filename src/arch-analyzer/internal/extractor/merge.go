package extractor

import "fmt"

func mergePatches(objects, patches []object) []object {
	for _, patch := range patches {
		matched := false
		for index := range objects {
			if objectKey(objects[index].data) != objectKey(patch.data) {
				continue
			}
			if stringValue(patch.data, "$patch") == "delete" {
				objects = append(objects[:index], objects[index+1:]...)
				matched = true
				break
			}
			objects[index].data = mergeMap(objects[index].data, patch.data)
			objects[index].source = patch.source
			objects[index].line = patch.line
			objects[index].node = patch.node
			matched = true
			break
		}
		if !matched && stringValue(patch.data, "$patch") != "delete" {
			objects = append(objects, patch)
		}
	}
	return objects
}

func mergeMap(base, patch map[string]any) map[string]any {
	result := cloneMap(base)
	for key, patchValue := range patch {
		baseMap, baseOK := result[key].(map[string]any)
		patchMap, patchOK := patchValue.(map[string]any)
		if baseOK && patchOK {
			result[key] = mergeMap(baseMap, patchMap)
			continue
		}
		baseSlice, baseOK := result[key].([]any)
		patchSlice, patchOK := patchValue.([]any)
		if baseOK && patchOK {
			result[key] = mergeNamedSlice(baseSlice, patchSlice)
			continue
		}
		result[key] = patchValue
	}
	return result
}

func mergeNamedSlice(base, patch []any) []any {
	result := append([]any{}, base...)
	for _, patchItem := range patch {
		patchMap, ok := patchItem.(map[string]any)
		name := ""
		if ok {
			name = stringValue(patchMap, "name")
		}
		if name == "" {
			return patch
		}
		matched := false
		for index, baseItem := range result {
			baseMap, ok := baseItem.(map[string]any)
			if ok && stringValue(baseMap, "name") == name {
				result[index] = mergeMap(baseMap, patchMap)
				matched = true
				break
			}
		}
		if !matched {
			result = append(result, patchItem)
		}
	}
	return result
}

func cloneMap(value map[string]any) map[string]any {
	result := make(map[string]any, len(value))
	for key, item := range value {
		result[key] = item
	}
	return result
}

func objectKey(data map[string]any) string {
	return fmt.Sprintf("%s/%s", stringValue(data, "kind"), nestedString(data, "metadata", "name"))
}

func applyTransforms(objects []object, prefix, suffix, namespace string) {
	nameMap := make(map[string]string, len(objects))
	for index := range objects {
		if name := nestedString(objects[index].data, "metadata", "name"); name != "" {
			nameMap[name] = prefix + name + suffix
		}
	}
	for index := range objects {
		metadata := mapValue(objects[index].data, "metadata")
		if metadata == nil {
			continue
		}
		if name := stringValue(metadata, "name"); name != "" {
			metadata["name"] = prefix + name + suffix
		}
		if namespace != "" && stringValue(metadata, "namespace") == "" && namespacedKind(stringValue(objects[index].data, "kind")) {
			metadata["namespace"] = namespace
		}
		rewriteNameReferences(objects[index].data, nameMap)
	}
}

func rewriteNameReferences(data map[string]any, names map[string]string) {
	rewriteNestedName(data, names, "roleRef", "name")
	rewriteNestedName(data, names, "spec", "template", "spec", "serviceAccountName")
	for _, rawSubject := range sliceValue(data, "subjects") {
		if subject, ok := rawSubject.(map[string]any); ok && stringValue(subject, "kind") == "ServiceAccount" {
			rewriteNestedName(subject, names, "name")
		}
	}

	switch stringValue(data, "kind") {
	case "Ingress":
		for _, rawRule := range sliceValue(data, "spec", "rules") {
			rule, _ := rawRule.(map[string]any)
			for _, rawPath := range sliceValue(rule, "http", "paths") {
				path, _ := rawPath.(map[string]any)
				rewriteNestedName(path, names, "backend", "service", "name")
			}
		}
	case "Route":
		rewriteNestedName(data, names, "spec", "to", "name")
	case "HTTPRoute":
		for _, rawRule := range sliceValue(data, "spec", "rules") {
			rule, _ := rawRule.(map[string]any)
			for _, rawBackend := range sliceValue(rule, "backendRefs") {
				if backend, ok := rawBackend.(map[string]any); ok {
					rewriteNestedName(backend, names, "name")
				}
			}
		}
	case "MutatingWebhookConfiguration", "ValidatingWebhookConfiguration":
		for _, rawWebhook := range sliceValue(data, "webhooks") {
			if webhook, ok := rawWebhook.(map[string]any); ok {
				rewriteNestedName(webhook, names, "clientConfig", "service", "name")
			}
		}
	}
}

func rewriteNestedName(data map[string]any, names map[string]string, keys ...string) {
	if len(keys) == 0 {
		return
	}
	parent := data
	if len(keys) > 1 {
		parent = mapValue(data, keys[:len(keys)-1]...)
	}
	if parent == nil {
		return
	}
	key := keys[len(keys)-1]
	current := stringValue(parent, key)
	if replacement, ok := names[current]; ok {
		parent[key] = replacement
	}
}

func namespacedKind(kind string) bool {
	switch kind {
	case "Namespace", "Node", "PersistentVolume", "CustomResourceDefinition", "ClusterRole", "ClusterRoleBinding", "MutatingWebhookConfiguration", "ValidatingWebhookConfiguration", "APIService", "ClusterServingRuntime":
		return false
	default:
		return true
	}
}
