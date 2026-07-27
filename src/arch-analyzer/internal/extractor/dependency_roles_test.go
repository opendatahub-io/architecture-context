package extractor

import (
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestClassifyDependencyRolesGo(t *testing.T) {
	input := model.Input{
		Dependencies: model.Dependencies{
			GoModules: []model.GoModule{
				{Module: "sigs.k8s.io/controller-runtime", Version: "v0.19.0"},
				{Module: "github.com/spf13/cobra", Version: "v1.8.0"},
			},
			Packages: []model.LanguagePackage{
				{Name: "controller-runtime", Ecosystem: "go"},
			},
		},
	}
	classifyDependencyRoles(&input)
	if input.Dependencies.GoModules[0].Category != "runtime-framework" {
		t.Errorf("controller-runtime category = %q, want runtime-framework", input.Dependencies.GoModules[0].Category)
	}
	if input.Dependencies.GoModules[1].Category != "build-tool" {
		t.Errorf("cobra category = %q, want build-tool", input.Dependencies.GoModules[1].Category)
	}
}

func TestClassifyDependencyRolesPython(t *testing.T) {
	input := model.Input{
		Dependencies: model.Dependencies{
			Packages: []model.LanguagePackage{
				{Name: "fastapi", Ecosystem: "pypi"},
				{Name: "uvicorn", Ecosystem: "pypi"},
				{Name: "cryptography", Ecosystem: "pypi"},
				{Name: "pytest", Ecosystem: "pypi"},
				{Name: "numpy", Ecosystem: "pypi"},
			},
		},
	}
	classifyDependencyRoles(&input)
	expected := map[string]string{
		"fastapi":      "runtime-framework",
		"uvicorn":      "runtime-transport",
		"cryptography": "runtime-security",
		"pytest":       "build-tool",
		"numpy":        "runtime-library",
	}
	for _, pkg := range input.Dependencies.Packages {
		want := expected[pkg.Name]
		if pkg.Role != want {
			t.Errorf("%s role = %q, want %q", pkg.Name, pkg.Role, want)
		}
	}
}

func TestClassifyDependencyRolesRust(t *testing.T) {
	input := model.Input{
		Dependencies: model.Dependencies{
			Packages: []model.LanguagePackage{
				{Name: "tokio", Ecosystem: "Cargo"},
				{Name: "tonic", Ecosystem: "Cargo"},
				{Name: "rustls", Ecosystem: "Cargo"},
			},
		},
	}
	classifyDependencyRoles(&input)
	expected := map[string]string{
		"tokio":  "runtime-framework",
		"tonic":  "runtime-transport",
		"rustls": "runtime-security",
	}
	for _, pkg := range input.Dependencies.Packages {
		want := expected[pkg.Name]
		if pkg.Role != want {
			t.Errorf("%s role = %q, want %q", pkg.Name, pkg.Role, want)
		}
	}
}

func TestClassifyDependencyRolesPreservesExistingRole(t *testing.T) {
	input := model.Input{
		Dependencies: model.Dependencies{
			Packages: []model.LanguagePackage{
				{Name: "fastapi", Ecosystem: "pypi", Role: "custom-role"},
			},
		},
	}
	classifyDependencyRoles(&input)
	if input.Dependencies.Packages[0].Role != "custom-role" {
		t.Errorf("role = %q, want custom-role (should not overwrite)", input.Dependencies.Packages[0].Role)
	}
}

func TestClassifyDependencyRolesPreservesExistingGoModuleCategory(t *testing.T) {
	input := model.Input{
		Dependencies: model.Dependencies{
			GoModules: []model.GoModule{
				{Module: "sigs.k8s.io/controller-runtime", Category: "operator-framework"},
			},
		},
	}
	classifyDependencyRoles(&input)
	if input.Dependencies.GoModules[0].Category != "operator-framework" {
		t.Errorf("category = %q, want operator-framework (should not overwrite)", input.Dependencies.GoModules[0].Category)
	}
}
