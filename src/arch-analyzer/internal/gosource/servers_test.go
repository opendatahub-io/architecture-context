package gosource

import (
	"fmt"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestExtractBoundedHTTPAndGRPCAuthentication(t *testing.T) {
	root := writeSecurityRepository(t, `package main
import (
	"net/http"
	"google.golang.org/grpc"
	prom "github.com/grpc-ecosystem/go-grpc-middleware/providers/prometheus"
	serving "example.com/api"
)
func post(w http.ResponseWriter, r *http.Request) { if r.Method != "POST" { return } }
func health(w http.ResponseWriter, r *http.Request) {}
func metrics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { next.ServeHTTP(w, r) })
}
func serve() {
	ordinaryCall()
	mux := http.NewServeMux()
	mux.Handle("/features", metrics(http.HandlerFunc(post)))
	mux.Handle("/health", metrics(http.HandlerFunc(health)))
	server := &http.Server{Handler: mux}
	_ = server
	provider := prom.NewServerMetrics()
	grpcServer := grpc.NewServer(grpc.UnaryInterceptor(provider.UnaryServerInterceptor()))
	serving.RegisterServingServiceServer(grpcServer, nil)
}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]string{
		"/features (Go HTTP)": "POST",
		"/health (Go HTTP)":   "GET",
		"gRPC services (Go)":  "ALL",
	}
	for _, fact := range result.Authentication {
		if method, exists := want[fact.Endpoint]; exists {
			if fact.Methods != method || fact.Mechanism != "None" || fact.Source == "" {
				t.Errorf("fact = %#v, want bounded unauthenticated surface", fact)
			}
			delete(want, fact.Endpoint)
		}
	}
	if len(want) != 0 {
		t.Errorf("missing facts = %#v; got %#v", want, result.Authentication)
	}
}

func TestBoundedHTTPAuthenticationRejectsIncompleteChains(t *testing.T) {
	tests := []struct {
		name   string
		source string
	}{
		{
			name: "security middleware",
			source: `package main
import "net/http"
func handler(http.ResponseWriter, *http.Request) {}
func auth(next http.Handler) http.Handler { return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { token := r.Header.Get("Authorization"); _ = token; next.ServeHTTP(w, r) }) }
func serve() { mux := http.NewServeMux(); mux.Handle("/data", auth(http.HandlerFunc(handler))); _ = &http.Server{Handler: mux} }
`,
		},
		{
			name: "conditional pass through",
			source: `package main
import "net/http"
func handler(http.ResponseWriter, *http.Request) {}
func conditional(next http.Handler) http.Handler { return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { if allowed() { next.ServeHTTP(w, r) } }) }
func serve() { mux := http.NewServeMux(); mux.Handle("/data", conditional(http.HandlerFunc(handler))); _ = &http.Server{Handler: mux} }
`,
		},
		{
			name: "unresolved method",
			source: `package main
import "net/http"
func handler(http.ResponseWriter, *http.Request) {}
func serve() { mux := http.NewServeMux(); mux.Handle("/data", http.HandlerFunc(handler)); _ = &http.Server{Handler: mux} }
`,
		},
		{
			name: "undeployed mux",
			source: `package main
import "net/http"
func handler(w http.ResponseWriter, r *http.Request) { if r.Method != "POST" { return } }
func serve() { mux := http.NewServeMux(); mux.Handle("/data", http.HandlerFunc(handler)) }
`,
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			root := writeSecurityRepository(t, test.source)
			result, err := Extract(root)
			if err != nil {
				t.Fatal(err)
			}
			if facts := goServerFacts(result.Authentication); len(facts) != 0 {
				t.Fatalf("facts = %#v, want incomplete HTTP chain unresolved", facts)
			}
		})
	}
}

func TestBoundedGRPCAuthenticationRejectsDynamicOrUnknownOptions(t *testing.T) {
	tests := []string{
		`package main
import ("google.golang.org/grpc"; serving "example.com/api")
func serve() { options := []grpc.ServerOption{}; server := grpc.NewServer(options...); serving.RegisterServingServiceServer(server, nil) }
`,
		`package main
import ("google.golang.org/grpc"; serving "example.com/api")
func serve() { server := grpc.NewServer(grpc.UnaryInterceptor(authenticationInterceptor())); serving.RegisterServingServiceServer(server, nil) }
`,
		`package main
import ("google.golang.org/grpc"; health "google.golang.org/grpc/health/grpc_health_v1")
func serve() { server := grpc.NewServer(); health.RegisterHealthServer(server, nil) }
`,
		`package main
import ("google.golang.org/grpc"; serving "example.com/api")
func serve(secure bool) { var server *grpc.Server; if secure { server = grpc.NewServer(grpc.Creds(credentials())) } else { server = grpc.NewServer() }; serving.RegisterServingServiceServer(server, nil) }
`,
	}
	for index, source := range tests {
		root := writeSecurityRepository(t, source)
		result, err := Extract(root)
		if err != nil {
			t.Fatal(err)
		}
		for _, fact := range result.Authentication {
			if fact.Endpoint == "gRPC services (Go)" {
				t.Errorf("case %d fact = %#v, want unresolved gRPC security", index, fact)
			}
		}
	}
}

func TestExtractConfigurableCRDAuthorization(t *testing.T) {
	root := writeSecurityRepository(t, `package api
import corev1 "k8s.io/api/core/v1"
type FeatureStoreSpec struct {
	Services *Services `+"`json:\"services,omitempty\"`"+`
	Authz *AuthzConfig `+"`json:\"authz,omitempty\"`"+`
}
type Services struct{}
// +kubebuilder:validation:XValidation:rule="[has(self.kubernetes), has(self.oidc)].exists_one(c, c)",message="choose one"
type AuthzConfig struct {
	Kubernetes *KubernetesAuthz `+"`json:\"kubernetes,omitempty\"`"+`
	OIDC *OIDCAuthz `+"`json:\"oidc,omitempty\"`"+`
}
type KubernetesAuthz struct { Roles []string `+"`json:\"roles,omitempty\"`"+` }
type OIDCAuthz struct { SecretRef corev1.LocalObjectReference `+"`json:\"secretRef\"`"+` }
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	facts := configurableCRDFacts(result.Authentication)
	if len(facts) != 1 {
		t.Fatalf("facts = %#v, want one configurable authorization contract", facts)
	}
	if facts[0].Methods != "ALL" || !strings.Contains(facts[0].Mechanism, "Kubernetes RBAC") ||
		!strings.Contains(facts[0].Mechanism, "OIDC") || !strings.Contains(facts[0].Policy, "Exactly one") {
		t.Errorf("fact = %#v, want mutually exclusive configurable mechanisms", facts[0])
	}
}

func TestConfigurableCRDAuthorizationRejectsIncompleteContracts(t *testing.T) {
	base := `package api
import corev1 "k8s.io/api/core/v1"
type FeatureStoreSpec struct { Services *Services %s; Authz *AuthzConfig %s }
type Services struct{}
%s
type AuthzConfig struct { Kubernetes *KubernetesAuthz %s; OIDC *OIDCAuthz %s }
type KubernetesAuthz struct { Roles %s %s }
type OIDCAuthz struct { SecretRef %s %s }
`
	tag := func(value string) string { return "`json:\"" + value + "\"`" }
	marker := `// +kubebuilder:validation:XValidation:rule="[has(self.kubernetes), has(self.oidc)].exists_one(c, c)",message="choose one"`
	tests := []struct {
		name, marker, rolesType, secretType string
	}{
		{name: "missing exclusivity marker", marker: "", rolesType: "[]string", secretType: "corev1.LocalObjectReference"},
		{name: "roles shape unresolved", marker: marker, rolesType: "string", secretType: "corev1.LocalObjectReference"},
		{name: "OIDC secret is not reference", marker: marker, rolesType: "[]string", secretType: "string"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			source := fmt.Sprintf(base, tag("services,omitempty"), tag("authz,omitempty"), test.marker,
				tag("kubernetes,omitempty"), tag("oidc,omitempty"), test.rolesType, tag("roles,omitempty"),
				test.secretType, tag("secretRef"))
			root := writeSecurityRepository(t, source)
			result, err := Extract(root)
			if err != nil {
				t.Fatal(err)
			}
			if facts := configurableCRDFacts(result.Authentication); len(facts) != 0 {
				t.Fatalf("facts = %#v, want incomplete CRD contract rejected", facts)
			}
		})
	}
}

