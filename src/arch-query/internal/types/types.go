package types

type ComponentDoc struct {
	Name     string            `json:"name"`
	FileName string            `json:"file_name"`
	Metadata map[string]string `json:"metadata,omitempty"`

	Repository string `json:"repository,omitempty"`
	Branch     string `json:"branch,omitempty"`
	Version    string `json:"version,omitempty"`
	Languages  string `json:"languages,omitempty"`
	DeployType string `json:"deploy_type,omitempty"`

	Purpose     string `json:"purpose,omitempty"`
	PurposeFull string `json:"purpose_full,omitempty"`

	Components   []ArchComponent `json:"components,omitempty"`
	CRDs         []CRD           `json:"crds,omitempty"`
	Endpoints    []Endpoint      `json:"endpoints,omitempty"`
	GRPCServices []GRPCService   `json:"grpc_services,omitempty"`
	ExternalDeps []Dependency    `json:"external_deps,omitempty"`
	InternalDeps []Dependency    `json:"internal_deps,omitempty"`
	Services     []Service       `json:"services,omitempty"`
	Ingresses    []Ingress       `json:"ingresses,omitempty"`
	Egresses     []Egress        `json:"egresses,omitempty"`
	RBACRoles    []RBACRole      `json:"rbac_roles,omitempty"`

	ControllerWatches []ControllerWatch `json:"controller_watches,omitempty"`
	Webhooks          []Webhook         `json:"webhooks,omitempty"`
	PlatformWebhooks  []WebhookRef      `json:"platform_webhooks,omitempty"`
	ExternalWebhooks  []WebhookRef      `json:"external_webhooks,omitempty"`
	NetworkPolicies   []NetworkPolicy   `json:"network_policies,omitempty"`
	Dockerfiles       []Dockerfile      `json:"dockerfiles,omitempty"`

	CommitSHA       string `json:"commit_sha,omitempty"`
	AnalyzerVersion string `json:"analyzer_version,omitempty"`

	RawSections map[string]string `json:"-"`
}

type ArchComponent struct {
	Name    string `json:"name"`
	Type    string `json:"type"`
	Purpose string `json:"purpose"`
}

type CRD struct {
	Group   string `json:"group"`
	Version string `json:"version"`
	Kind    string `json:"kind"`
	Scope   string `json:"scope"`
	Purpose string `json:"purpose,omitempty"`
	Source  string `json:"source,omitempty"`
}

type Endpoint struct {
	Path       string `json:"path"`
	Method     string `json:"method"`
	Port       string `json:"port"`
	Protocol   string `json:"protocol"`
	Encryption string `json:"encryption"`
	Auth       string `json:"auth"`
	Purpose    string `json:"purpose"`
}

type GRPCService struct {
	Service    string `json:"service"`
	Port       string `json:"port"`
	Protocol   string `json:"protocol"`
	Encryption string `json:"encryption"`
	Auth       string `json:"auth"`
	Purpose    string `json:"purpose"`
}

type Dependency struct {
	Component       string `json:"component"`
	Version         string `json:"version,omitempty"`
	Required        string `json:"required,omitempty"`
	Purpose         string `json:"purpose"`
	InteractionType string `json:"interaction_type,omitempty"`
}

type Service struct {
	Name       string `json:"name"`
	Type       string `json:"type"`
	Port       string `json:"port"`
	TargetPort string `json:"target_port"`
	Protocol   string `json:"protocol"`
	Encryption string `json:"encryption"`
	Auth       string `json:"auth"`
	Exposure   string `json:"exposure"`
}

type Ingress struct {
	Component  string `json:"component"`
	Type       string `json:"type"`
	Hosts      string `json:"hosts"`
	Port       string `json:"port"`
	Protocol   string `json:"protocol"`
	Encryption string `json:"encryption"`
	TLSMode    string `json:"tls_mode"`
	Exposure   string `json:"exposure"`
}

type Egress struct {
	Destination string `json:"destination"`
	Port        string `json:"port"`
	Protocol    string `json:"protocol"`
	Encryption  string `json:"encryption"`
	Auth        string `json:"auth"`
	Purpose     string `json:"purpose"`
}

type RBACRole struct {
	RoleName  string `json:"role_name"`
	APIGroup  string `json:"api_group"`
	Resources string `json:"resources"`
	Verbs     string `json:"verbs"`
}

type ControllerWatch struct {
	Type       string `json:"type"`
	GVK        string `json:"gvk"`
	Controller string `json:"controller"`
	Source     string `json:"source,omitempty"`
}

type WebhookRule struct {
	APIGroups   []string `json:"apiGroups"`
	APIVersions []string `json:"apiVersions"`
	Resources   []string `json:"resources"`
	Operations  []string `json:"operations"`
}

type WebhookSource struct {
	Type string `json:"type"`
	File string `json:"file"`
	Repo string `json:"repo,omitempty"`
	Line int    `json:"line,omitempty"`
	Note string `json:"note,omitempty"`
}

type WebhookDataRead struct {
	Kind  string `json:"kind"`
	Group string `json:"group,omitempty"`
	Usage string `json:"usage,omitempty"`
}

