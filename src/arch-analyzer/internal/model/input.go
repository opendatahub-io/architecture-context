package model

import (
	"encoding/json"
	"fmt"
	"io"
)

// Input is the compatibility representation of component-architecture.json.
// Unknown fields are intentionally ignored so newer extractor output remains usable.
type Input struct {
	Component             string                            `json:"component"`
	Repo                  string                            `json:"repo"`
	CommitSHA             string                            `json:"commit_sha"`
	ExtractedAt           string                            `json:"extracted_at"`
	AnalyzerVersion       string                            `json:"analyzer_version"`
	SchemaVersion         string                            `json:"schema_version"`
	Summary               string                            `json:"summary"`
	SourceComponents      []SourceComponent                 `json:"source_components,omitempty"`
	CRDs                  []CRD                             `json:"crds"`
	ServingRuntimes       []ServingRuntimeDefinition        `json:"serving_runtime_definitions,omitempty"`
	APIReferenceContracts []APIReferenceContract            `json:"api_reference_contracts,omitempty"`
	FieldProjections      []FieldProjection                 `json:"field_projections,omitempty"`
	ManagedComponents     []ManagedComponentContract        `json:"managed_component_contracts,omitempty"`
	Services              []Service                         `json:"services"`
	Deployments           []Deployment                      `json:"deployments"`
	RBAC                  RBAC                              `json:"rbac"`
	Secrets               []Secret                          `json:"secrets_referenced"`
	HTTPEndpoints         []HTTPEndpoint                    `json:"http_endpoints"`
	GRPCServices          []GRPCService                     `json:"grpc_services,omitempty"`
	Dependencies          Dependencies                      `json:"dependencies"`
	ControllerWatches     []ControllerWatch                 `json:"controller_watches"`
	Webhooks              []Webhook                         `json:"webhooks"`
	ExternalWebhooks      []ExternalWebhook                 `json:"external_webhooks"`
	IngressRouting        []Ingress                         `json:"ingress_routing"`
	ExternalConnections   []ExternalConnection              `json:"external_connections"`
	Authentication        []AuthenticationFact              `json:"authentication,omitempty"`
	IntegrationPoints     []IntegrationFact                 `json:"integration_points,omitempty"`
	RecentChanges         []RecentChange                    `json:"recent_changes,omitempty"`
	ComponentRefs         []ComponentRef                    `json:"component_refs"`
	Entrypoints           []Entrypoint                      `json:"entrypoints,omitempty"`
	SecurityEvidence      []SecurityEvidence                `json:"security_evidence,omitempty"`
	Dockerfiles           []Dockerfile                      `json:"dockerfiles"`
	SourceDefaults        []SourceDefault                   `json:"source_defaults,omitempty"`
	RuntimeClients        []RuntimeClient                   `json:"runtime_clients,omitempty"`
	RuntimeModuleUses     []RuntimeModuleUse                `json:"runtime_module_uses,omitempty"`
	RuntimeManagedUses    []RuntimeManagedComponent         `json:"runtime_managed_components,omitempty"`
	RuntimeServers        []RuntimeServer                   `json:"runtime_servers,omitempty"`
	RuntimeSecurity       []RuntimeSecurityControl          `json:"runtime_security_controls,omitempty"`
	RuntimeProxies        []RuntimeProxyControl             `json:"runtime_proxy_controls,omitempty"`
	RuntimeWebhooks       []RuntimeWebhookServer            `json:"runtime_webhook_servers,omitempty"`
	AccessPolicies        []AccessPolicy                    `json:"access_policies,omitempty"`
	DataCoverage          map[string]string                 `json:"data_coverage"`
	CategoryCoverage      map[string]CategoryCoverage       `json:"category_coverage,omitempty"`
	CrossReferences       []CrossReference                  `json:"cross_references,omitempty"`
	CoverageFindings      []CoverageFinding                 `json:"coverage_findings,omitempty"`
	SynthesisEvidence     map[string][]EvidenceRecord       `json:"synthesis_evidence,omitempty"`
	CrossCuttingEvidence  map[string][]CrossCuttingEvidence `json:"cross_cutting_evidence,omitempty"`
	GapEvidenceIndex      map[string][]GapEvidenceCandidate `json:"gap_evidence_index,omitempty"`
	ContextContract       *ContextContract                  `json:"context_contract,omitempty"`
}

