package types

type ComponentDoc struct {
	Name     string            `json:"name"`
	FileName string            `json:"file_name"`
	Metadata map[string]string `json:"metadata,omitempty"`

	Repository string `json:"repository,omitempty"`
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
}