type Webhook struct {
	Name          string          `json:"name"`
	Type          string          `json:"type"`
	ServiceRef    string          `json:"service_ref,omitempty"`
	Path          string          `json:"path"`
	Port          int             `json:"port,omitempty"`
	FailurePolicy string          `json:"failure_policy,omitempty"`
	SideEffects   string          `json:"side_effects,omitempty"`
	Rules         []WebhookRule   `json:"rules,omitempty"`
	Sources       []WebhookSource `json:"sources,omitempty"`

	Overlays             []string          `json:"overlays,omitempty"`
	EnableCondition      string            `json:"enable_condition,omitempty"`
	Purpose              string            `json:"purpose,omitempty"`
	DataRead             []WebhookDataRead `json:"data_read,omitempty"`
	CrossCuttingConcerns []string          `json:"cross_cutting_concerns,omitempty"`
}

type WebhookRef struct {
	Component string `json:"component"`
	Webhook   string `json:"webhook"`
}

type NetworkPolicy struct {
	Name        string            `json:"name"`
	Source      string            `json:"source,omitempty"`
	PodSelector map[string]string `json:"pod_selector,omitempty"`
	PolicyTypes []string          `json:"policy_types,omitempty"`
}

type Dockerfile struct {
	Path         string   `json:"path"`
	BaseImage    string   `json:"base_image"`
	Stages       int      `json:"stages"`
	User         string   `json:"user,omitempty"`
	ExposedPorts []int    `json:"exposed_ports,omitempty"`
	Issues       []string `json:"issues,omitempty"`
}

type PlatformComponent struct {
	Name       string `json:"name"`
	Type       string `json:"type"`
	Language   string `json:"language"`
	Repository string `json:"repository"`
	Version    string `json:"version"`
	Purpose    string `json:"purpose"`
}

type PlatformDoc struct {
	Metadata   map[string]string   `json:"metadata,omitempty"`
	Overview   string              `json:"overview,omitempty"`
	Components []PlatformComponent `json:"components,omitempty"`
}

type ContainerImage struct {
	Name          string `json:"name"`
	Repository    string `json:"repository"`
	ProductionRef string `json:"production_ref,omitempty"`
	StagingRef    string `json:"staging_ref,omitempty"`
	SourceRepo    string `json:"source_repo,omitempty"`
	SourceCommit  string `json:"source_commit,omitempty"`
	Category      string `json:"category"`
}

type BuildInfo struct {
	ProductVersion         string            `json:"product_version"`
	SupportedOCPVersions   []string          `json:"supported_ocp_versions,omitempty"`
	SupportedArchitectures []string          `json:"supported_architectures,omitempty"`
	MinKubeVersion         string            `json:"min_kube_version,omitempty"`
	OperatorFeatures       map[string]string `json:"operator_features,omitempty"`
	Images                 []ContainerImage  `json:"images,omitempty"`
}

type OverlayDoc struct {
	ID           string   `yaml:"id" json:"id"`
	Title        string   `yaml:"title" json:"title"`
	Status       string   `yaml:"status" json:"status"`
	Created      string   `yaml:"created" json:"created,omitempty"`
	Affects      []string `yaml:"affects" json:"affects,omitempty"`
	Release      []string `yaml:"release" json:"release,omitempty"`
	Provenance   []string `yaml:"provenance" json:"provenance,omitempty"`
	Author       string   `yaml:"author" json:"author,omitempty"`
	SupersededBy *string  `yaml:"superseded_by" json:"superseded_by,omitempty"`

	Fact    string `json:"fact,omitempty"`
	Impact  string `json:"impact,omitempty"`
	Context string `json:"context,omitempty"`
}

type VersionInfo struct {
	Name           string   `json:"name"`
	Path           string   `json:"path"`
	IsSymlink      bool     `json:"is_symlink"`
	SymlinkTarget  string   `json:"symlink_target,omitempty"`
	Aliases        []string `json:"aliases,omitempty"`
	ComponentCount int      `json:"component_count"`
}

type VersionData struct {
	Version    VersionInfo              `json:"version"`
	Components map[string]*ComponentDoc `json:"components,omitempty"`
	Platform   *PlatformDoc             `json:"platform,omitempty"`
	Overlays   []*OverlayDoc            `json:"overlays,omitempty"`
	BuildInfo  *BuildInfo               `json:"build_info,omitempty"`
	Provenance *Provenance              `json:"provenance,omitempty"`
}

type ProvenanceRepo struct {
	Org                 string   `json:"org"`
	Repo                string   `json:"repo"`
	IsFork              bool     `json:"is_fork"`
	Upstream            string   `json:"upstream"`
	UpstreamDetection   string   `json:"upstream_detection"`
	Downstream          []string `json:"downstream"`
	DownstreamDetection string   `json:"downstream_detection"`
	SyncMechanism       string   `json:"sync_mechanism"`
	SyncBranch          string   `json:"sync_branch,omitempty"`
	SyncWorkflows       []string `json:"sync_workflows"`
}

type ProvenanceMetadata struct {
	GeneratedAt         string   `json:"generated_at"`
	CheckoutsDirs       []string `json:"checkouts_dirs"`
	GitHubAPIAvailable  bool     `json:"github_api_available"`
	TotalRepos          int      `json:"total_repos"`
	ReposWithUpstream   int      `json:"repos_with_upstream"`
	ReposWithDownstream int      `json:"repos_with_downstream"`
}

type Provenance struct {
	Metadata ProvenanceMetadata        `json:"metadata"`
	Repos    map[string]ProvenanceRepo `json:"repos"`
}
