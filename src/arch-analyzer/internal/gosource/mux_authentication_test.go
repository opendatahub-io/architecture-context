package gosource

import (
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestRepositoryHTTPAuthenticationClosesHelperRegisteredMuxes(t *testing.T) {
	result, err := Extract(writeRuntimeClientRepository(t, repositoryMuxFiles("", "", true)))
	if err != nil {
		t.Fatal(err)
	}
	facts := repositoryMuxFacts(result.Authentication)
	if len(facts) != 2 {
		t.Fatalf("authentication = %#v, want API and observability mux facts", facts)
	}
	want := map[string]string{
		"API server routes": "POST, GET, DELETE",
		"Observability endpoints (/health, /ready, /metrics)": "GET, HEAD",
	}
	for _, fact := range facts {
		methods, exists := want[fact.Endpoint]
		if !exists || fact.Methods != methods || fact.Mechanism != "None" || fact.EnforcementPoint != "N/A" || fact.Source == "" {
			t.Errorf("fact = %#v, want source-backed closed unauthenticated mux", fact)
		}
		delete(want, fact.Endpoint)
	}
	if len(want) != 0 {
		t.Fatalf("missing facts = %#v", want)
	}
}

func TestRepositoryHTTPAuthenticationRejectsUnclosedBoundaries(t *testing.T) {
	tests := []struct {
		name, middleware, routes string
		invoke                   bool
	}{
		{
			name: "credential enforcement",
			middleware: `func Authentication(_ common.Route, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("Authorization") == "" { w.WriteHeader(http.StatusUnauthorized); return }
		next(w, r)
	}
}`,
			invoke: true,
		},
		{
			name: "dynamic route inventory",
			routes: `func (h *APIHandler) GetRoutes() []common.Route {
		routes := []common.Route{{Method: http.MethodGet, Pattern: "/v1/items", HandlerFunc: h.Get}}
		return routes
	}`,
			invoke: true,
		},
		{name: "disconnected server constructor", invoke: false},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			result, err := Extract(writeRuntimeClientRepository(t, repositoryMuxFiles(test.middleware, test.routes, test.invoke)))
			if err != nil {
				t.Fatal(err)
			}
			for _, fact := range repositoryMuxFacts(result.Authentication) {
				if fact.Endpoint == "API server routes" {
					t.Fatalf("authentication = %#v, want API mux unresolved", result.Authentication)
				}
			}
		})
	}
}

func TestRepositoryHTTPAuthenticationRejectsImportedOrMutatedMiddleware(t *testing.T) {
	tests := []struct {
		name   string
		mutate func(map[string]string)
	}{
		{
			name: "imported middleware",
			mutate: func(files map[string]string) {
				files["server/server.go"] = strings.Replace(files["server/server.go"],
					`"example.com/mux/middleware"`, `"example.com/mux/middleware"
	"example.com/mux/external"`, 1)
				files["server/server.go"] = strings.Replace(files["server/server.go"], "middleware.Requests", "external.Wrap", 1)
				files["external/external.go"] = `package external
import ("net/http"; "example.com/mux/common")
func Wrap(_ common.Route, next http.HandlerFunc) http.HandlerFunc { return next }
`
			},
		},
		{
			name: "conditionally mutated middleware slice",
			mutate: func(files map[string]string) {
				files["server/server.go"] = strings.Replace(files["server/server.go"],
					"chain := []common.Middleware{middleware.Recovery, middleware.Requests}",
					"chain := []common.Middleware{middleware.Recovery, middleware.Requests}\n\tif enabled() { chain = append(chain, middleware.Recovery) }", 1)
			},
		},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			files := repositoryMuxFiles("", "", true)
			test.mutate(files)
			result, err := Extract(writeRuntimeClientRepository(t, files))
			if err != nil {
				t.Fatal(err)
			}
			for _, fact := range repositoryMuxFacts(result.Authentication) {
				if fact.Endpoint == "API server routes" {
					t.Fatalf("authentication = %#v, want dynamic or imported middleware unresolved", result.Authentication)
				}
			}
		})
	}
}

func repositoryMuxFacts(facts []model.AuthenticationFact) []model.AuthenticationFact {
	var result []model.AuthenticationFact
	for _, fact := range facts {
		if strings.Contains(fact.Endpoint, "server routes") || strings.HasPrefix(fact.Endpoint, "Observability endpoints") {
			result = append(result, fact)
		}
	}
	return result
}

