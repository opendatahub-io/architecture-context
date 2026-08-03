package gosource

import (
	"testing"
)

func TestBlankImportExtendsReachabilityToProviderPackages(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"go.mod": "module example.com/runtime\n\ngo 1.25.0\n",
		"main.go": `package main

import (
	"example.com/runtime/internal/puller"
)

func main() { puller.Pull() }
`,
		"internal/puller/puller.go": `package puller

import (
	_ "example.com/runtime/internal/providers/gcs"
)

func Pull() {}
`,
		"internal/providers/gcs/provider.go": `package gcs

func init() {}
`,
		"internal/providers/gcs/downloader.go": `package gcs

import (
	storage "cloud.google.com/go/storage"
)

func NewDownloader() {
	_ = storage.NewClient()
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, client := range result.RuntimeClients {
		if client.Target == "Google Cloud Storage" && client.Client == "GCS storage client" {
			found = true
		}
	}
	if !found {
		t.Fatalf("runtime clients = %#v, want GCS storage client via blank-import reachability", result.RuntimeClients)
	}
}

func TestBlankImportTransitiveReachability(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"go.mod": "module example.com/runtime\n\ngo 1.25.0\n",
		"main.go": `package main

import (
	_ "example.com/runtime/internal/providers"
)

func main() {}
`,
		"internal/providers/providers.go": `package providers

import (
	_ "example.com/runtime/internal/providers/azure"
)
`,
		"internal/providers/azure/azure.go": `package azure

import (
	azblob "github.com/Azure/azure-sdk-for-go/sdk/storage/azblob"
)

func NewDownloader() {
	_ = azblob.NewClient()
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, client := range result.RuntimeClients {
		if client.Target == "Azure Blob Storage" && client.Client == "Azure Blob Storage client" {
			found = true
		}
	}
	if !found {
		t.Fatalf("runtime clients = %#v, want Azure Blob Storage client via transitive blank-import", result.RuntimeClients)
	}
}

func TestNonBlankImportDoesNotExtendReachability(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"go.mod": "module example.com/runtime\n\ngo 1.25.0\n",
		"main.go": `package main

func main() {}
`,
		"internal/unused/unused.go": `package unused

import (
	storage "cloud.google.com/go/storage"
)

func New() {
	_ = storage.NewClient()
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, client := range result.RuntimeClients {
		if client.Target == "Google Cloud Storage" {
			t.Fatalf("runtime clients = %#v, want unreachable package without blank import rejected", result.RuntimeClients)
		}
	}
}
