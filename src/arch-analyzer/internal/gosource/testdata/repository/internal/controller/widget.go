package controller

import (
	widgetv1 "example.com/widget-operator/api/v1"
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

type WidgetReconciler struct{}

type WidgetParams struct {
	Name string
	Spec *widgetv1.WidgetSpec
}

func (r *WidgetReconciler) SetupWithManager(manager any) error {
	return NewControllerManagedBy(manager).
		For(&widgetv1.Widget{}).
		Owns(&appsv1.Deployment{}).
		Watches(&corev1.Secret{}).
		Complete(r)
}

func RegisterRoutes(router interface {
	GET(string, ...any)
	POST(string, ...any)
}) {
	router.GET("/v1/widgets")
	router.POST("/v1/widgets")
}

func RegisterChecks(manager interface {
	AddHealthzCheck(string, any)
}) {
	manager.AddHealthzCheck("healthz", nil)
}

func (r *WidgetReconciler) Reconcile(client interface {
	Create(any, any) error
	Get(any, any, any) error
}, context, key any) error {
	deployment := &appsv1.Deployment{}
	if err := client.Create(context, deployment); err != nil {
		return err
	}
	var secret corev1.Secret
	return client.Get(context, key, &secret)
}

func (r *WidgetReconciler) provisionCredential(context any, params *WidgetParams) error {
	secretName := params.Name + "-credentials"
	secret := &corev1.Secret{
		ObjectMeta: metav1.ObjectMeta{Name: secretName},
		Type:       corev1.SecretTypeTLS,
	}
	readOnly := &corev1.Secret{ObjectMeta: metav1.ObjectMeta{Name: params.Name + "-read-only"}}
	unnamed := &corev1.Secret{}
	_, _ = readOnly, unnamed
	return r.createOrUpdate(context, secret)
}

func (r *WidgetReconciler) createOrUpdate(_ any, _ any) error {
	return nil
}
