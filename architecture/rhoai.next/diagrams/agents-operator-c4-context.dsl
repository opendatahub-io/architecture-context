workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys AI agents on OpenShift AI"
        platformadmin = person "Platform Admin" "Manages RHOAI platform and agent infrastructure"

        agentsOperator = softwareSystem "Agents Operator" "Automates deployment, discovery, identity, authentication, and observability for AI agents" {
            manager = container "kagenti-operator (manager)" "Core controller with 10+ controllers and 3 webhooks managing AgentRuntime/AgentCard lifecycle" "Go Operator (controller-runtime)"
            authbridgeProxy = container "authbridge-proxy" "HTTP forward/reverse proxy sidecar with mTLS, JWT validation, token exchange, and protocol plugins (A2A, MCP, Inference, IBAC)" "Go Sidecar Proxy"
            authbridgeEnvoy = container "authbridge-envoy" "Envoy external processing gRPC server for envoy-sidecar mode" "Go ext_proc Service"
            authbridgeLite = container "authbridge-lite" "Lightweight proxy-sidecar with auth gates only" "Go Sidecar Proxy"
            tokenBroker = container "token-broker" "OAuth2 session broker with PKCE flows and in-memory token caching" "Go Service"
            bundleService = container "bundle-service" "OPA policy bundle distributor watching AuthorizationPolicy CRs" "Go Service"
            sparcService = container "sparc-service" "SPARC reflection service wrapping ALTK for pre-tool reflection" "Python FastAPI"
            agentcardSigner = container "agentcard-signer" "JWS signing of agent cards using SPIRE X.509 SVIDs" "Go CLI"
            proxyInit = container "proxy-init" "iptables setup for transparent traffic interception" "Shell Init Container"
        }

        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD reconciliation and workload management" "Infrastructure"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Internal Platform"
        keycloak = softwareSystem "Keycloak" "Identity provider for OAuth2/OIDC authentication and client registration" "Internal Platform"
        spire = softwareSystem "SPIRE" "SPIFFE-based workload identity and mTLS credential management" "Internal Platform"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model registry" "Internal Platform"
        kuadrant = softwareSystem "Kuadrant" "API gateway policy management" "Internal Platform"
        tekton = softwareSystem "Tekton" "CI/CD pipeline framework for agent build workflows" "Internal Platform"
        dsc = softwareSystem "DataScienceCluster" "RHOAI platform component configuration" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Route management for external access" "Infrastructure"
        envoyProxy = softwareSystem "Envoy Proxy" "Service proxy for ext_proc callouts" "Infrastructure"

        datascientist -> agentsOperator "Creates AgentRuntime CR via kubectl"
        platformadmin -> agentsOperator "Configures platform components and security policies"

        manager -> k8sAPI "CRD reconciliation, workload management" "HTTPS/6443"
        manager -> keycloak "Client registration, realm management" "HTTP/8080"
        manager -> spire "Workload identity, trust bundles" "In-process"
        manager -> certManager "Webhook TLS, SharedTrust CA" "HTTPS/6443 via K8s API"
        manager -> mlflow "Experiment creation, tracing config" "HTTP/HTTPS"
        manager -> kuadrant "API gateway policy CRUD" "HTTPS/6443 via K8s API"
        manager -> tekton "TektonConfig patch" "HTTPS/6443 via K8s API"
        manager -> dsc "Read enabled components" "HTTPS/6443 via K8s API"
        manager -> openshiftRoutes "Route CRUD" "HTTPS/6443 via K8s API"

        authbridgeProxy -> keycloak "RFC 8693 token exchange" "HTTP/8080"
        authbridgeProxy -> bundleService "Fetch OPA policy bundles" "HTTP/8080"
        authbridgeProxy -> tokenBroker "Session management" "HTTP/8080"
        tokenBroker -> keycloak "OAuth2 PKCE flows" "HTTP/8080"

        authbridgeEnvoy -> envoyProxy "ext_proc gRPC callouts" "gRPC/9090"
    }

    views {
        systemContext agentsOperator "SystemContext" {
            include *
            autoLayout
        }

        container agentsOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