// CategoryCoverage records whether a bounded discovery contract completed for one
// normalized architecture category. FactCount is independent of Status: a category
// may contain facts while still being incomplete.
type CategoryCoverage struct {
	Status            string   `json:"status"`
	FactCount         int      `json:"fact_count"`
	DiscoveryContract string   `json:"discovery_contract"`
	CompletedChecks   []string `json:"completed_checks"`
	Limitations       []string `json:"limitations"`
	Evidence          []string `json:"evidence"`
}

// CrossReference is a deterministic relationship derived from two or more
// independently extracted facts. It is evidence, not architectural judgment.
type CrossReference struct {
	Kind         string   `json:"kind"`
	From         string   `json:"from"`
	To           string   `json:"to"`
	Relationship string   `json:"relationship"`
	Details      string   `json:"details,omitempty"`
	Sources      []string `json:"sources"`
}

// CoverageFinding makes a category's empty or unresolved state explicit. An
// empty category is only "confirmed-empty" when its discovery contract is
// complete; otherwise the finding remains "not-verified".
type CoverageFinding struct {
	Category string   `json:"category"`
	Status   string   `json:"status"`
	Finding  string   `json:"finding"`
	Sources  []string `json:"sources,omitempty"`
}

// EvidenceRecord is a compact, source-linked projection for synthesis. The
// complete structured record remains authoritative in the surrounding JSON.
type EvidenceRecord struct {
	Claim   string   `json:"claim"`
	Sources []string `json:"sources"`
}

// CrossCuttingEvidence is a bounded, source-linked fact family retained for
// platform aggregation. Status describes the evidence state; it is not a
// semantic recommendation.
type CrossCuttingEvidence struct {
	Claim   string   `json:"claim"`
	Status  string   `json:"status"`
	Sources []string `json:"sources"`
}

// GapEvidenceCandidate points an agent at a bounded, source-backed location
// that may answer an unresolved synthesis question. A candidate is navigation
// guidance, not proof of the relationship described by the question.
type GapEvidenceCandidate struct {
	Source         string   `json:"source"`
	LineRange      string   `json:"line_range,omitempty"`
	Symbols        []string `json:"symbols,omitempty"`
	Question       string   `json:"question"`
	ExpectedSignal string   `json:"expected_signal"`
	Status         string   `json:"status"`
	Limitations    []string `json:"limitations,omitempty"`
}

type SourceComponent struct {
	Name    string `json:"name"`
	Type    string `json:"type"`
	Purpose string `json:"purpose"`
	Source  string `json:"source"`
}

type SourceDefault struct {
	Path    string   `json:"path"`
	Value   string   `json:"value"`
	Sources []string `json:"sources"`
}

// APIReferenceContract records a typed CRD reference whose default target and
// failure behavior are declared in source. It does not imply that a referenced
// runtime exists; consumers must correlate it with independent runtime evidence.
type APIReferenceContract struct {
	OwnerKind          string   `json:"owner_kind"`
	Field              string   `json:"field"`
	DefaultKind        string   `json:"default_kind,omitempty"`
	FailureModeDefault string   `json:"failure_mode_default,omitempty"`
	FailureModes       []string `json:"failure_modes,omitempty"`
	Source             string   `json:"source"`
}

// RuntimeClient records source-backed construction of a client used by running
// application code. Deployment and credential evidence are modeled separately.
type RuntimeClient struct {
	Target        string `json:"target"`
	Client        string `json:"client"`
	Configuration string `json:"configuration"`
	Source        string `json:"source"`
}

