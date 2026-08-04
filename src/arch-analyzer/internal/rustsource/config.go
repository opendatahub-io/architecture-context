package rustsource

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
	"gopkg.in/yaml.v3"
)

func extractConfiguredConnections(root string) (
	[]model.ExternalConnection,
	[]model.InternalDependency,
	error,
) {
	path := filepath.Join(root, "config", "config.yaml")
	content, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil, nil
	}
	if err != nil {
		return nil, nil, fmt.Errorf("read Rust service config: %w", err)
	}
	var document yaml.Node
	if err := yaml.NewDecoder(strings.NewReader(string(content))).Decode(&document); err != nil && !errors.Is(err, io.EOF) {
		return nil, nil, fmt.Errorf("parse Rust service config: %w", err)
	}
	if len(document.Content) == 0 {
		return nil, nil, nil
	}
	relative, _ := filepath.Rel(root, path)
	sourcePath := filepath.ToSlash(relative)
	rootNode := document.Content[0]
	var connections []model.ExternalConnection

	if generation := mappingValue(rootNode, "generation"); generation != nil {
		provider := scalarValue(mappingValue(generation, "provider"))
		name := "Generation service"
		if strings.EqualFold(provider, "tgis") {
			name = "TGIS generation service"
		} else if strings.EqualFold(provider, "nlp") {
			name = "caikit-nlp service"
		}
		if service := mappingValue(generation, "service"); service != nil {
			connections = append(connections, connectionFromService(name, "gRPC client", "gRPC", service, sourcePath))
		}
	}
	if openAI := mappingValue(rootNode, "openai"); openAI != nil {
		if service := mappingValue(openAI, "service"); service != nil {
			connections = append(connections, connectionFromService(
				"OpenAI-compatible service", "REST API client", "HTTP/HTTPS", service, sourcePath,
			))
		}
	}
	if chunkers := mappingValue(rootNode, "chunkers"); chunkers != nil {
		for _, item := range mappingEntries(chunkers) {
			if service := mappingValue(item.value, "service"); service != nil {
				connections = append(connections, connectionFromService(
					"Chunker services", "gRPC client", "gRPC", service, sourcePath,
				))
			}
		}
	}
	if detectors := mappingValue(rootNode, "detectors"); detectors != nil {
		for _, item := range mappingEntries(detectors) {
			if service := mappingValue(item.value, "service"); service != nil {
				connections = append(connections, connectionFromService(
					"Detector services", "REST API client", "HTTP/HTTPS", service, sourcePath,
				))
			}
			if service := mappingValue(item.value, "health_service"); service != nil {
				connections = append(connections, connectionFromService(
					"Detector health services", "REST health client", "HTTP/HTTPS", service, sourcePath,
				))
			}
		}
	}
	connections = dedupeConnections(connections)
	internal := make([]model.InternalDependency, 0, len(connections))
	for _, connection := range connections {
		internal = append(internal, model.InternalDependency{
			Component: connection.Target, Interaction: connection.Type, Purpose: connection.Function,
		})
	}
	return connections, internal, nil
}

func connectionFromService(name, connectionType, protocol string, service *yaml.Node, sourcePath string) model.ExternalConnection {
	portNode := mappingValue(service, "port")
	var port any
	if portNode != nil {
		if err := portNode.Decode(&port); err != nil {
			port = portNode.Value
		}
	}
	encryption := "None"
	if mappingValue(service, "tls") != nil {
		encryption = "TLS (optional, configurable)"
	}
	auth := "None"
	if name == "Detector services" || name == "OpenAI-compatible service" {
		auth = "Bearer token (optional)"
	}
	return model.ExternalConnection{
		Type: connectionType, Target: name, Protocol: protocol, Port: port,
		Encryption: encryption, Auth: auth,
		Source:   fmt.Sprintf("%s:%d", sourcePath, service.Line),
		Function: "Configured downstream " + strings.ToLower(connectionType),
	}
}

type mappingEntry struct {
	key   string
	value *yaml.Node
}

func mappingEntries(node *yaml.Node) []mappingEntry {
	if node == nil || node.Kind != yaml.MappingNode {
		return nil
	}
	entries := make([]mappingEntry, 0, len(node.Content)/2)
	for index := 0; index+1 < len(node.Content); index += 2 {
		entries = append(entries, mappingEntry{key: node.Content[index].Value, value: node.Content[index+1]})
	}
	return entries
}

func mappingValue(node *yaml.Node, key string) *yaml.Node {
	for _, entry := range mappingEntries(node) {
		if entry.key == key {
			return entry.value
		}
	}
	return nil
}

func scalarValue(node *yaml.Node) string {
	if node == nil {
		return ""
	}
	return node.Value
}

func dedupeConnections(connections []model.ExternalConnection) []model.ExternalConnection {
	seen := map[string]bool{}
	result := make([]model.ExternalConnection, 0, len(connections))
	for _, connection := range connections {
		key := connection.Target + "\x00" + fmt.Sprint(connection.Port)
		if !seen[key] {
			seen[key] = true
			result = append(result, connection)
		}
	}
	sort.Slice(result, func(i, j int) bool { return result[i].Target < result[j].Target })
	return result
}
