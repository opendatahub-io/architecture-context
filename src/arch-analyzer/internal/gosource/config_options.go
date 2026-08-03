package gosource

import "go/ast"

// repositoryOptionBindings resolves small configuration wrappers without type
// checking. A binding is retained only when a getter, backing field, Viper key,
// literal default, and flag name all converge across the repository.
type repositoryOptionBindings struct {
	strings map[string]stringFlagBinding
	bools   map[string]boolFlagBinding
}

type repositoryDefault struct {
	stringValue string
	boolValue   bool
	kind        string
}

func discoverRepositoryOptionBindings(files []sourceFile) repositoryOptionBindings {
	result := repositoryOptionBindings{
		strings: map[string]stringFlagBinding{},
		bools:   map[string]boolFlagBinding{},
	}
	defaults := map[string]repositoryDefault{}
	fieldKeys := map[string]string{}
	accessorFields := map[string]string{}
	flagNames := map[string]string{}

	for _, file := range files {
		ast.Inspect(file.file, func(node ast.Node) bool {
			call, ok := node.(*ast.CallExpr)
			if !ok || len(call.Args) < 2 {
				return true
			}
			selector, ok := call.Fun.(*ast.SelectorExpr)
			if !ok || selector.Sel.Name != "SetDefault" {
				return true
			}
			key, keyOK := staticStringLiteral(call.Args[0])
			if !keyOK {
				return true
			}
			if value, valueOK := staticStringLiteral(call.Args[1]); valueOK {
				defaults[key] = repositoryDefault{kind: "string", stringValue: value}
				return true
			}
			value := expressionIdentifier(call.Args[1])
			if value == "true" || value == "false" {
				defaults[key] = repositoryDefault{kind: "bool", boolValue: value == "true"}
			}
			return true
		})
	}

	for _, file := range files {
		ast.Inspect(file.file, func(node ast.Node) bool {
			switch typed := node.(type) {
			case *ast.KeyValueExpr:
				left := expressionIdentifier(typed.Key)
				if call, ok := typed.Value.(*ast.CallExpr); left != "" && ok && len(call.Args) == 1 {
					selector, selectorOK := call.Fun.(*ast.SelectorExpr)
					key, keyOK := staticStringLiteral(call.Args[0])
					if selectorOK && keyOK &&
						(selector.Sel.Name == "GetString" || selector.Sel.Name == "GetBool") {
						fieldKeys[left] = key
					}
				}
				key, keyOK := staticStringLiteral(typed.Key)
				value, valueOK := staticStringLiteral(typed.Value)
				if keyOK && valueOK {
					if _, exists := defaults[key]; exists {
						flagNames[key] = value
					}
				}
			case *ast.FuncDecl:
				if typed.Recv == nil || typed.Body == nil {
					return true
				}
				ast.Inspect(typed.Body, func(bodyNode ast.Node) bool {
					returned, ok := bodyNode.(*ast.ReturnStmt)
					if !ok || len(returned.Results) != 1 {
						return true
					}
					if field := terminalSelector(returned.Results[0]); field != "" {
						accessorFields[typed.Name.Name] = field
					}
					return true
				})
			}
			return true
		})
	}

	for accessor, field := range accessorFields {
		key := fieldKeys[field]
		value, valueOK := defaults[key]
		flag, flagOK := flagNames[key]
		if !valueOK || !flagOK {
			continue
		}
		switch value.kind {
		case "string":
			result.strings[accessor] = stringFlagBinding{name: flag, defaultValue: value.stringValue}
		case "bool":
			result.bools[accessor] = boolFlagBinding{name: flag, defaultValue: value.boolValue}
		}
	}
	return result
}

func terminalSelector(expression ast.Expr) string {
	selector, ok := expression.(*ast.SelectorExpr)
	if !ok {
		return ""
	}
	return selector.Sel.Name
}
