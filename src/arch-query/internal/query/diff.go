package query

import (
	"github.com/jctanner/arch-query/internal/diff"
	"github.com/jctanner/arch-query/internal/types"
)

func QueryDiff(component, fromVersion, toVersion string, from, to *types.VersionData) *Response {
	args := map[string]any{
		"component": component,
		"from":      fromVersion,
		"to":        toVersion,
	}

	var result *diff.DiffResult
	if component == "" || component == "platform" {
		result = diff.Compute(fromVersion, toVersion, from, to)
	} else {
		result = diff.ComputeSingle(component, fromVersion, toVersion, from, to)
	}

	status := StatusOK
	var reason string
	switch {
	case result.Status == "incompatible":
		status = StatusNotExtracted
		reason = "neither version contains data"
	case result.Status == "unknown":
		status = StatusUnknown
		reason = "component not found in either version"
	case len(result.Status) > len("not-extracted:") && result.Status[:14] == "not-extracted:":
		status = StatusNotExtracted
		reason = "version data missing for " + result.Status[14:]
	}

	var evidence []Evidence
	if status == StatusOK {
		evidence = append(evidence, Evidence{
			Source:   fromVersion,
			Category: "snapshot",
		})
		evidence = append(evidence, Evidence{
			Source:   toVersion,
			Category: "snapshot",
		})
	}

	return &Response{
		ContractVersion: ContractVersion,
		Query:           "diff",
		Args:            args,
		Version:         fromVersion + ".." + toVersion,
		Status:          status,
		Reason:          reason,
		Evidence:        evidence,
		Result:          result,
	}
}
