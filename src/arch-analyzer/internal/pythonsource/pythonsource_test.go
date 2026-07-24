package pythonsource

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestExtractPythonRepository(t *testing.T) {
	result, err := Extract("testdata/repository")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(result.Components) != 1 || result.Components[0].Name != "widget-api" ||
		result.Components[0].Type != "Python Service (FastAPI)" {
		t.Fatalf("components = %#v", result.Components)
	}
	dependencies := map[string]string{}
	for _, dependency := range result.Dependencies {
		dependencies[dependency.Name] = dependency.Version
	}
	for name, version := range map[string]string{
		"Python": ">=3.11", "fastapi": ">=0.115", "grpcio": ">=1.67", "httpx": ">=0.27", "pydantic": ">=2.0",
	} {
		if dependencies[name] != version {
			t.Errorf("dependency %s = %q, want %q", name, dependencies[name], version)
		}
	}
	if len(result.HTTPEndpoints) != 2 || result.HTTPEndpoints[0].Port != "8000/TCP" {
		t.Errorf("endpoints = %#v", result.HTTPEndpoints)
	}
	if len(result.GRPCServices) != 2 || result.GRPCServices[0].Service != "example.v1.WidgetService/GetWidget" {
		t.Errorf("gRPC services = %#v", result.GRPCServices)
	}
	if len(result.Services) != 1 || result.Services[0].Name != "widget-api" {
		t.Errorf("services = %#v", result.Services)
	}
	if len(result.Connections) != 1 || result.Connections[0].Target != "models.example.com" {
		t.Errorf("connections = %#v", result.Connections)
	}
	if len(result.Secrets) != 1 || result.Secrets[0].Name != "WIDGET_API_TOKEN" {
		t.Errorf("secrets = %#v", result.Secrets)
	}
	if !strings.HasPrefix(result.Coverage, "partial:") {
		t.Errorf("coverage = %q", result.Coverage)
	}
}

func TestExtractAuthMiddlewareRegistration(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var middleware *model.AuthenticationFact
	for i := range result.Authentication {
		if strings.Contains(result.Authentication[i].EnforcementPoint, "ASGI middleware") {
			middleware = &result.Authentication[i]
			break
		}
	}
	if middleware == nil {
		t.Fatalf("no ASGI middleware fact found in %d facts", len(result.Authentication))
	}
	if middleware.Mechanism != "Bearer token" {
		t.Errorf("mechanism = %q, want Bearer token", middleware.Mechanism)
	}
	if !strings.Contains(middleware.Policy, "Configuration-conditional") {
		t.Errorf("policy = %q, want Configuration-conditional", middleware.Policy)
	}
	if !strings.Contains(middleware.Policy, "config.server.auth") {
		t.Errorf("policy = %q, want config.server.auth in condition", middleware.Policy)
	}
	if !strings.Contains(middleware.Source, "server.py") {
		t.Errorf("source = %q, want server.py", middleware.Source)
	}
}

func TestExtractAuthProviderFactory(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var providers []model.AuthenticationFact
	for _, fact := range result.Authentication {
		if strings.Contains(fact.EnforcementPoint, "via factory") {
			providers = append(providers, fact)
		}
	}
	if len(providers) != 2 {
		t.Fatalf("got %d factory providers, want 2; facts=%v", len(providers), result.Authentication)
	}
	sort.Slice(providers, func(i, j int) bool {
		return providers[i].EnforcementPoint < providers[j].EnforcementPoint
	})
	if !strings.Contains(providers[0].EnforcementPoint, "ExternalAuthProvider") {
		t.Errorf("provider[0] = %q, want ExternalAuthProvider", providers[0].EnforcementPoint)
	}
	if providers[0].Mechanism != "External HTTP authentication delegation" {
		t.Errorf("provider[0].mechanism = %q", providers[0].Mechanism)
	}
	if !strings.Contains(providers[1].EnforcementPoint, "JWTAuthProvider") {
		t.Errorf("provider[1] = %q, want JWTAuthProvider", providers[1].EnforcementPoint)
	}
}

func TestExtractABACEnforcement(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var abac []model.AuthenticationFact
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "ABAC") {
			abac = append(abac, fact)
		}
	}
	if len(abac) != 2 {
		t.Fatalf("got %d ABAC facts, want 2; facts=%v", len(abac), result.Authentication)
	}
	sort.Slice(abac, func(i, j int) bool { return abac[i].Endpoint < abac[j].Endpoint })
	if !strings.Contains(abac[0].Endpoint, "Resource manager") {
		t.Errorf("abac[0].endpoint = %q", abac[0].Endpoint)
	}
	if !strings.Contains(abac[0].Methods, "create") || !strings.Contains(abac[0].Methods, "delete") || !strings.Contains(abac[0].Methods, "read") {
		t.Errorf("abac[0].methods = %q, want create, delete, read", abac[0].Methods)
	}
	if !strings.Contains(abac[1].Endpoint, "Session store") {
		t.Errorf("abac[1].endpoint = %q", abac[1].Endpoint)
	}
	if !strings.Contains(abac[1].Methods, "create") || !strings.Contains(abac[1].Methods, "read") {
		t.Errorf("abac[1].methods = %q, want create, read", abac[1].Methods)
	}
}