func repositoryMuxFiles(authenticationMiddleware, apiRoutes string, invoke bool) map[string]string {
	if apiRoutes == "" {
		apiRoutes = `func (h *APIHandler) GetRoutes() []common.Route {
	return []common.Route{
		{Method: http.MethodPost, Pattern: "/v1/items", HandlerFunc: h.Post},
		{Method: http.MethodGet, Pattern: "/v1/items", HandlerFunc: h.Get},
		{Method: http.MethodDelete, Pattern: "/v1/items/{id}", HandlerFunc: h.Delete},
	}
}`
	}
	middlewareEntry := "middleware.Requests"
	if authenticationMiddleware != "" {
		middlewareEntry = "middleware.Authentication"
	}
	mainBody := "func main() {}"
	if invoke {
		mainBody = `func main() {
	s := server.New()
	s.Start()
}`
	}
	return map[string]string{
		"go.mod": "module example.com/mux\n\ngo 1.25.0\n",
		"main.go": `package main
import "example.com/mux/server"
` + mainBody + "\n",
		"common/routes.go": `package common
import "net/http"
type Route struct { Method string; Pattern string; HandlerFunc http.HandlerFunc }
type Handler interface { GetRoutes() []Route }
type Middleware func(Route, http.HandlerFunc) http.HandlerFunc
func Register(mux *http.ServeMux, h Handler, middleware ...Middleware) {
	for _, route := range h.GetRoutes() {
		handler := route.HandlerFunc
		for i := len(middleware)-1; i >= 0; i-- { handler = middleware[i](route, handler) }
		mux.HandleFunc(route.Method+" "+route.Pattern, handler)
	}
}
`,
		"handlers/handlers.go": `package handlers
import (
	"net/http"
	"example.com/mux/common"
)
type APIHandler struct{}
func NewAPIHandler() *APIHandler { return &APIHandler{} }
` + apiRoutes + `
func (*APIHandler) Post(http.ResponseWriter, *http.Request) {}
func (*APIHandler) Get(http.ResponseWriter, *http.Request) {}
func (*APIHandler) Delete(http.ResponseWriter, *http.Request) {}
type HealthHandler struct{}
func NewHealthHandler() *HealthHandler { return &HealthHandler{} }
func (h *HealthHandler) GetRoutes() []common.Route {
	return []common.Route{
		{Method: http.MethodGet, Pattern: "/health", HandlerFunc: h.Health},
		{Method: http.MethodHead, Pattern: "/health", HandlerFunc: h.Health},
	}
}
func (*HealthHandler) Health(http.ResponseWriter, *http.Request) {}
type ReadyHandler struct{}
func NewReadyHandler() *ReadyHandler { return &ReadyHandler{} }
func (h *ReadyHandler) GetRoutes() []common.Route {
	return []common.Route{{Method: http.MethodGet, Pattern: "/ready", HandlerFunc: h.Ready}}
}
func (*ReadyHandler) Ready(http.ResponseWriter, *http.Request) {}
type MetricsHandler struct{}
func NewMetricsHandler() *MetricsHandler { return &MetricsHandler{} }
func (h *MetricsHandler) GetRoutes() []common.Route {
	return []common.Route{{Method: http.MethodGet, Pattern: "/metrics", HandlerFunc: h.Metrics}}
}
func (*MetricsHandler) Metrics(http.ResponseWriter, *http.Request) {}
`,
		"middleware/middleware.go": `package middleware
import (
	"net/http"
	"example.com/mux/common"
)
func Recovery(_ common.Route, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) { defer func(){ _ = recover() }(); next(w, r) }
}
func Requests(_ common.Route, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) { _ = r.Header.Get("x-tenant-id"); next(w, r) }
}
` + authenticationMiddleware + "\n",
		"server/server.go": `package server
import (
	"net/http"
	"example.com/mux/common"
	"example.com/mux/handlers"
	"example.com/mux/middleware"
)
type Server struct { api http.Handler; obs http.Handler }
func New() *Server {
	apiMux := http.NewServeMux()
	api := handlers.NewAPIHandler()
	chain := []common.Middleware{middleware.Recovery, ` + middlewareEntry + `}
	common.Register(apiMux, api, chain...)
	obsMux := http.NewServeMux()
	health := handlers.NewHealthHandler()
	ready := handlers.NewReadyHandler()
	metrics := handlers.NewMetricsHandler()
	for _, h := range []common.Handler{health, ready, metrics} { common.Register(obsMux, h) }
	return &Server{api: apiMux, obs: obsMux}
}
func (s *Server) Start() {
	apiServer := &http.Server{Handler: s.api}
	obsServer := &http.Server{Handler: s.obs}
	go apiServer.ListenAndServe()
	go obsServer.ListenAndServe()
}
`,
	}
}
