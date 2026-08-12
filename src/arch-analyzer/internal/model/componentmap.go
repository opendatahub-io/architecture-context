package model

// ComponentMap represents the component-map.json structure used by the pipeline.
type ComponentMap struct {
	Components map[string]ComponentEntry `json:"components"`
	Provenance *ComponentMapProvenance   `json:"provenance,omitempty"`
}

type ComponentEntry struct {
	RepoOrg  string `json:"repo_org"`
	RepoName string `json:"repo_name"`
	RepoURL  string `json:"repo_url"`
}

type ComponentMapProvenance struct {
	Repos map[string]ComponentMapRepo `json:"repos"`
}

type ComponentMapRepo struct {
	Org                 string   `json:"org"`
	Repo                string   `json:"repo"`
	IsFork              bool     `json:"is_fork"`
	Upstream            string   `json:"upstream"`
	UpstreamDetection   string   `json:"upstream_detection"`
	Downstream          []string `json:"downstream"`
	DownstreamDetection string   `json:"downstream_detection"`
	SyncMechanism       string   `json:"sync_mechanism"`
	SyncWorkflows       []string `json:"sync_workflows"`
	SyncBranch          string   `json:"sync_branch"`
}
