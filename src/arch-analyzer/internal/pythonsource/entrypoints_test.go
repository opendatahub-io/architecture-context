package pythonsource

import (
	"testing"
)

func TestPythonEntrypointsFromScripts(t *testing.T) {
	result, err := Extract("testdata/entrypoint_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	scripts := map[string]bool{}
	for _, ep := range result.Entrypoints {
		scripts[ep.Name] = true
		if ep.Runtime != "Python" {
			t.Errorf("entrypoint %q runtime = %q, want Python", ep.Name, ep.Runtime)
		}
		if ep.Source == "" {
			t.Errorf("entrypoint %q missing source", ep.Name)
		}
	}
	if !scripts["auth-serve"] {
		t.Error("missing auth-serve console script entrypoint")
	}
	if !scripts["auth-migrate"] {
		t.Error("missing auth-migrate console script entrypoint")
	}
	if !scripts["uvicorn"] {
		t.Error("missing uvicorn ASGI server entrypoint")
	}
}

func TestPythonEntrypointTypes(t *testing.T) {
	result, err := Extract("testdata/entrypoint_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	for _, ep := range result.Entrypoints {
		switch ep.Name {
		case "auth-serve", "auth-migrate":
			if ep.Type != "Python console script" {
				t.Errorf("entrypoint %q type = %q, want Python console script", ep.Name, ep.Type)
			}
			if ep.Command == "" {
				t.Errorf("entrypoint %q missing command", ep.Name)
			}
		case "uvicorn":
			if ep.Type != "Python ASGI/WSGI server" {
				t.Errorf("entrypoint %q type = %q, want Python ASGI/WSGI server", ep.Name, ep.Type)
			}
		}
	}
}

func TestPythonSecurityEvidenceFromDependencies(t *testing.T) {
	result, err := Extract("testdata/entrypoint_app")
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}
	kinds := map[string]bool{}
	for _, se := range result.SecurityEvidence {
		kinds[se.Kind+":"+se.Target] = true
		if se.Status != "dependency-signal" {
			t.Errorf("evidence %q status = %q, want dependency-signal", se.Target, se.Status)
		}
		if se.Source == "" {
			t.Errorf("evidence %q missing source", se.Target)
		}
	}
	if !kinds["tls-config:cryptography"] {
		t.Error("missing tls-config evidence from cryptography dependency")
	}
	if !kinds["auth-middleware:pyjwt"] {
		t.Error("missing auth-middleware evidence from pyjwt dependency")
	}
	if !kinds["rbac-ref:kubernetes"] {
		t.Error("missing rbac-ref evidence from kubernetes dependency")
	}
}
