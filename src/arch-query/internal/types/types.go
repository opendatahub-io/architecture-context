package types

type ComponentDoc struct {
	Name     string
	FileName string
	Metadata map[string]string

	Repository string
	Version    string
	Languages  string
	DeployType string

	Purpose     string
	PurposeFull string

	Components  []ArchComponent
	CRDs        []CRD
	Endpoints   []Endpoint
	GRPCServices []GRPCService
	ExternalDeps []Dependency
	InternalDeps []Dependency
	Services    []Service
	Ingresses   []Ingress
	Egresses    []Egress
	RBACRoles   []RBACRole

	RawSections map[string]string
}

type ArchComponent struct {
	Name    string
	Type    string
	Purpose string
}

type CRD struct {
	Group   string
	Version string
	Kind    string
	Scope   string
	Purpose string
	Source  string
}

type Endpoint struct {
	Path       string
	Method     string
	Port       string
	Protocol   string
	Encryption string
	Auth       string
	Purpose    string
}

type GRPCService struct {
	Service    string
	Port       string
	Protocol   string
	Encryption string
	Auth       string
	Purpose    string
}

type Dependency struct {
	Component       string
	Version         string
	Required        string
	Purpose         string
	InteractionType string
}

type Service struct {
	Name       string
	Type       string
	Port       string
	TargetPort string
	Protocol   string
	Encryption string
	Auth       string
	Exposure   string
}

type Ingress struct {
	Component  string
	Type       string
	Hosts      string
	Port       string
	Protocol   string
	Encryption string
	TLSMode    string
	Exposure   string
}

type Egress struct {
	Destination string
	Port        string
	Protocol    string
	Encryption  string
	Auth        string
	Purpose     string
}

type RBACRole struct {
	RoleName  string
	APIGroup  string
	Resources string
	Verbs     string
}

type PlatformComponent struct {
	Name       string
	Type       string
	Language   string
	Repository string
	Version    string
	Purpose    string
}

type PlatformDoc struct {
	Metadata map[string]string
	Overview string
	Components []PlatformComponent
}

type OverlayDoc struct {
	ID           string   `yaml:"id"`
	Title        string   `yaml:"title"`
	Status       string   `yaml:"status"`
	Created      string   `yaml:"created"`
	Affects      []string `yaml:"affects"`
	Release      []string `yaml:"release"`
	Provenance   []string `yaml:"provenance"`
	Author       string   `yaml:"author"`
	SupersededBy *string  `yaml:"superseded_by"`

	Fact    string
	Impact  string
	Context string
}

type VersionInfo struct {
	Name           string
	Path           string
	IsSymlink      bool
	SymlinkTarget  string
	Aliases        []string
	ComponentCount int
}

type VersionData struct {
	Version    VersionInfo
	Components map[string]*ComponentDoc
	Platform   *PlatformDoc
	Overlays   []*OverlayDoc
}
