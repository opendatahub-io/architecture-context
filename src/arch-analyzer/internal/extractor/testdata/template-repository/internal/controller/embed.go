package controller

import (
	"embed"

	templatev1 "example.com/template-operator/api/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

//go:embed templates/*.yaml.tmpl templates/managed.yaml.tmpl
//go:embed templates/catalog/*.yaml.tmpl
var templates embed.FS

type TemplateParams struct {
	Name string
	Spec *templatev1.RegistrySpec
}

type Reconciler struct{}

func (r *Reconciler) provision(params *TemplateParams) error {
	secretName := params.Name + "-credentials"
	secret := &corev1.Secret{
		ObjectMeta: metav1.ObjectMeta{Name: secretName},
		Type:       corev1.SecretTypeTLS,
	}
	return r.createOrUpdate(secret)
}

func (r *Reconciler) createOrUpdate(_ any) error {
	return nil
}
