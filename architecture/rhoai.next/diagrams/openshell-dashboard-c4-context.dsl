workspace {
    model {
        user = person "Platform User" "Manages AI agent sandboxes, providers, and security policies through the browser"
        admin = person "Platform Admin" "Configures global policies, gateway settings, and workspace membership"

        openshellDashboard = softwareSystem "OpenShell Dashboard" "Web admin UI and Go BFF for managing OpenShell sandboxed AI agent runtimes" {
            bff = container "Go BFF Server" "REST/WebSocket API server that translates browser requests to gateway gRPC calls; stateless token relay" "Go 1.26.7 + chi router" "WebApp"
            frontend = container "React Frontend" "Browser-based admin UI for workspace, sandbox, provider, and policy management" "TypeScript + React 18 + PatternFly 6" "WebBrowser"
            rawExecClient = container "Raw Exec Client" "Bypasses SDK for binary-safe file uploads via raw gRPC (non-TTY stdin)" "Go gRPC" "Component"
        }

        gateway = softwareSystem "OpenShell Gateway" "NVIDIA OpenShell agent sandboxing platform gateway — manages sandboxes, providers, policies, RBAC" "External"
        authProxy = softwareSystem "Auth Proxy" "OAuth2-proxy or platform-equivalent — handles OIDC flows, session management, CSRF, token injection" "External"
        oidcIdP = softwareSystem "OIDC Identity Provider" "Keycloak, Dex, or equivalent — issues JWTs, provides JWKS for validation" "External"

        # User interactions
        user -> frontend "Manages sandboxes, providers, policies via browser"
        admin -> frontend "Configures global policies and gateway settings"

        # Frontend to BFF
        frontend -> bff "REST API calls (/api/v1/*)" "HTTP(S)/8080"
        frontend -> bff "Interactive terminal session" "WebSocket/8080"

        # Auth flow
        user -> authProxy "Authenticates via OIDC" "HTTPS/443"
        admin -> authProxy "Authenticates via OIDC" "HTTPS/443"
        authProxy -> bff "Proxies requests with bearer token" "HTTP(S)/8080"
        authProxy -> oidcIdP "OIDC/OAuth2 authentication flows" "HTTPS"

        # BFF to Gateway
        bff -> gateway "All resource operations (workspaces, sandboxes, providers, policies)" "gRPC/50051"
        bff -> gateway "Interactive terminal relay (ExecSandboxInteractive)" "gRPC bidirectional stream/50051"
        rawExecClient -> gateway "Binary-safe file upload (ExecSandbox non-TTY)" "gRPC/50051"

        # Gateway auth
        gateway -> oidcIdP "Validates JWT via JWKS" "HTTPS"
    }

    views {
        systemContext openshellDashboard "SystemContext" {
            include *
            autoLayout
        }

        container openshellDashboard "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Container" {
                background #61affe
                color #ffffff
            }
            element "WebApp" {
                shape WebBrowser
            }
            element "WebBrowser" {
                shape WebBrowser
            }
            element "Component" {
                shape Component
            }
        }
    }
}