const conditionalIdentitySource = `package main

import "net/http"

type Config struct { LocalMode bool }
func (c *Config) RequiresIdentityHeaders() bool { return !c.LocalMode }

type ExecutionContext struct { User string; Tenant string }

type Server struct { config *Config }

func (s *Server) canContinueRequest(ctx *ExecutionContext) bool {
	if !s.config.RequiresIdentityHeaders() {
		return true
	}
	if ctx.User == "" {
		return false
	}
	if ctx.Tenant == "" {
		return false
	}
	return true
}

func (s *Server) setupRoutes() {
	mux := http.NewServeMux()
	s.setupHealthRoutes(mux)
	s.setupEvaluationRoutes(mux)
}

func (s *Server) setupHealthRoutes(mux *http.ServeMux) {
	s.handleFunc(mux, "/healthz", s.healthHandler)
}

func (s *Server) setupEvaluationRoutes(mux *http.ServeMux) {
	s.handleFunc(mux, "/evaluate", func(w http.ResponseWriter, r *http.Request) {
		if !s.canContinueRequest(nil) { return }
		s.evaluateHandler(w, r)
	})
}

func (s *Server) handleFunc(mux *http.ServeMux, pattern string, handler func(http.ResponseWriter, *http.Request)) {
	mux.HandleFunc(pattern, handler)
}

func (s *Server) healthHandler(w http.ResponseWriter, r *http.Request) {}
func (s *Server) evaluateHandler(w http.ResponseWriter, r *http.Request) {}

func main() {
	srv := &Server{config: &Config{}}
	srv.setupRoutes()
}
`

