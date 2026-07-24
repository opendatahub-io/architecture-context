package gosource

import (
	"strings"
	"testing"
)

func TestCLIKubernetesRuntimeBoundariesRequireConstructionAndOperations(t *testing.T) {
	result, err := Extract(writeRuntimeClientRepository(t, cliKubernetesRuntimeFiles()))
	if err != nil {
		t.Fatal(err)
	}
	wantClients := map[string]bool{
		"Operator Lifecycle Manager (OLM)": false,
		"Kubernetes API":                   false,
	}
	for _, client := range result.RuntimeClients {
		if _, expected := wantClients[client.Target]; expected {
			wantClients[client.Target] = client.Client != "" && client.Configuration != "" && client.Source != ""
		}
	}
	for target, found := range wantClients {
		if !found {
			t.Errorf("runtime clients = %#v, missing closed %s boundary", result.RuntimeClients, target)
		}
	}
	if len(result.Authentication) != 1 {
		t.Fatalf("authentication = %#v, want one Kubernetes API credential boundary", result.Authentication)
	}
	fact := result.Authentication[0]
	if fact.Endpoint != "Kubernetes API (6443/TCP)" ||
		fact.Methods != "kubeconfig credential chain (bearer token, client certificate, OIDC)" ||
		fact.Mechanism != "k8s.io/client-go transport credentials" || fact.EnforcementPoint != "kube-apiserver" ||
		fact.Policy != "RBAC pre-flight via SelfSubjectAccessReview before privileged operations" || fact.Source == "" {
		t.Fatalf("authentication = %#v, want source-backed kubeconfig and RBAC preflight", result.Authentication)
	}
}

func TestCLIKubernetesRuntimeBoundariesFollowRegisteredConcreteCallbacks(t *testing.T) {
	files := registeredCLIKubernetesRuntimeFiles(true)
	result, err := Extract(writeRuntimeClientRepository(t, files))
	if err != nil {
		t.Fatal(err)
	}
	if len(result.Authentication) != 1 || result.Authentication[0].Endpoint != "Kubernetes API (6443/TCP)" {
		t.Fatalf("authentication = %#v, want operation reached through registered concrete callback", result.Authentication)
	}

	result, err = Extract(writeRuntimeClientRepository(t, registeredCLIKubernetesRuntimeFiles(false)))
	if err != nil {
		t.Fatal(err)
	}
	for _, fact := range result.Authentication {
		if fact.Endpoint == "Kubernetes API (6443/TCP)" {
			t.Fatalf("authentication = %#v, want disconnected callback registration rejected", result.Authentication)
		}
	}
}

func TestCLIKubernetesRuntimeBoundariesRejectIncompleteEvidence(t *testing.T) {
	complete := cliKubernetesRuntimeFiles()
	tests := []struct {
		name     string
		allowOLM bool
		mutate   func(map[string]string)
	}{
		{name: "module only", mutate: func(files map[string]string) {
			for name := range files {
				if name != "go.mod" {
					delete(files, name)
				}
			}
		}},
		{name: "import only", mutate: func(files map[string]string) {
			files["client/client.go"] = strings.Replace(files["client/client.go"], "func NewClients", "func unusedNewClients", 1)
		}},
		{name: "interface only", mutate: func(files map[string]string) {
			files["operations/operations.go"] = `package operations
type Reader interface { Subscriptions(string) any; ClusterServiceVersions(string) any }
type Reviewer interface { SelfSubjectAccessReviews() any }
`
		}},
		{name: "disconnected lifecycle", mutate: func(files map[string]string) {
			files["cmd/main.go"] = `package main
func main() {}
`
		}},
		{name: "construction without operations", mutate: func(files map[string]string) {
			files["command/command.go"] = strings.Replace(files["command/command.go"], "operations.ReadOLM(clients)\n\toperations.CheckRBAC(clients)", "_ = clients", 1)
		}},
		{name: "operations without construction", mutate: func(files map[string]string) {
			files["command/command.go"] = strings.Replace(files["command/command.go"], "clients, _ := client.NewClients(config)", "var clients any", 1)
		}},
		{name: "review object without create", allowOLM: true, mutate: func(files map[string]string) {
			files["operations/operations.go"] = strings.Replace(files["operations/operations.go"],
				"_, _ = auth.SelfSubjectAccessReviews().Create(ctx, review)", "_ = review", 1)
		}},
		{name: "config not returned", mutate: func(files map[string]string) {
			files["config/config.go"] = strings.Replace(files["config/config.go"], "return config, nil", "return nil, nil", 1)
		}},
		{name: "different configs", mutate: func(files map[string]string) {
			files["client/client.go"] = strings.Replace(files["client/client.go"], "kubernetes.NewForConfig(config)", "kubernetes.NewForConfig(other)", 1)
		}},
		{name: "support tool only", mutate: func(files map[string]string) {
			files["tools/helper/main.go"] = strings.Replace(files["cmd/main.go"], "example.com/runtime/command", "example.com/runtime/command", 1)
			files["cmd/main.go"] = "package main\nfunc main() {}\n"
		}},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			files := map[string]string{}
			for name, content := range complete {
				files[name] = content
			}
			test.mutate(files)
			result, err := Extract(writeRuntimeClientRepository(t, files))
			if err != nil {
				t.Fatal(err)
			}
			for _, client := range result.RuntimeClients {
				if (client.Target == "Operator Lifecycle Manager (OLM)" && !test.allowOLM) ||
					(client.Target == "Kubernetes API" && strings.Contains(client.Configuration, "SelfSubjectAccessReview")) {
					t.Fatalf("runtime clients = %#v, want incomplete CLI boundary rejected", result.RuntimeClients)
				}
			}
			for _, fact := range result.Authentication {
				if fact.Endpoint == "Kubernetes API (6443/TCP)" {
					t.Fatalf("authentication = %#v, want incomplete CLI boundary rejected", result.Authentication)
				}
			}
		})
	}
}

