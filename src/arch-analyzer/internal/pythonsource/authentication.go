package pythonsource

import (
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type middlewareReg struct {
	className   string
	conditional string
	source      string
}

type classDef struct {
	name string
	file string
	body string
}

type factoryInfo struct {
	name     string
	file     string
	branches []string
}

type abacSignal struct {
	function string
	action   string
	file     string
	line     int
	class    string
}

type abacGroup struct {
	name     string
	function string
	actions  []string
	source   string
}

var (
	pyAddMiddlewareRe = regexp.MustCompile(`\b\w+\.add_middleware\(\s*(\w+)`)
	pyClassDefRe      = regexp.MustCompile(`(?m)^class\s+(\w+)\s*(?:\([^)]*\))?\s*:`)
	pyFactoryDefRe    = regexp.MustCompile(`(?mi)^def\s+((?:create|get|build|make)_\w*(?:auth|provider)\w*)\s*\(`)
	pyFactoryReturnRe = regexp.MustCompile(`(?m)\breturn\s+(\w+)\s*\(`)
	pyBearerRe        = regexp.MustCompile(`(?i)(?:["']authorization["']|\.startswith\(\s*["']Bearer |auth_header\b)`)
	pyDenialRe        = regexp.MustCompile(`(?i)(?:_send_auth_error|send_auth_error|raise\s+\w*(?:Error|Exception)|["':](?:401|403)\b|status_code\s*=\s*(?:401|403)\b)`)
	pyTokenValRe      = regexp.MustCompile(`(?i)(?:validate_token|verify_token)\s*\(`)
	pyFactoryCallRe   = regexp.MustCompile(`(?i)((?:create|get|build|make)_\w*(?:auth|provider)\w*)\s*\(`)
	pyJWTRe           = regexp.MustCompile(`(?i)(?:\bjwt\b\.(?:decode|get_unverified_header)|jwks|introspect_token)`)
	pyHTTPDelegateRe  = regexp.MustCompile(`(?i)(?:httpx|aiohttp|requests)\.\w*[Cc]lient`)
	pyAbacCallRe      = regexp.MustCompile(`(?i)\b(is_action_allowed|check_permission|has_permission|is_authorized)\s*\(`)
	pyAbacNegRe       = regexp.MustCompile(`(?im)(?:if\s+not|not\s+)\s*(?:is_action_allowed|check_permission|has_permission|is_authorized)\s*\(`)
	pyAbacFilterRe    = regexp.MustCompile(`(?i)\bfor\s+\w+[^\n]*\bif\s+(?:is_action_allowed|check_permission|has_permission|is_authorized)\s*\(`)
	pyAbacReturnRe    = regexp.MustCompile(`(?im)\breturn\s+(?:is_action_allowed|check_permission|has_permission|is_authorized)\s*\(`)
	pyAbacActionRe    = regexp.MustCompile(`(?i)(?:is_action_allowed|check_permission|has_permission|is_authorized)\s*\([^,]*,\s*["'](\w+)["']`)
	pyQuotaRe         = regexp.MustCompile(`(?i)(?:\bQuota\b|\bRateLimit\b|\bThrottl)`)

	pyStarletteAuthImportRe = regexp.MustCompile(
		`(?m)from\s+starlette\.middleware\.authentication\s+import\s+AuthenticationMiddleware`)
)

func extractPythonAuthentication(root string) ([]model.AuthenticationFact, error) {
	var registrations []middlewareReg
	classesByName := map[string]classDef{}
	var factories []factoryInfo
	var abacCalls []abacSignal
	fileContents := map[string]string{}

	err := walkPythonFiles(root, func(relative, content string) error {
		fileContents[relative] = content

		for _, match := range pyAddMiddlewareRe.FindAllStringSubmatchIndex(content, -1) {
			className := content[match[2]:match[3]]
			cond := findConfigCondition(content, match[0])
			registrations = append(registrations, middlewareReg{
				className:   className,
				conditional: cond,
				source:      sourceRef(relative, content, content[match[0]:match[1]]),
			})
		}

		for _, match := range pyClassDefRe.FindAllStringSubmatch(content, -1) {
			name := match[1]
			if _, exists := classesByName[name]; !exists {
				classesByName[name] = classDef{
					name: name,
					file: relative,
					body: extractClassBody(content, name),
				}
			}
		}

		for _, match := range pyFactoryDefRe.FindAllStringSubmatchIndex(content, -1) {
			funcName := content[match[2]:match[3]]
			funcBody := extractFuncBody(content, funcName)
			var branches []string
			for _, ret := range pyFactoryReturnRe.FindAllStringSubmatch(funcBody, -1) {
				branches = append(branches, ret[1])
			}
			factories = append(factories, factoryInfo{
				name:     funcName,
				file:     relative,
				branches: branches,
			})
		}

		for _, match := range pyAbacCallRe.FindAllStringSubmatchIndex(content, -1) {
			funcName := content[match[2]:match[3]]
			callLine := extractCallLine(content, match[0])
			gating := pyAbacNegRe.MatchString(callLine) || pyAbacFilterRe.MatchString(callLine) || pyAbacReturnRe.MatchString(callLine)
			if !gating {
				continue
			}
			var action string
			callForward := content[match[0]:]
			if len(callForward) > 200 {
				callForward = callForward[:200]
			}
			if actionMatch := pyAbacActionRe.FindStringSubmatch(callForward); len(actionMatch) > 1 {
				action = actionMatch[1]
			}
			className := findEnclosingClass(content, match[0])
			abacCalls = append(abacCalls, abacSignal{
				function: funcName,
				action:   action,
				file:     relative,
				line:     sourceLine(content, content[match[0]:match[1]]),
				class:    className,
			})
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	var facts []model.AuthenticationFact

	for _, reg := range registrations {
		if reg.className == "AuthenticationMiddleware" && starletteAuthImported(fileContents) {
			facts = append(facts, model.AuthenticationFact{
				Endpoint:         "HTTP API",
				Methods:          "All",
				Mechanism:        "Bearer token (Starlette AuthenticationMiddleware)",
				EnforcementPoint: "ASGI middleware (starlette.middleware.authentication.AuthenticationMiddleware)",
				Policy:           policyForRegistration(reg),
				Source:           reg.source,
			})
			continue
		}

		cls, ok := classesByName[reg.className]
		if !ok {
			continue
		}
		classContent := cls.body
		if classContent == "" {
			continue
		}
		if !pyBearerRe.MatchString(classContent) || !pyDenialRe.MatchString(classContent) {
			continue
		}
		if !pyTokenValRe.MatchString(classContent) && !pyFactoryCallRe.MatchString(classContent) {
			continue
		}
		if pyQuotaRe.MatchString(cls.name) {
			continue
		}

		mechanism := classifyMiddlewareMechanism(classContent)
		facts = append(facts, model.AuthenticationFact{
			Endpoint:         "HTTP API",
			Methods:          "All",
			Mechanism:        mechanism,
			EnforcementPoint: "ASGI middleware (" + reg.className + ")",
			Policy:           policyForRegistration(reg),
			Source:           reg.source,
		})

		if factoryCallMatch := pyFactoryCallRe.FindStringSubmatch(classContent); len(factoryCallMatch) > 1 {
			calledFactory := factoryCallMatch[1]
			for _, factory := range factories {
				if factory.name != calledFactory {
					continue
				}
				for _, branch := range factory.branches {
					providerCls, ok := classesByName[branch]
					if !ok {
						continue
					}
					providerBody := providerCls.body
					if providerBody == "" || !hasConcreteValidation(providerBody) {
						continue
					}
					if pyQuotaRe.MatchString(branch) {
						continue
					}
					providerMech := classifyProviderMechanism(providerBody)
					facts = append(facts, model.AuthenticationFact{
						Endpoint:         "HTTP API",
						Methods:          "All",
						Mechanism:        providerMech,
						EnforcementPoint: "Auth provider (" + branch + " via factory)",
						Policy:           "Runtime-selectable provider",
						Source:           sourceRef(providerCls.file, fileContents[providerCls.file], "class "+branch),
					})
				}
			}
		}
	}

	surfaces := collectABACSurfaces(abacCalls)
	for _, surface := range surfaces {
		facts = append(facts, model.AuthenticationFact{
			Endpoint:         surface.name + " operations",
			Methods:          strings.Join(surface.actions, ", "),
			Mechanism:        "ABAC enforcement (" + surface.function + ")",
			EnforcementPoint: surface.name + " control flow",
			Policy:           "Operation-gating: denies or filters based on policy and authenticated user attributes",
			Source:           surface.source,
		})
	}

	return facts, nil
}

func findConfigCondition(content string, matchIndex int) string {
	before := content[:matchIndex]
	lines := strings.Split(before, "\n")
	// Start from the second-to-last line; the last element is the partial
	// text on the match line (often pure indentation) and must be skipped.
	for i := len(lines) - 2; i >= 0 && i >= len(lines)-7; i-- {
		line := strings.TrimSpace(lines[i])
		if strings.HasPrefix(line, "if ") && strings.HasSuffix(line, ":") {
			return strings.TrimSpace(strings.TrimSuffix(strings.TrimPrefix(line, "if "), ":"))
		}
		if line == "" || strings.HasPrefix(line, "def ") || strings.HasPrefix(line, "class ") {
			break
		}
	}
	return ""
}

func extractClassBody(content, className string) string {
	re := regexp.MustCompile(`(?m)^class\s+` + regexp.QuoteMeta(className) + `\s*(?:\([^)]*\))?\s*:`)
	loc := re.FindStringIndex(content)
	if loc == nil {
		return ""
	}
	rest := content[loc[1]:]
	endRe := regexp.MustCompile(`(?m)^(?:class |def )\w`)
	endLoc := endRe.FindStringIndex(rest)
	if endLoc == nil {
		return rest
	}
	return rest[:endLoc[0]]
}

func extractFuncBody(content, funcName string) string {
	re := regexp.MustCompile(`(?m)^def\s+` + regexp.QuoteMeta(funcName) + `\s*\(`)
	loc := re.FindStringIndex(content)
	if loc == nil {
		return ""
	}
	rest := content[loc[1]:]
	endRe := regexp.MustCompile(`(?m)^(?:class |def )\w`)
	endLoc := endRe.FindStringIndex(rest)
	if endLoc == nil {
		return rest
	}
	return rest[:endLoc[0]]
}

func extractCallLine(content string, callIndex int) string {
	lineStart := strings.LastIndex(content[:callIndex], "\n") + 1
	lineEnd := strings.Index(content[callIndex:], "\n")
	if lineEnd < 0 {
		lineEnd = len(content) - callIndex
	}
	return content[lineStart : callIndex+lineEnd]
}

func findEnclosingClass(content string, callIndex int) string {
	before := content[:callIndex]
	matches := pyClassDefRe.FindAllStringSubmatch(before, -1)
	if len(matches) == 0 {
		return ""
	}
	return matches[len(matches)-1][1]
}

func classifyMiddlewareMechanism(body string) string {
	if pyBearerRe.MatchString(body) {
		return "Bearer token"
	}
	return "Token-based authentication"
}

func hasConcreteValidation(body string) bool {
	return pyTokenValRe.MatchString(body) && (pyJWTRe.MatchString(body) || pyHTTPDelegateRe.MatchString(body))
}

func classifyProviderMechanism(body string) string {
	hasJWT := pyJWTRe.MatchString(body)
	hasHTTP := pyHTTPDelegateRe.MatchString(body)
	if hasJWT && hasHTTP {
		return "OAuth2 JWT/JWKS or token introspection"
	}
	if hasJWT {
		return "OAuth2 JWT/JWKS validation"
	}
	if hasHTTP {
		return "External HTTP authentication delegation"
	}
	return "Token validation"
}

func surfaceNameFromClass(className string) string {
	if className == "" {
		return "Protected resource"
	}
	var words []string
	start := 0
	for i := 1; i < len(className); i++ {
		if className[i] >= 'A' && className[i] <= 'Z' && className[i-1] >= 'a' && className[i-1] <= 'z' {
			words = append(words, className[start:i])
			start = i
		}
	}
	words = append(words, className[start:])
	var clean []string
	for _, w := range words {
		lower := strings.ToLower(w)
		if lower == "impl" || lower == "common" || lower == "base" || lower == "default" || lower == "abstract" || lower == "mixin" {
			continue
		}
		clean = append(clean, lower)
	}
	if len(clean) == 0 {
		return "Protected resource"
	}
	result := strings.Join(clean, " ")
	return strings.ToUpper(result[:1]) + result[1:]
}

func collectABACSurfaces(calls []abacSignal) []abacGroup {
	type surfaceKey struct {
		file     string
		class    string
		function string
	}
	groupMap := map[surfaceKey]*abacGroup{}
	var order []surfaceKey

	for _, call := range calls {
		key := surfaceKey{file: call.file, class: call.class, function: call.function}
		group, ok := groupMap[key]
		if !ok {
			name := surfaceNameFromClass(call.class)
			group = &abacGroup{
				name:     name,
				function: call.function,
				source:   fmt.Sprintf("%s:%d", call.file, call.line),
			}
			groupMap[key] = group
			order = append(order, key)
		}
		if call.action != "" && !stringSliceContains(group.actions, call.action) {
			group.actions = append(group.actions, call.action)
		}
	}

	var result []abacGroup
	for _, key := range order {
		g := groupMap[key]
		sort.Strings(g.actions)
		result = append(result, *g)
	}
	return result
}

func stringSliceContains(slice []string, value string) bool {
	for _, s := range slice {
		if s == value {
			return true
		}
	}
	return false
}

func starletteAuthImported(fileContents map[string]string) bool {
	for _, content := range fileContents {
		if pyStarletteAuthImportRe.MatchString(content) {
			return true
		}
	}
	return false
}

func policyForRegistration(reg middlewareReg) string {
	if reg.conditional != "" {
		return "Configuration-conditional (" + reg.conditional + ")"
	}
	return "Source-defined authentication"
}