// RuntimeModuleUse records a direct project module imported by non-test,
// non-generated source. A dependency declaration alone is not runtime evidence.
type RuntimeModuleUse struct {
	Module string `json:"module"`
	Source string `json:"source"`
}

// RuntimeServer records a listener whose construction, handler or service
// registration, and runtime lifecycle converge in source.
type RuntimeServer struct {
	Surface   string `json:"surface"`
	Protocol  string `json:"protocol"`
	Lifecycle string `json:"lifecycle"`
	Source    string `json:"source"`
}

// RuntimeSecurityControl records a statically configured runtime enforcement
// control. Manifest evidence determines its deployed address and credentials.
type RuntimeSecurityControl struct {
	Surface                string `json:"surface"`
	AddressFlag            string `json:"address_flag,omitempty"`
	AddressDefault         string `json:"address_default,omitempty"`
	SecureFlag             string `json:"secure_flag,omitempty"`
	SecureDefault          bool   `json:"secure_default"`
	CertificatePathFlag    string `json:"certificate_path_flag,omitempty"`
	CertificatePathDefault string `json:"certificate_path_default,omitempty"`
	CertificateMode        string `json:"certificate_mode,omitempty"`
	Mechanism              string `json:"mechanism"`
	EnforcementPoint       string `json:"enforcement_point"`
	Source                 string `json:"source"`
}

// RuntimeProxyControl records a complete source-constructed kube-rbac-proxy
// enforcement path. Service and RBAC fields are retained independently so the
// semantic pass can reject partial constructions instead of inferring deployment.
type RuntimeProxyControl struct {
	Surface            string `json:"surface"`
	Methods            string `json:"methods"`
	Workload           string `json:"workload"`
	ServiceAccount     string `json:"service_account"`
	ListenPort         int    `json:"listen_port"`
	Upstream           string `json:"upstream"`
	ConfigFile         string `json:"config_file"`
	TLSCertFile        string `json:"tls_cert_file"`
	TLSPrivateKeyFile  string `json:"tls_private_key_file"`
	TLSSecret          string `json:"tls_secret"`
	ServicePort        int    `json:"service_port"`
	ServiceTargetPort  int    `json:"service_target_port"`
	ReviewRole         string `json:"review_role"`
	ReviewBinding      string `json:"review_binding"`
	AuthorizationScope string `json:"authorization_scope,omitempty"`
	Source             string `json:"source"`
}

// RuntimeWebhookServer records explicit controller-runtime webhook server
// construction. Deployment, Service, and certificate correlation remain a
// separate manifest-backed proof.
type RuntimeWebhookServer struct {
	Port        int    `json:"port"`
	Conditional bool   `json:"conditional"`
	Source      string `json:"source"`
}

type AccessPolicy struct {
	Name           string            `json:"name"`
	Kind           string            `json:"kind"`
	TargetKind     string            `json:"target_kind"`
	TargetName     string            `json:"target_name,omitempty"`
	Authentication []string          `json:"authentication"`
	Authorization  []string          `json:"authorization,omitempty"`
	Exclusions     []PolicyExclusion `json:"exclusions,omitempty"`
	Source         string            `json:"source"`
}

type PolicyExclusion struct {
	Path    string `json:"path"`
	Methods string `json:"methods"`
}

type CRD struct {
	Group   string `json:"group"`
	Version string `json:"version"`
	Kind    string `json:"kind"`
	Scope   string `json:"scope"`
	Source  string `json:"source"`
}

// ServingRuntimeDefinition records a source-backed KServe runtime manifest
// shipped by the analyzed repository or selected overlay. It represents
// runtime resource instances, not the CRD schemas that define their API.
type ServingRuntimeDefinition struct {
	Name                  string   `json:"name"`
	Kind                  string   `json:"kind"`
	APIGroup              string   `json:"api_group"`
	Version               string   `json:"version"`
	Scope                 string   `json:"scope"`
	SupportedModelFormats []string `json:"supported_model_formats,omitempty"`
	ContainerImages       []string `json:"container_images,omitempty"`
	BuiltInAdapter        string   `json:"built_in_adapter,omitempty"`
	Source                string   `json:"source"`
}

