package pythonsource

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var protoPackage = regexp.MustCompile(`(?m)^\s*package\s+([A-Za-z_][A-Za-z0-9_.]*)\s*;`)
var protoService = regexp.MustCompile(`(?m)^\s*service\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{`)
var protoRPC = regexp.MustCompile(`(?m)^\s*rpc\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(`)

func extractProtoServices(root string, enabled bool) ([]model.GRPCService, error) {
	if !enabled {
		return nil, nil
	}
	var result []model.GRPCService
	err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			if path != root && ignoredDirectory(entry.Name()) {
				return filepath.SkipDir
			}
			return nil
		}
		if !strings.HasSuffix(strings.ToLower(entry.Name()), ".proto") {
			return nil
		}
		contentBytes, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		content := string(contentBytes)
		packageName := ""
		if match := protoPackage.FindStringSubmatch(content); len(match) > 1 {
			packageName = match[1] + "."
		}
		relative, _ := filepath.Rel(root, path)
		source := filepath.ToSlash(relative)
		for _, serviceMatch := range protoService.FindAllStringSubmatchIndex(content, -1) {
			serviceName := content[serviceMatch[2]:serviceMatch[3]]
			opening := serviceMatch[1] - 1
			closing := matchingBrace(content, opening)
			if closing < 0 {
				continue
			}
			body := content[opening+1 : closing]
			rpcs := protoRPC.FindAllStringSubmatch(body, -1)
			if len(rpcs) == 0 {
				result = append(result, model.GRPCService{
					Service: packageName + serviceName, Protocol: "gRPC",
					Purpose: "Protocol buffer service", Source: sourceRef(source, content, serviceName),
				})
				continue
			}
			for _, rpc := range rpcs {
				result = append(result, model.GRPCService{
					Service: packageName + serviceName + "/" + rpc[1], Protocol: "gRPC",
					Purpose: "Protocol buffer RPC " + rpc[1], Source: sourceRef(source, content, rpc[0]),
				})
			}
		}
		return nil
	})
	if err != nil {
		return nil, fmt.Errorf("extract protobuf services: %w", err)
	}
	seen := map[string]bool{}
	filtered := result[:0]
	for _, item := range result {
		if seen[item.Service] {
			continue
		}
		seen[item.Service] = true
		filtered = append(filtered, item)
	}
	sort.Slice(filtered, func(i, j int) bool { return filtered[i].Service < filtered[j].Service })
	return filtered, nil
}

func matchingBrace(content string, opening int) int {
	depth := 0
	for index := opening; index < len(content); index++ {
		switch content[index] {
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return index
			}
		}
	}
	return -1
}
