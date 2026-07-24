package gosource

import (
	"go/ast"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

var routeMethods = map[string]string{
	"GET": "GET", "Get": "GET",
	"POST": "POST", "Post": "POST",
	"PUT": "PUT", "Put": "PUT",
	"PATCH": "PATCH", "Patch": "PATCH",
	"DELETE": "DELETE", "Delete": "DELETE",
	"HEAD": "HEAD", "Head": "HEAD",
	"OPTIONS": "OPTIONS", "Options": "OPTIONS",
	"Handle": "Unknown", "HandleFunc": "Unknown",
}

func extractRoutes(file sourceFile) []model.HTTPEndpoint {
	var routes []model.HTTPEndpoint
	ast.Inspect(file.file, func(node ast.Node) bool {
		call, ok := node.(*ast.CallExpr)
		if !ok || len(call.Args) == 0 {
			return true
		}
		selector, ok := call.Fun.(*ast.SelectorExpr)
		if !ok {
			return true
		}
		method, registered := routeMethods[selector.Sel.Name]
		path := stringLiteral(call.Args[0])
		if registered && strings.HasPrefix(path, "/") {
			routes = append(routes, model.HTTPEndpoint{
				Method:      method,
				Path:        path,
				Protocol:    "HTTP",
				Description: "Registered Go HTTP route",
				Source:      sourceAt(file, selector.Sel.Pos()),
			})
			return true
		}
		if selector.Sel.Name == "AddHealthzCheck" || selector.Sel.Name == "AddReadyzCheck" {
			name := stringLiteral(call.Args[0])
			if name != "" {
				routes = append(routes, model.HTTPEndpoint{
					Method:      "GET",
					Path:        "/" + strings.TrimPrefix(name, "/"),
					Protocol:    "HTTP",
					Description: "Controller manager health endpoint",
					Source:      sourceAt(file, selector.Sel.Pos()),
				})
			}
		}
		return true
	})
	return routes
}

func stringLiteral(expression ast.Expr) string {
	literal, ok := expression.(*ast.BasicLit)
	if !ok || literal.Kind.String() != "STRING" {
		return ""
	}
	value, err := strconv.Unquote(literal.Value)
	if err != nil {
		return ""
	}
	return value
}