func TestExtractQuotaNotAuthentication(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(strings.ToLower(fact.EnforcementPoint), "quota") ||
			strings.Contains(strings.ToLower(fact.Mechanism), "rate") {
			t.Errorf("quota middleware emitted as auth fact: %v", fact)
		}
	}
}

func TestExtractDisconnectedProviderNotEmitted(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.EnforcementPoint, "UnusedAuthProvider") {
			t.Errorf("disconnected provider emitted as auth fact: %v", fact)
		}
	}
}

func TestExtractAuthDeduplication(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	seen := map[string]bool{}
	for _, fact := range result.Authentication {
		key := fact.EnforcementPoint + "\x00" + fact.Mechanism
		if seen[key] {
			t.Errorf("duplicate auth fact: %v", fact)
		}
		seen[key] = true
	}
}

func TestExtractImportOnlyNoFact(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "import-only"
dependencies = ["fastapi"]
`)
	mustWriteFile(t, root, "app/main.py", `from starlette.middleware import AuthenticationMiddleware
from some_lib import AuthProvider
import jwt
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(result.Authentication) != 0 {
		t.Errorf("import-only should not emit auth facts: %v", result.Authentication)
	}
}

func TestExtractNonGatingABACNotEmitted(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "non-gating"
dependencies = ["fastapi"]
`)
	mustWriteFile(t, root, "app/handler.py", `from access import is_action_allowed

class Logger:
    def log_access(self, user, resource):
        allowed = is_action_allowed(self.policy, "audit", resource, user)
        logger.info(f"Access check: {allowed}")
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "ABAC") {
			t.Errorf("non-gating ABAC call emitted as fact: %v", fact)
		}
	}
}

func TestExtractUnconditionalMiddleware(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "unconditional"
dependencies = ["starlette"]
`)
	mustWriteFile(t, root, "app/server.py", `from app.auth import AuthMiddleware
app = FastAPI()
app.add_middleware(AuthMiddleware)
`)
	mustWriteFile(t, root, "app/auth.py", `class AuthMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        headers = dict(scope.get("headers", []))
        auth_header = headers.get(b"authorization", b"").decode()
        if not auth_header.startswith("Bearer "):
            return await self._send_auth_error(send, "Unauthorized")
        token = auth_header.split("Bearer ", 1)[1]
        await self.auth_provider.validate_token(token)
        return await self.app(scope, receive, send)

    async def _send_auth_error(self, send, msg):
        await send({"type": "http.response.start", "status": 401})
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(result.Authentication) != 1 {
		t.Fatalf("got %d facts, want 1", len(result.Authentication))
	}
	if strings.Contains(result.Authentication[0].Policy, "Configuration-conditional") {
		t.Errorf("unconditional middleware should not be marked conditional: %v", result.Authentication[0])
	}
	if result.Authentication[0].Policy != "Source-defined authentication" {
		t.Errorf("policy = %q", result.Authentication[0].Policy)
	}
}

func TestExtractRepeatedABACGrouped(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "repeated-abac"
dependencies = ["fastapi"]
`)
	mustWriteFile(t, root, "app/resources.py", `from access import is_action_allowed

class ItemStore:
    def get_item(self, item):
        if not is_action_allowed(self.policy, "read", item, user):
            return None
        return item

    def get_item_v2(self, item):
        if not is_action_allowed(self.policy, "read", item, user):
            return None
        return item

    def delete_item(self, item):
        if not is_action_allowed(self.policy, "delete", item, user):
            raise AccessDeniedError()
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var abac []model.AuthenticationFact
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "ABAC") {
			abac = append(abac, fact)
		}
	}
	if len(abac) != 1 {
		t.Fatalf("repeated ABAC calls should be grouped into 1 fact, got %d", len(abac))
	}
	if !strings.Contains(abac[0].Methods, "delete") || !strings.Contains(abac[0].Methods, "read") {
		t.Errorf("methods = %q, want delete, read", abac[0].Methods)
	}
}

func TestAuthFactCount(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	// 1 middleware + 2 providers + 2 ABAC surfaces = 5
	if len(result.Authentication) != 5 {
		for i, fact := range result.Authentication {
			t.Logf("  fact[%d]: endpoint=%q enforcement=%q mechanism=%q", i, fact.Endpoint, fact.EnforcementPoint, fact.Mechanism)
		}
		t.Fatalf("got %d auth facts, want 5", len(result.Authentication))
	}
}