func TestConditionalIdentityEnforcementClassifiesRoutes(t *testing.T) {
	result, err := Extract(writeSecurityRepository(t, conditionalIdentitySource))
	if err != nil {
		t.Fatal(err)
	}
	gated := map[string]bool{}
	ungated := map[string]bool{}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "Conditional") {
			gated[fact.Endpoint] = true
		}
		if fact.Mechanism == "None" && strings.Contains(fact.Policy, "does not invoke") {
			ungated[fact.Endpoint] = true
		}
	}
	if !gated["/evaluate (Go HTTP)"] {
		t.Errorf("gated routes = %#v, want /evaluate gated", gated)
	}
	if !ungated["/healthz (Go HTTP)"] {
		t.Errorf("ungated routes = %#v, want /healthz ungated", ungated)
	}
}

func TestConditionalIdentityEnforcementRejectsWithoutGateMethod(t *testing.T) {
	source := strings.Replace(conditionalIdentitySource,
		`func (s *Server) canContinueRequest(ctx *ExecutionContext) bool {
	if !s.config.RequiresIdentityHeaders() {
		return true
	}
	if ctx.User == "" {
		return false
	}
	if ctx.Tenant == "" {
		return false
	}
	return true
}`,
		`func (s *Server) canContinueRequest(ctx *ExecutionContext) bool {
	return true
}`, 1)
	result, err := Extract(writeSecurityRepository(t, source))
	if err != nil {
		t.Fatal(err)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "Conditional") {
			t.Fatalf("facts = %#v, want no conditional enforcement without proper gate method", result.Authentication)
		}
	}
}

func goServerFacts(facts []model.AuthenticationFact) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	for _, fact := range facts {
		if strings.Contains(fact.Endpoint, "(Go HTTP)") || fact.Endpoint == "gRPC services (Go)" {
			result = append(result, fact)
		}
	}
	return result
}

func configurableCRDFacts(facts []model.AuthenticationFact) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	for _, fact := range facts {
		if strings.Contains(fact.Endpoint, "(CRD-configured)") {
			result = append(result, fact)
		}
	}
	return result
}