// FieldProjection records an explicit contract that another control-plane actor
// supplies a CR field. It preserves the schema wording rather than inferring an
// owner from the repository or component name.
type FieldProjection struct {
	APIGroup       string `json:"api_group"`
	Kind           string `json:"kind"`
	Field          string `json:"field"`
	Projector      string `json:"projector"`
	UpstreamSource string `json:"upstream_source,omitempty"`
	Description    string `json:"description"`
	Source         string `json:"source"`
}

// ManagedComponentContract records a CRD field whose schema explicitly controls
// the lifecycle of a named sub-component through Managed and Removed states.
type ManagedComponentContract struct {
	APIGroup     string `json:"api_group"`
	Kind         string `json:"kind"`
	Field        string `json:"field"`
	Component    string `json:"component"`
	ManagedState string `json:"managed_state"`
	RemovedState string `json:"removed_state"`
	Source       string `json:"source"`
}

// RuntimeManagedComponent records a registered reconciliation action that gates
// manifest application on a CR field being in the Managed state.
type RuntimeManagedComponent struct {
	Field     string `json:"field"`
	Action    string `json:"action"`
	Lifecycle string `json:"lifecycle"`
	Source    string `json:"source"`
}

type Service struct {
	Name             string        `json:"name"`
	Source           string        `json:"source"`
	Type             string        `json:"type"`
	Ports            []ServicePort `json:"ports"`
	TargetDeployment string        `json:"target_deployment"`
	Encryption       string        `json:"encryption,omitempty"`
	Auth             string        `json:"auth,omitempty"`
	Exposure         string        `json:"exposure,omitempty"`
}

type ServicePort struct {
	Name        string `json:"name"`
	Port        any    `json:"port"`
	TargetPort  any    `json:"targetPort"`
	Protocol    string `json:"protocol"`
	AppProtocol string `json:"appProtocol,omitempty"`
	Encryption  string `json:"encryption,omitempty"`
	Auth        string `json:"auth,omitempty"`
}

type Deployment struct {
	Name           string      `json:"name"`
	Kind           string      `json:"kind"`
	Source         string      `json:"source"`
	ServiceAccount string      `json:"service_account"`
	Containers     []Container `json:"containers"`
}

type Container struct {
	Name              string          `json:"name"`
	Image             string          `json:"image"`
	Args              []string        `json:"args,omitempty"`
	Ports             []ContainerPort `json:"ports"`
	EnvFromSecrets    []string        `json:"env_from_secrets"`
	EnvFromConfigMaps []string        `json:"env_from_configmaps"`
	LivenessProbe     *Probe          `json:"liveness_probe"`
	ReadinessProbe    *Probe          `json:"readiness_probe"`
}

type ContainerPort struct {
	Name          string `json:"name"`
	ContainerPort int    `json:"containerPort"`
	Protocol      string `json:"protocol"`
}

type Probe struct {
	Type    string       `json:"type"`
	Path    string       `json:"path"`
	Port    any          `json:"port"`
	Headers []HTTPHeader `json:"headers,omitempty"`
}

type HTTPHeader struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

type RBAC struct {
	ClusterRoles        []Role    `json:"cluster_roles"`
	Roles               []Role    `json:"roles"`
	ClusterRoleBindings []Binding `json:"cluster_role_bindings"`
	RoleBindings        []Binding `json:"role_bindings"`
}

type Role struct {
	Name   string            `json:"name"`
	Labels map[string]string `json:"labels,omitempty"`
	Source string            `json:"source"`
	Rules  []RoleRule        `json:"rules"`
}

