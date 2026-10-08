workspace {
    model {
        user = person "User" "Data scientist, ML engineer, or platform admin managing AI agent sandboxes"

        openshellDashboard = softwareSystem "OpenShell Dashboard" "Web admin UI and Go BFF for managing sandboxed AI agent runtimes, workspaces, providers, policies, and templates" {
            bff = container "Go BFF Server" "HTTP/REST API server that relays authenticated requests to the OpenShell gateway via gRPC, serves static frontend assets, and provides WebSocket terminal relay" "Go (chi router), 8080/TCP"
            frontend = container "React Frontend" "PatternFly 6 SPA for workspace, sandbox, provider, policy, and template management; published as npm package for downstream embedding" "TypeScript, React, PatternFly 6"
            sdkClient = container "OpenShell Go SDK Client" "Primary gRPC client using official NVIDIA OpenShell Go SDK" "Go"
            rawClients = container "Raw gRPC Clients" "Three escape-hatch clients for SDK gaps: rawexec (file uploads), rawprovider (credential keys), rawprofile (provider profiles)" "Go, gRPC"
        }

        authProxy = softwareSystem "Auth Proxy" "OAuth2 proxy that owns OIDC login flow, session management, and bearer token injection" "External"
        openshellGateway = softwareSystem "OpenShell Gateway" "NVIDIA OpenShell gateway providing sandbox, workspace, provider, policy, template, and service management via gRPC API; validates JWT and enforces RBAC" "External"
        rhoai = softwareSystem "RHOAI Platform" "Red Hat OpenShift AI — embeds OpenShell Dashboard frontend as npm package" "Internal"

        # Relationships
        user -> authProxy "Authenticates via OIDC" "HTTPS/443, TLS 1.3"
        authProxy -> openshellDashboard "Forwards authenticated requests with bearer token" "HTTP(S)/8080"
        user -> openshellDashboard "Manages workspaces, sandboxes, policies via web UI" "HTTPS/443 (through auth proxy)"

        frontend -> bff "REST API calls + WebSocket terminal" "HTTP(S)/8080"
        bff -> sdkClient "Delegates API operations"
        bff -> rawClients "File uploads, credential keys, provider profiles"
        sdkClient -> openshellGateway "gRPC API calls" "gRPC/50051, TLS 1.2+"
        rawClients -> openshellGateway "Direct gRPC for SDK gaps" "gRPC/50051, TLS 1.2+"

        rhoai -> frontend "Imports as npm package" "npm dependency"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
