package gosource

import "testing"

func TestInClusterServiceAccountAuth(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import (
	"k8s.io/client-go/rest"
	"k8s.io/client-go/kubernetes"
)
func main() {
	config, _ := rest.InClusterConfig()
	clientset, _ := kubernetes.NewForConfig(config)
	_ = clientset
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, fact := range result.Authentication {
		if fact.Mechanism == "ServiceAccount token (in-cluster)" {
			found = true
		}
	}
	if !found {
		t.Fatalf("authentication = %#v, want ServiceAccount token (in-cluster) fact", result.Authentication)
	}
}

func TestInClusterAuthRequiresBothConfigAndClient(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import "k8s.io/client-go/rest"
func main() {
	config, _ := rest.InClusterConfig()
	_ = config
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, fact := range result.Authentication {
		if fact.Mechanism == "ServiceAccount token (in-cluster)" {
			t.Fatalf("authentication = %#v, want no in-cluster auth without client constructor", result.Authentication)
		}
	}
}

func TestTokenReviewAuth(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import (
	authenticationv1 "k8s.io/api/authentication/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)
func main() {
	config, _ := rest.InClusterConfig()
	clientset, _ := kubernetes.NewForConfig(config)
	validate(clientset)
}
func validate(clientset any) {
	review := &authenticationv1.TokenReview{}
	_, _ = clientset.AuthenticationV1().TokenReviews().Create(nil, review, nil)
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, fact := range result.Authentication {
		if fact.Mechanism == "Kubernetes TokenReview API" {
			found = true
		}
	}
	if !found {
		t.Fatalf("authentication = %#v, want Kubernetes TokenReview API fact", result.Authentication)
	}
}

func TestTokenReviewRequiresBothConstructionAndCall(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import authenticationv1 "k8s.io/api/authentication/v1"
func main() {
	review := &authenticationv1.TokenReview{}
	_ = review
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, fact := range result.Authentication {
		if fact.Mechanism == "Kubernetes TokenReview API" {
			t.Fatalf("authentication = %#v, want no TokenReview without API call", result.Authentication)
		}
	}
}

func TestKubeconfigAuth(t *testing.T) {
	root := writeRuntimeClientRepository(t, map[string]string{
		"main.go": `package main
import (
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/kubernetes"
)
func main() {
	config, _ := clientcmd.BuildConfigFromFlags("", "/etc/kubernetes/kubeconfig")
	clientset, _ := kubernetes.NewForConfig(config)
	_ = clientset
}
`,
	})
	result, err := Extract(root)
	if err != nil {
		t.Fatal(err)
	}
	found := false
	for _, fact := range result.Authentication {
		if fact.Mechanism == "kubeconfig credential chain" {
			found = true
		}
	}
	if !found {
		t.Fatalf("authentication = %#v, want kubeconfig credential chain fact", result.Authentication)
	}
}
