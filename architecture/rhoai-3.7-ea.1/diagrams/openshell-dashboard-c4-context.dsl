workspace "openshell-dashboard" "RHOAI 3.7-ea.1 - Web admin UI and BFF for an NVIDIA OpenShell gateway" {
    model {
        user = person "OpenShell User / Admin" "Manages workspaces, sandboxes, policies and providers through the browser"

        dashboard = softwareSystem "openshell-dashboard" "Web admin UI and Go backend-for-frontend for one OpenShell gateway; stateless relay-only BFF" {
            proxy = container "oauth2-proxy" "OIDC sign-in, encrypted session cookie, token refresh; forwards access token to BFF. Only network entry point (4180/TCP)" "Go, oauth2-proxy v7.15.2 (sidecar)"
            bff = container "BFF Server" "REST API under /api/v1 on 127.0.0.1:8080; relays each request to the gateway over gRPC with the user's bearer token" "Go, chi router"
            spa = container "Frontend SPA" "Admin UI for workspaces, sandboxes, policies, providers, gateway overview" "React 18, TypeScript, PatternFly 6"
            clients = container "Gateway Clients" "OpenShell Go SDK client plus raw gRPC clients (exec stdin, provider key names, provider profiles)" "Go, gRPC"
        }

        ingress = softwareSystem "OpenShift Router / Gateway API" "External exposure and TLS termination (Route edge/reencrypt or HTTPRoute)" "External"
        gateway = softwareSystem "OpenShell Gateway" "NVIDIA OpenShell sandboxing gateway 0.1.x; validates tokens, enforces RBAC and workspace membership, runs sandboxes" "Internal Platform"
        oidc = softwareSystem "OIDC Provider (Keycloak)" "Identity, roles (openshell-admin / openshell-user), access tokens trusted by the gateway" "External"

        user -> ingress "Uses dashboard" "HTTPS/443"
        user -> oidc "Signs in (redirect)" "HTTPS/443 OIDC auth code + PKCE"
        ingress -> proxy "Forwards" "HTTP or HTTPS/4180"
        proxy -> oidc "Token exchange, refresh, logout" "HTTPS/443"
        proxy -> bff "Proxies with X-Forwarded-Access-Token" "HTTP/8080 loopback"
        bff -> spa "Serves static files"
        bff -> clients "Invokes"
        clients -> gateway "All operations, Bearer token per RPC" "gRPC/8080 TLS 1.2+"
        gateway -> oidc "Fetches JWKS" "HTTPS/443"
    }

    views {
        systemContext dashboard "SystemContext" {
            include *
            autoLayout
        }

        container dashboard "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
            }
        }
    }
}
