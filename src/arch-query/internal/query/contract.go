package query

const ContractVersion = "v1"

type Status string

const (
	StatusOK           Status = "ok"
	StatusUnknown      Status = "unknown"
	StatusNotExtracted Status = "not-extracted"
)

type Response struct {
	ContractVersion string         `json:"contract_version"`
	Query           string         `json:"query"`
	Args            map[string]any `json:"args"`
	Version         string         `json:"version,omitempty"`
	Status          Status         `json:"status"`
	Reason          string         `json:"reason,omitempty"`
	Evidence        []Evidence     `json:"evidence,omitempty"`
	Result          any            `json:"result"`
}

type Evidence struct {
	Source      string `json:"source"`
	Category   string `json:"category,omitempty"`
	Confidence string `json:"confidence,omitempty"`
}

func NotExtractedResponse(queryName string, args map[string]any, version, reason string) *Response {
	return &Response{
		ContractVersion: ContractVersion,
		Query:           queryName,
		Args:            args,
		Version:         version,
		Status:          StatusNotExtracted,
		Reason:          reason,
		Result:          nil,
	}
}

func UnknownResponse(queryName string, args map[string]any, version, reason string) *Response {
	return &Response{
		ContractVersion: ContractVersion,
		Query:           queryName,
		Args:            args,
		Version:         version,
		Status:          StatusUnknown,
		Reason:          reason,
		Result:          nil,
	}
}