func cliKubernetesRuntimeFiles() map[string]string {
	return map[string]string{
		"go.mod": `module example.com/runtime

go 1.25.0

require (
	github.com/operator-framework/api v0.0.0
	github.com/operator-framework/operator-lifecycle-manager v0.0.0
	k8s.io/api v0.0.0
	k8s.io/cli-runtime v0.0.0
	k8s.io/client-go v0.0.0
)
`,
		"cmd/main.go": `package main
import "example.com/runtime/command"
func main() {
	command := command.New()
	command.Run()
}
`,
		"command/command.go": `package command
import (
	"example.com/runtime/client"
	"example.com/runtime/config"
	"example.com/runtime/operations"
	"k8s.io/cli-runtime/pkg/genericclioptions"
)
type Command struct{}
func New() *Command { return &Command{} }
func (c *Command) Run() {
	flags := &genericclioptions.ConfigFlags{}
	config, _ := config.NewRESTConfig(flags)
	clients, _ := client.NewClients(config)
	operations.ReadOLM(clients)
	operations.CheckRBAC(clients)
}
`,
		"config/config.go": `package config
import (
	"k8s.io/cli-runtime/pkg/genericclioptions"
	"k8s.io/client-go/rest"
)
func NewRESTConfig(flags *genericclioptions.ConfigFlags) (*rest.Config, error) {
	config, err := flags.ToRESTConfig()
	if err != nil { return nil, err }
	return config, nil
}
`,
		"client/client.go": `package client
import (
	olmclient "github.com/operator-framework/operator-lifecycle-manager/pkg/api/client/clientset/versioned"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)
type Clients struct { OLM any; Kubernetes any }
func NewClients(config *rest.Config) (*Clients, error) {
	olm, _ := olmclient.NewForConfig(config)
	kube, _ := kubernetes.NewForConfig(config)
	return &Clients{OLM: olm, Kubernetes: kube}, nil
}
`,
		"operations/operations.go": `package operations
import (
	"context"
	operators "github.com/operator-framework/api/pkg/operators/v1alpha1"
	authorization "k8s.io/api/authorization/v1"
)
func ReadOLM(client any) {
	var typed operators.Subscription
	_, _ = client.Subscriptions("operators").Get(context.Background(), typed.Name)
	_, _ = client.ClusterServiceVersions("operators").List(context.Background())
}
func CheckRBAC(auth any) {
	ctx := context.Background()
	review := &authorization.SelfSubjectAccessReview{}
	_, _ = auth.SelfSubjectAccessReviews().Create(ctx, review)
}
`,
	}
}

func registeredCLIKubernetesRuntimeFiles(reachable bool) map[string]string {
	files := cliKubernetesRuntimeFiles()
	files["command/command.go"] = strings.Replace(files["command/command.go"],
		`"example.com/runtime/client"`, `"example.com/runtime/actions"
	"example.com/runtime/client"`, 1)
	registration := `_ = clients`
	if reachable {
		registration = `registry.MustRegister(&actions.Action{})`
	}
	files["command/command.go"] = strings.Replace(files["command/command.go"],
		"operations.CheckRBAC(clients)", registration, 1)
	files["command/command.go"] += `
type Registry struct{}
func (Registry) MustRegister(any) {}
var registry Registry
`
	if !reachable {
		files["command/command.go"] += `
func unusedRegistration() { registry.MustRegister(&actions.Action{}) }
`
	}
	files["actions/action.go"] = `package actions
import "example.com/runtime/operations"
type Action struct{}
func (a *Action) Execute() { operations.CheckRBAC(nil) }
`
	return files
}