// --- Auth posture tests ---

func TestAuthPostureNoAuth(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "no-auth-app"
dependencies = ["fastapi"]
`)
	mustWriteFile(t, root, "app/main.py", `from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/predict")
async def predict():
    return {"result": 42}

uvicorn.run("app.main:app", port=8080)
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(result.HTTPEndpoints) < 2 {
		t.Fatalf("expected at least 2 endpoints, got %d", len(result.HTTPEndpoints))
	}
	var posture *model.AuthenticationFact
	for i := range result.Authentication {
		if strings.Contains(result.Authentication[i].Mechanism, "None") {
			posture = &result.Authentication[i]
			break
		}
	}
	if posture == nil {
		t.Fatalf("no absence-of-auth fact found in %d facts", len(result.Authentication))
	}
	if posture.Mechanism != "None (no auth middleware detected)" {
		t.Errorf("mechanism = %q", posture.Mechanism)
	}
	if posture.EnforcementPoint != "FastAPI/Starlette application" {
		t.Errorf("enforcement_point = %q", posture.EnforcementPoint)
	}
	if !strings.HasSuffix(strings.SplitN(posture.Source, ":", 2)[0], ".py") {
		t.Errorf("source = %q, want .py file", posture.Source)
	}
}

func TestAuthPostureWithAuthMarker(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "auth-marker-app"
dependencies = ["fastapi"]
`)
	mustWriteFile(t, root, "app/main.py", `from fastapi import FastAPI
from fastapi.security import OAuth2PasswordBearer

app = FastAPI()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

@app.get("/protected")
async def protected():
    return {"data": "secret"}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "None") {
			t.Errorf("absence-of-auth fact should not be emitted when authMarker is present: %v", fact)
		}
	}
	if len(result.Authentication) == 0 {
		t.Fatal("expected at least one auth fact from authMarker")
	}
}

func TestAuthPostureWithMiddleware(t *testing.T) {
	result, err := Extract("testdata/auth_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "None") {
			t.Errorf("absence-of-auth fact should not be emitted when auth middleware is present: %v", fact)
		}
	}
	if len(result.Authentication) != 5 {
		t.Errorf("auth_app should still have 5 facts, got %d", len(result.Authentication))
	}
}

func TestStarletteAuthMiddleware(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "starlette-auth-app"
dependencies = ["fastapi", "starlette"]
`)
	mustWriteFile(t, root, "app/auth_backend.py", `from starlette.middleware.authentication import AuthenticationMiddleware
`)
	mustWriteFile(t, root, "app/server.py", `from fastapi import FastAPI
from starlette.middleware.authentication import AuthenticationMiddleware
from app.auth_backend import TokenBackend

app = FastAPI()
app.add_middleware(AuthenticationMiddleware, backend=TokenBackend())

@app.get("/api/v1/status")
async def status():
    return {"status": "ok"}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var starletteAuth *model.AuthenticationFact
	for i := range result.Authentication {
		if strings.Contains(result.Authentication[i].Mechanism, "Starlette") {
			starletteAuth = &result.Authentication[i]
			break
		}
	}
	if starletteAuth == nil {
		for i, fact := range result.Authentication {
			t.Logf("  fact[%d]: mechanism=%q enforcement=%q", i, fact.Mechanism, fact.EnforcementPoint)
		}
		t.Fatalf("no Starlette AuthenticationMiddleware fact found in %d facts", len(result.Authentication))
	}
	if !strings.Contains(starletteAuth.EnforcementPoint, "starlette.middleware.authentication") {
		t.Errorf("enforcement_point = %q", starletteAuth.EnforcementPoint)
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "None") {
			t.Errorf("absence-of-auth should not fire when starlette middleware is present: %v", fact)
		}
	}
}

func TestSlowAPINotAuth(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "rate-limited-app"
dependencies = ["fastapi", "slowapi"]
`)
	mustWriteFile(t, root, "app/main.py", `from fastapi import FastAPI
from slowapi import Limiter
from slowapi.middleware import SlowAPIMiddleware

app = FastAPI()
limiter = Limiter(key_func=lambda: "global")
app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)

@app.get("/data")
async def get_data():
    return {"data": [1, 2, 3]}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	hasAbsence := false
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "None") {
			hasAbsence = true
		}
		lower := strings.ToLower(fact.Mechanism + fact.EnforcementPoint)
		if strings.Contains(lower, "slowapi") || strings.Contains(lower, "limiter") ||
			strings.Contains(lower, "rate") {
			t.Errorf("rate limiter emitted as auth fact: %v", fact)
		}
	}
	if !hasAbsence {
		t.Error("absence-of-auth should fire when only a rate limiter is present (no real auth)")
	}
}

