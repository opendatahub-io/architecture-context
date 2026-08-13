package gosource

import (
	"os"
	"path/filepath"
	"testing"
)

func TestEmbeddedManifestFileRecognizesTmplYaml(t *testing.T) {
	cases := []struct {
		path string
		want bool
	}{
		{"resources/deploy.yaml", true},
		{"resources/deploy.yml", true},
		{"resources/deploy.yaml.tmpl", true},
		{"resources/deploy.yml.tmpl", true},
		{"resources/deploy.tmpl.yaml", true},
		{"resources/deploy.tmpl.yml", true},
		{"resources/deploy.go", false},
		{"resources/deploy.json", false},
		{"resources/", false},
	}
	for _, tc := range cases {
		if got := embeddedManifestFile(tc.path); got != tc.want {
			t.Errorf("embeddedManifestFile(%q) = %v, want %v", tc.path, got, tc.want)
		}
	}
}

func TestEmbeddedManifestsWalksDirectories(t *testing.T) {
	dir := t.TempDir()
	repoRoot := dir

	pkgDir := filepath.Join(dir, "internal", "controller")
	resDir := filepath.Join(pkgDir, "resources")
	if err := os.MkdirAll(resDir, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, name := range []string{"deploy.tmpl.yaml", "service.yaml", "notes.txt"} {
		if err := os.WriteFile(filepath.Join(resDir, name), []byte("---"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	goMod := "module example.com/test\n\ngo 1.22\n"
	if err := os.WriteFile(filepath.Join(dir, "go.mod"), []byte(goMod), 0o644); err != nil {
		t.Fatal(err)
	}

	goSource := `package controller

import "embed"

//go:embed resources
var templates embed.FS
`
	goFile := filepath.Join(pkgDir, "controller.go")
	if err := os.WriteFile(goFile, []byte(goSource), 0o644); err != nil {
		t.Fatal(err)
	}

	result, err := Extract(repoRoot)
	if err != nil {
		t.Fatalf("Extract() error = %v", err)
	}

	wantSuffixes := map[string]bool{
		"deploy.tmpl.yaml": false,
		"service.yaml":     false,
	}
	for _, path := range result.EmbeddedManifests {
		base := filepath.Base(path)
		if _, ok := wantSuffixes[base]; ok {
			wantSuffixes[base] = true
		}
	}
	for suffix, found := range wantSuffixes {
		if !found {
			t.Errorf("embedded manifests missing %q; got %v", suffix, result.EmbeddedManifests)
		}
	}
	for _, path := range result.EmbeddedManifests {
		if filepath.Base(path) == "notes.txt" {
			t.Errorf("non-manifest file %q should not be included", path)
		}
	}
}