type RoleRule struct {
	APIGroups     []string `json:"apiGroups"`
	Resources     []string `json:"resources"`
	ResourceNames []string `json:"resourceNames,omitempty"`
	Verbs         []string `json:"verbs"`
}

type Binding struct {
	Name      string    `json:"name"`
	Namespace string    `json:"namespace,omitempty"`
	RoleRef   string    `json:"role_ref"`
	RoleKind  string    `json:"role_kind,omitempty"`
	Subjects  []Subject `json:"subjects"`
	Source    string    `json:"source"`
}

type Subject struct {
	Kind      string `json:"kind"`
	Name      string `json:"name"`
	Namespace string `json:"namespace"`
}

type Secret struct {
	Name          string   `json:"name"`
	Type          string   `json:"type"`
	ReferencedBy  []string `json:"referenced_by"`
	ProvisionedBy string   `json:"provisioned_by"`
	Source        string   `json:"source"`
}

type HTTPEndpoint struct {
	Method      string `json:"method"`
	Path        string `json:"path"`
	Port        any    `json:"port"`
	Protocol    string `json:"protocol"`
	Encryption  string `json:"encryption,omitempty"`
	Auth        string `json:"auth,omitempty"`
	Description string `json:"description"`
	Owner       string `json:"owner,omitempty"`
	Transport   string `json:"transport,omitempty"`
	Source      string `json:"source"`
}

type GRPCService struct {
	Service    string `json:"service"`
	Port       any    `json:"port,omitempty"`
	Protocol   string `json:"protocol"`
	Encryption string `json:"encryption,omitempty"`
	Auth       string `json:"auth,omitempty"`
	Purpose    string `json:"purpose"`
	Owner      string `json:"owner,omitempty"`
	Transport  string `json:"transport,omitempty"`
	Source     string `json:"source"`
	Limitation string `json:"limitation,omitempty"`
}

type Dependencies struct {
	GoVersion string               `json:"go_version"`
	GoModules []GoModule           `json:"go_modules"`
	Packages  []LanguagePackage    `json:"packages,omitempty"`
	Internal  []InternalDependency `json:"internal_odh"`
}

type LanguagePackage struct {
	Name      string `json:"name"`
	Version   string `json:"version"`
	Ecosystem string `json:"ecosystem"`
	Role      string `json:"role,omitempty"`
	Purpose   string `json:"purpose,omitempty"`
	Source    string `json:"source"`
}

type GoModule struct {
	Module   string `json:"module"`
	Version  string `json:"version"`
	Category string `json:"category"`
	Role     string `json:"role,omitempty"`
	Purpose  string `json:"purpose"`
	Source   string `json:"source,omitempty"`
}

type InternalDependency struct {
	Component   string `json:"component"`
	Interaction string `json:"interaction"`
	Role        string `json:"role,omitempty"`
	Purpose     string `json:"purpose"`
	Source      string `json:"source,omitempty"`
}

type ControllerWatch struct {
	Type        string       `json:"type"`
	GVK         string       `json:"gvk"`
	Controller  string       `json:"controller"`
	Source      string       `json:"source"`
	Conditional bool         `json:"conditional,omitempty"`
	Operations  []ResourceOp `json:"resource_ops"`
}

type ResourceOp struct {
	Operation string `json:"operation"`
	Resource  string `json:"resource"`
	Source    string `json:"source"`
}

type Webhook struct {
	Name          string          `json:"name"`
	Type          string          `json:"type"`
	ServiceRef    string          `json:"service_ref"`
	Path          string          `json:"path"`
	Port          any             `json:"port"`
	FailurePolicy string          `json:"failure_policy"`
	Rules         []WebhookRule   `json:"rules"`
	Sources       []WebhookSource `json:"sources"`
	Purpose       string          `json:"purpose"`
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
	Repo string `json:"repo"`
	Line int    `json:"line"`
}

type ExternalWebhook struct {
	Component string `json:"component"`
	Webhook   string `json:"webhook"`
}