func TestDependsAuth(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "depends-auth-app"
dependencies = ["fastapi"]
`)
	mustWriteFile(t, root, "app/main.py", `from fastapi import FastAPI, Depends
from app.auth import get_current_user

app = FastAPI()

@app.get("/profile")
async def profile(user=Depends(get_current_user)):
    return {"user": user}
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(result.Authentication) == 0 {
		t.Fatal("expected at least one auth fact from Depends(get_current_user)")
	}
	for _, fact := range result.Authentication {
		if strings.Contains(fact.Mechanism, "None") {
			t.Errorf("absence-of-auth should not fire when Depends auth is present: %v", fact)
		}
	}
}

// --- SDK client tests ---

func TestSDKClientOpenAI(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "openai-app"
dependencies = ["openai"]
`)
	mustWriteFile(t, root, "app/client.py", `import os
import openai

client = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
response = client.chat.completions.create(model="gpt-4", messages=[])
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var found *model.ExternalConnection
	for i := range result.Connections {
		if result.Connections[i].Type == "SDK client" {
			found = &result.Connections[i]
			break
		}
	}
	if found == nil {
		t.Fatalf("no SDK client connection found in %d connections", len(result.Connections))
	}
	if found.Service != "OpenAI" {
		t.Errorf("service = %q, want OpenAI", found.Service)
	}
	if found.Auth != "API key (OPENAI_API_KEY)" {
		t.Errorf("auth = %q", found.Auth)
	}
	if found.Protocol != "HTTPS" {
		t.Errorf("protocol = %q", found.Protocol)
	}
}

func TestSDKClientAnthropic(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "anthropic-app"
dependencies = ["anthropic"]
`)
	mustWriteFile(t, root, "app/llm.py", `import os
from anthropic import Anthropic

client = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var found *model.ExternalConnection
	for i := range result.Connections {
		if result.Connections[i].Type == "SDK client" && result.Connections[i].Service == "Anthropic" {
			found = &result.Connections[i]
			break
		}
	}
	if found == nil {
		t.Fatal("no Anthropic SDK client connection found")
	}
	if found.Auth != "API key (ANTHROPIC_API_KEY)" {
		t.Errorf("auth = %q", found.Auth)
	}
}

func TestSDKClientAzure(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "azure-app"
dependencies = ["openai"]
`)
	mustWriteFile(t, root, "app/llm.py", `import os
from openai import AzureOpenAI

client = AzureOpenAI(
    api_key=os.environ.get("AZURE_OPENAI_API_KEY"),
    azure_endpoint="https://myendpoint.openai.azure.com",
)
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	var found *model.ExternalConnection
	for i := range result.Connections {
		if result.Connections[i].Type == "SDK client" && result.Connections[i].Service == "Azure OpenAI" {
			found = &result.Connections[i]
			break
		}
	}
	if found == nil {
		t.Fatal("no Azure OpenAI SDK client connection found")
	}
	if found.Auth != "API key (AZURE_OPENAI_API_KEY)" {
		t.Errorf("auth = %q", found.Auth)
	}
}

func TestSDKClientMultiple(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "multi-sdk-app"
dependencies = ["openai", "anthropic"]
`)
	mustWriteFile(t, root, "app/llm.py", `import os
import openai
from anthropic import Anthropic

oai = openai.OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))
ant = Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	sdkCount := 0
	for _, conn := range result.Connections {
		if conn.Type == "SDK client" {
			sdkCount++
		}
	}
	if sdkCount != 2 {
		t.Errorf("got %d SDK client connections, want 2", sdkCount)
	}
}

func TestSDKClientNoEnvVar(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "no-env-app"
dependencies = ["openai"]
`)
	mustWriteFile(t, root, "app/llm.py", `from openai import OpenAI

client = OpenAI(api_key=config.api_key)
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	for _, conn := range result.Connections {
		if conn.Type == "SDK client" {
			t.Errorf("SDK client connection should not be emitted without env var credential: %v", conn)
		}
	}
}

func TestHFTokenNotSDKClient(t *testing.T) {
	root := t.TempDir()
	mustWriteFile(t, root, "pyproject.toml", `[project]
name = "hf-token-app"
dependencies = ["transformers"]
`)
	mustWriteFile(t, root, "app/loader.py", `import os

token = os.environ.get("HF_TOKEN")
`)
	result, err := Extract(root)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	if len(result.Secrets) != 1 || result.Secrets[0].Name != "HF_TOKEN" {
		t.Errorf("secrets = %v, want [HF_TOKEN]", result.Secrets)
	}
	for _, conn := range result.Connections {
		if conn.Type == "SDK client" {
			t.Errorf("HF_TOKEN should not generate SDK client connection: %v", conn)
		}
	}
}

func mustWriteFile(t *testing.T, root, relative, content string) {
	t.Helper()
	path := filepath.Join(root, filepath.FromSlash(relative))
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
}
