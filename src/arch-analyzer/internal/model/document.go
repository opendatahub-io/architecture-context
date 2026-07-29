package model

type Document struct {
	Component              string
	Metadata               Metadata
	Purpose                string
	ArchitectureComponents []ArchitectureComponent
	CRDs                   []CRDRow
	ServingRuntimes        []ServingRuntimeRow
	HTTPEndpoints          []HTTPEndpointRow
	GRPCServices           []GRPCServiceRow
	ExternalDependencies   []ExternalDependencyRow
	InternalDependencies   []InternalDependencyRow
	Services               []ServiceRow
	Ingress                []IngressRow
	Egress                 []EgressRow
	ClusterRoles           []ClusterRoleRow
	RoleBindings           []RoleBindingRow
	Secrets                []SecretRow
	Authentication         []AuthenticationRow
	SecurityEvidence       []SecurityEvidence
	Webhooks               []WebhookRow
	IntegrationPoints      []IntegrationPointRow
	RecentChanges          []RecentChange
	Sources                []SourceRow
	DataCoverage           map[string]string
	CategoryCoverage       map[string]CategoryCoverage
	CrossReferences        []CrossReference
	CoverageFindings       []CoverageFinding
	SynthesisEvidence      map[string][]EvidenceRecord
	CrossCuttingEvidence   map[string][]CrossCuttingEvidence
	Contract               *ContextContract
}

type Metadata struct {
	Repository     string
	Version        string
	Distribution   string
	Languages      string
	DeploymentType string
	GeneratedBy    string
}

type ArchitectureComponent struct {
	Component string
	Type      string
	Purpose   string
}

type CRDRow struct {
	Group   string
	Version string
	Kind    string
	Scope   string
	Purpose string
}

type ServingRuntimeRow struct {
	Name                  string
	Kind                  string
	APIGroup              string
	Version               string
	Scope                 string
	SupportedModelFormats string
	ContainerImages       string
	BuiltInAdapter        string
	Source                string
}

type HTTPEndpointRow struct {
	Path       string
	Method     string
	Port       string
	Protocol   string
	Transport  string
	Encryption string
	Auth       string
	Owner      string
	Purpose    string
}

type GRPCServiceRow struct {
	Service    string
	Port       string
	Protocol   string
	Transport  string
	Encryption string
	Auth       string
	Owner      string
	Purpose    string
}

type ExternalDependencyRow struct {
	Component string
	Version   string
	Required  string
	Role      string
	Purpose   string
}

type InternalDependencyRow struct {
	Component       string
	InteractionType string
	Role            string
	Purpose         string
}

type ServiceRow struct {
	Name       string
	Type       string
	Port       string
	TargetPort string
	Protocol   string
	Encryption string
	Auth       string
	Exposure   string
}

type IngressRow struct {
	Name       string
	Type       string
	Hosts      string
	Port       string
	Protocol   string
	Encryption string
	TLSMode    string
	Exposure   string
}

type EgressRow struct {
	Destination string
	Port        string
	Protocol    string
	Encryption  string
	Auth        string
	Purpose     string
}

type ClusterRoleRow struct {
	Name      string
	APIGroup  string
	Resources string
	Verbs     string
}

type RoleBindingRow struct {
	Name           string
	Namespace      string
	Role           string
	ServiceAccount string
}

type SecretRow struct {
	Name          string
	Type          string
	Purpose       string
	ProvisionedBy string
	AutoRotate    string
}

type AuthenticationRow struct {
	Endpoint         string
	Methods          string
	Mechanism        string
	EnforcementPoint string
	Policy           string
}

type WebhookRow struct {
	Name          string
	Type          string
	Path          string
	Port          string
	FailurePolicy string
	Resources     string
	Operations    string
	Purpose       string
}

type IntegrationPointRow struct {
	Component       string
	InteractionType string
	Role            string
	Port            string
	Protocol        string
	Encryption      string
	Purpose         string
}

type SourceRow struct {
	File     string
	Lines    string
	Sections string
}
