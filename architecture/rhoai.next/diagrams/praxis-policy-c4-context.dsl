workspace {
    model {
        aiAgent = person "AI Agent / LLM" "Untrusted principal generating tool calls, prompt completions, and A2A requests"
        operator = person "Platform Operator" "Configures APL policy, manages credentials, selects PDP dialect"

        praxisProxy = softwareSystem "Praxis Proxy" "AI gateway that intercepts and governs all agent-to-tool traffic" {
            gateway = container "Praxis Gateway" "Pingora-based reverse proxy with HTTP/gRPC interception" "Rust Service"
            ppe = container "Praxis Policy Engine (PPE)" "Embedded reference monitor: identity resolution, authorization, delegation, redaction, taint tracking, audit" "Rust Library" {
                core = component "PolicyEngine" "Five-phase executor: sequential, transform, audit, concurrent, fire-and-forget" "Rust"
                aplRuntime = component "APL Runtime" "Route compiler, predicate evaluator, session manager" "Rust"
                jwtPlugin = component "JWT Identity Plugin" "RS256/ES256/EdDSA signature verification via jsonwebtoken (aws_lc_rs)" "Rust"
                apiKeyPlugin = component "API-Key Identity Plugin" "SHA-256 digest-based key verification" "Rust"
                cedarPdp = component "Cedar PDP" "cedar-policy 4 evaluation engine" "Rust"
                celPdp = component "CEL PDP" "CEL 0.14.5 expression evaluator" "Rust"
                opaPdp = component "OPA PDP" "regorus 0.12 Rego interpreter (restricted builtins)" "Rust"
                oauthDelegator = component "OAuth Delegator" "RFC 8693 token exchange with bounded coalescing cache" "Rust"
                cibaPlugin = component "CIBA Elicitation" "Out-of-band human approval via backchannel" "Rust"
                valkeySession = component "Valkey Session Store" "Taint label persistence via Redis protocol" "Rust"
                vaultSecrets = component "Vault Secrets" "KV v2 secret retrieval" "Rust"
                egressResolver = component "EgressResolver" "SSRF protection: blocks private, link-local, loopback, CGNAT, checks resolved addresses" "Rust"
            }
        }

        idp = softwareSystem "Identity Provider" "Keycloak, Auth0, or compatible OIDC provider" "External"
        valkey = softwareSystem "Valkey / Redis" "Session taint label persistence store" "External"
        vault = softwareSystem "HashiCorp Vault" "KV v2 secret backend for credential retrieval" "External"
        upstreamTools = softwareSystem "Upstream Tools & Services" "MCP servers, A2A agents, inference endpoints, databases" "External"

        # Relationships
        aiAgent -> praxisProxy "Sends tool/prompt/inference/A2A requests" "HTTPS/443"
        operator -> praxisProxy "Configures APL policy and credentials" "Config files, Vault, env"

        gateway -> ppe "Dispatches every agent operation through policy pipeline" "In-process Rust API"
        ppe -> idp "Fetches JWKS, exchanges tokens (RFC 8693), CIBA backchannel" "HTTPS/443, TLS 1.2+"
        ppe -> valkey "Reads/writes session taint labels" "TCP/6379, TLS optional"
        ppe -> vault "Retrieves secrets for credential injection" "HTTPS/8200, TLS 1.2+"
        gateway -> upstreamTools "Forwards allowed requests with delegated credentials" "HTTPS/gRPC"

        # Internal component flows
        core -> aplRuntime "Evaluates route predicates and effects"
        core -> jwtPlugin "identity.resolve hook"
        core -> apiKeyPlugin "identity.resolve hook"
        core -> cedarPdp "authorization.decide hook"
        core -> celPdp "authorization.decide hook"
        core -> opaPdp "authorization.decide hook"
        core -> oauthDelegator "delegation.exchange hook"
        core -> cibaPlugin "elicitation.approve hook"
        core -> valkeySession "session.read / session.write"
        core -> vaultSecrets "secrets.resolve"
        jwtPlugin -> idp "GET JWKS" "HTTPS/443"
        oauthDelegator -> idp "POST token exchange" "HTTPS/443"
        cibaPlugin -> idp "POST CIBA backchannel" "HTTPS/443"
        valkeySession -> valkey "GET/SET taint labels" "TCP/6379"
        vaultSecrets -> vault "GET secret" "HTTPS/8200"
    }

    views {
        systemContext praxisProxy "SystemContext" {
            include *
            autoLayout
        }

        container praxisProxy "Containers" {
            include *
            autoLayout
        }

        component ppe "Components" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
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
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
