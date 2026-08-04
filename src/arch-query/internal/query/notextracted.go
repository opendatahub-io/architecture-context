package query

import (
	"github.com/jctanner/arch-query/internal/types"
)

func QueryCallersOf(function, pkg, version string, data *types.VersionData) *Response {
	args := map[string]any{
		"function": function,
		"package":  pkg,
	}
	return NotExtractedResponse("callers-of", args, version,
		"source-level call graph is not extracted by the architecture analyzer; "+
			"callers require AST/IR analysis of the component source code")
}

func QueryConsumersOf(typeName, version string, data *types.VersionData) *Response {
	args := map[string]any{
		"type": typeName,
	}
	return NotExtractedResponse("consumers-of", args, version,
		"source-level type consumers are not extracted by the architecture analyzer; "+
			"consumer analysis requires cross-package type reference resolution")
}

func QueryConfigSources(component, version string, data *types.VersionData) *Response {
	args := map[string]any{
		"component": component,
	}

	doc := findComponent(data, component)
	if doc == nil {
		return UnknownResponse("config-sources", args, version,
			"component not found in version "+version)
	}

	return NotExtractedResponse("config-sources", args, version,
		"configuration source mapping (environment variables, ConfigMaps, CLI flags) "+
			"is not extracted by the architecture analyzer; "+
			"config source analysis requires manifest and source code inspection")
}
