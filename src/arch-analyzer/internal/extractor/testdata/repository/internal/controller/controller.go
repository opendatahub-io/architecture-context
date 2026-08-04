package controller

import widgetv1 "example.com/repository/api/v1"

type WidgetReconciler struct{}

func (r *WidgetReconciler) SetupWithManager(manager any) error {
	return NewControllerManagedBy(manager).For(&widgetv1.Widget{}).Complete(r)
}

func RegisterRoutes(router interface{ GET(string, ...any) }) {
	router.GET("/v1/widgets")
}
