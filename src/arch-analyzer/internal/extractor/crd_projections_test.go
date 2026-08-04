package extractor

import (
	"path/filepath"
	"strings"
	"testing"

	"github.com/jctanner/arch-analyzer/internal/model"
)

func TestCollectCRDFieldProjectionsUsesExplicitSchemaContracts(t *testing.T) {
	root := t.TempDir()
	mustWriteCoverageFile(t, root, "crd.yaml", `apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.example.io
spec:
  group: example.io
  names:
    kind: Widget
  scope: Namespaced
  versions:
  - name: v1
    storage: true
    served: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              gatewayDomain:
                description: |-
                  Gateway domain for this component.
                  Projected by the orchestrator from the platform GatewayConfig.
                type: string
              ordinaryField:
                description: Used by the orchestrator during reconciliation.
                type: string
`)
	resolver := &loader{root: root, visiting: map[string]bool{}}
	objects, err := resolver.loadYAML(filepath.Join(root, "crd.yaml"))
	if err != nil {
		t.Fatal(err)
	}
	input := model.Input{}
	collectCRD(objects[0], &input)

	if len(input.FieldProjections) != 1 {
		t.Fatalf("projections = %#v, want one explicit projection", input.FieldProjections)
	}
	projection := input.FieldProjections[0]
	if projection.Field != "spec.gatewayDomain" || projection.Projector != "orchestrator" ||
		projection.UpstreamSource != "platform GatewayConfig" || !strings.HasPrefix(projection.Source, "crd.yaml:") {
		t.Fatalf("projection = %#v, want typed projection with line evidence", projection)
	}
}

func TestCollectManagedComponentContractsRequiresLifecycleSchema(t *testing.T) {
	root := t.TempDir()
	manifest := `apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: gateways.example.io
spec:
  group: example.io
  names:
    kind: Gateway
  scope: Cluster
  versions:
  - name: v1
    storage: true
    served: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              batchGateway:
                description: BatchGateway controls the batch-gateway operator sub-component.
                properties:
                  managementState:
                    enum: [Managed, Removed]
                    type: string
                type: object
`
	mustWriteCoverageFile(t, root, "crd.yaml", manifest)
	resolver := &loader{root: root, visiting: map[string]bool{}}
	objects, err := resolver.loadYAML(filepath.Join(root, "crd.yaml"))
	if err != nil {
		t.Fatal(err)
	}
	input := model.Input{}
	collectCRD(objects[0], &input)
	if len(input.ManagedComponents) != 1 {
		t.Fatalf("managed contracts = %#v, want one", input.ManagedComponents)
	}
	contract := input.ManagedComponents[0]
	if contract.Field != "spec.batchGateway.managementState" || contract.Component != "batch-gateway operator" ||
		contract.ManagedState != "Managed" || contract.RemovedState != "Removed" ||
		!strings.HasPrefix(contract.Source, "crd.yaml:") {
		t.Fatalf("managed contract = %#v, want typed lifecycle schema", contract)
	}

	for _, mutation := range []struct {
		name string
		old  string
		new  string
	}{
		{name: "missing Removed state", old: "enum: [Managed, Removed]", new: "enum: [Managed]"},
		{name: "missing component contract", old: "controls the batch-gateway operator sub-component", new: "configures gateway behavior"},
	} {
		t.Run(mutation.name, func(t *testing.T) {
			mutatedRoot := t.TempDir()
			mustWriteCoverageFile(t, mutatedRoot, "crd.yaml", strings.Replace(manifest, mutation.old, mutation.new, 1))
			mutatedResolver := &loader{root: mutatedRoot, visiting: map[string]bool{}}
			mutatedObjects, err := mutatedResolver.loadYAML(filepath.Join(mutatedRoot, "crd.yaml"))
			if err != nil {
				t.Fatal(err)
			}
			mutatedInput := model.Input{}
			collectCRD(mutatedObjects[0], &mutatedInput)
			if len(mutatedInput.ManagedComponents) != 0 {
				t.Fatalf("managed contracts = %#v, want incomplete schema rejected", mutatedInput.ManagedComponents)
			}
		})
	}
}