type Ingress struct {
	Kind     string   `json:"kind"`
	Name     string   `json:"name"`
	Host     string   `json:"host"`
	Paths    []string `json:"paths"`
	Backend  string   `json:"backend"`
	Protocol string   `json:"protocol,omitempty"`
	TLS      bool     `json:"tls"`
	Source   string   `json:"source"`
	Note     string   `json:"note"`
}

type ExternalConnection struct {
	Type       string `json:"type"`
	Service    string `json:"service"`
	Target     string `json:"target"`
	Protocol   string `json:"protocol"`
	Encryption string `json:"encryption,omitempty"`
	Auth       string `json:"auth,omitempty"`
	Port       any    `json:"port"`
	Source     string `json:"source"`
	Function   string `json:"function"`
}

type AuthenticationFact struct {
	Endpoint         string `json:"endpoint"`
	Methods          string `json:"methods"`
	Mechanism        string `json:"mechanism"`
	EnforcementPoint string `json:"enforcement_point"`
	Policy           string `json:"policy"`
	Source           string `json:"source"`
}

type RecentChange struct {
	Version string `json:"version"`
	Date    string `json:"date"`
	Changes string `json:"changes"`
}

type IntegrationFact struct {
	Component       string `json:"component"`
	InteractionType string `json:"interaction_type"`
	Role            string `json:"role,omitempty"`
	Port            any    `json:"port,omitempty"`
	Protocol        string `json:"protocol,omitempty"`
	Encryption      string `json:"encryption,omitempty"`
	Purpose         string `json:"purpose,omitempty"`
	Source          string `json:"source,omitempty"`
}

type ComponentRef struct {
	Component   string `json:"component"`
	Type        string `json:"type"`
	Reference   string `json:"reference"`
	Source      string `json:"source"`
	Interaction string `json:"interaction"`
}

type Dockerfile struct {
	Path      string   `json:"path"`
	BaseImage string   `json:"base_image"`
	User      string   `json:"user"`
	Issues    []string `json:"issues"`
}

// Entrypoint records a deterministic executable entrypoint discovered from
// Dockerfiles, language main packages, or build scripts. The Runtime field
// identifies the language runtime (Go, Python, Rust, etc.). WorkloadRef links
// to a manifest workload name when the mapping is unambiguous; it is empty
// when the mapping requires agent interpretation.
type Entrypoint struct {
	Name        string `json:"name"`
	Type        string `json:"type"`
	Runtime     string `json:"runtime"`
	Command     string `json:"command,omitempty"`
	WorkloadRef string `json:"workload_ref,omitempty"`
	Source      string `json:"source"`
}

// SecurityEvidence records a literal security enforcement artifact discovered
// in source or manifests. It does not infer that an endpoint is secure; the
// Kind field identifies the evidence class (tls-config, rbac-ref, secret-ref,
// auth-middleware, ingress-policy, enforcement-boundary) and the Status field
// is "literal" for direct enforcement evidence, "dependency-signal" for an
// import or dependency that may provide a control but does not prove it is
// used, or "not-extracted" when the artifact exists but its semantics are
// ambiguous.
type SecurityEvidence struct {
	Kind    string   `json:"kind"`
	Target  string   `json:"target"`
	Detail  string   `json:"detail"`
	Status  string   `json:"status"`
	Source  string   `json:"source"`
	Sources []string `json:"sources,omitempty"`
}

func DecodeInput(reader io.Reader) (Input, error) {
	var input Input
	decoder := json.NewDecoder(reader)
	if err := decoder.Decode(&input); err != nil {
		return Input{}, fmt.Errorf("decode component architecture JSON: %w", err)
	}
	if input.Component == "" {
		return Input{}, fmt.Errorf("decode component architecture JSON: missing component")
	}
	return input, nil
}

func EncodeInput(writer io.Writer, input Input) error {
	encoder := json.NewEncoder(writer)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(input); err != nil {
		return fmt.Errorf("encode component architecture JSON: %w", err)
	}
	return nil
}
