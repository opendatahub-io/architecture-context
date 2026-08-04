package pythonsource

import (
	"regexp"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var pySDKConstructorRe = regexp.MustCompile(
	`\b((?:openai\.)?(?:AsyncAzureOpenAI|AzureOpenAI|AsyncOpenAI|OpenAI)` +
		`|(?:anthropic\.)?(?:AsyncAnthropic|Anthropic)` +
		`|WatsonxLLM)\s*\(`)

var pySDKCredentialRe = regexp.MustCompile(
	`(?:api_key|credentials)\s*=\s*os\.(?:environ\.get|environ\[|getenv)\s*\(\s*["']([A-Za-z_][A-Za-z0-9_]*)["']`)

func extractSDKClientConnections(relative, content string) []model.ExternalConnection {
	var connections []model.ExternalConnection
	for _, match := range pySDKConstructorRe.FindAllStringSubmatchIndex(content, -1) {
		constructorName := content[match[2]:match[3]]
		argRegion := extractArgRegion(content, match[1], 500)
		credMatch := pySDKCredentialRe.FindStringSubmatch(argRegion)
		if credMatch == nil {
			continue
		}
		envVar := credMatch[1]
		service := sdkServiceName(constructorName)
		connections = append(connections, model.ExternalConnection{
			Type:       "SDK client",
			Service:    service,
			Target:     service,
			Protocol:   "HTTPS",
			Encryption: "TLS",
			Auth:       "API key (" + envVar + ")",
			Port:       "443",
			Source:     sourceRef(relative, content, content[match[0]:match[1]]),
			Function:   "Outbound SDK client construction",
		})
	}
	return connections
}

func extractArgRegion(content string, start, maxLen int) string {
	if start >= len(content) {
		return ""
	}
	depth := 1
	end := start
	for end < len(content) && end-start < maxLen {
		switch content[end] {
		case '(':
			depth++
		case ')':
			depth--
			if depth == 0 {
				return content[start:end]
			}
		}
		end++
	}
	return content[start:end]
}

func sdkServiceName(constructor string) string {
	if idx := strings.LastIndex(constructor, "."); idx >= 0 {
		constructor = constructor[idx+1:]
	}
	switch {
	case strings.Contains(constructor, "AzureOpenAI"):
		return "Azure OpenAI"
	case strings.Contains(constructor, "OpenAI"):
		return "OpenAI"
	case strings.Contains(constructor, "Anthropic"):
		return "Anthropic"
	case strings.Contains(constructor, "Watsonx"):
		return "IBM Watsonx"
	default:
		return constructor
	}
}
