workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys AI agents on OpenShift"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and agent infrastructure"

        agentsOperator = softwareSystem "Kagenti Operator (agents-operator)" "Automates deployment, discovery, security, and observability of AI agents via A2A protocol, SPIFFE identity, and OAuth2 authentication" {
            controller = container "kagenti-operator" "Manages AgentRuntime and AgentCard CRDs, 14+ controllers, 3 webhooks" "Go Operator (controller-runtime)" "Operator"
            authbridge = container "AuthBridge Proxy" "HTTP forward/reverse proxy with mTLS, JWT validation, token exchange, protocol-aware plugins (A2A, MCP, Inference)" "Go Sidecar" "Sidecar"
            tokenBroker = container "Token Broker" "OAuth2 session broker -- PKCE flows, token caching, session lifecycle" "Go Service" "Support"
            bundleService = container "Bundle Service" "OPA policy bundle distributor -- watches AuthorizationPolicy CRs" "Go Service" "Support"
            agentcardSigner = container "AgentCard Signer" "JWS signing of A2A agent cards using SPIRE X.509 SVIDs" "Go CLI" "CLI"
        }

        keycloak = softwareSystem "Keycloak (RHBK)" "OAuth2 identity provider and client registration" "Platform"
        spire = softwareSystem "SPIRE (via ZTWIM)" "Workload identity management -- X.509/JWT-SVIDs, trust domain" "Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management" "Platform"
        istio = softwareSystem "Istio (ztunnel)" "Service mesh for ambient mTLS and traffic management" "Platform"
        mlflow = softwareSystem "MLflow" "Experiment tracking for AI agent workloads" "Platform"
        kuadrant = softwareSystem "Kuadrant" "API management operand" "Platform"
        tekton = softwareSystem "Tekton" "CI/CD pipeline configuration" "Platform"
        ovnKubernetes = softwareSystem "OVN-Kubernetes" "Network configuration and routing" "Platform"
        dataScienceCluster = softwareSystem "DataScienceCluster" "RHOAI platform orchestrator" "Platform"

        oauthProviders = softwareSystem "OAuth Providers" "External authorization servers" "External"
        sigstoreRekor = softwareSystem "Sigstore Rekor" "Supply-chain attestation transparency log" "External"

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD management" "Infrastructure"

        # User interactions
        dataScientist -> agentsOperator "Creates AgentRuntime CRs via kubectl" "HTTPS/6443"
        platformAdmin -> agentsOperator "Configures platform settings and feature gates"

        # Internal container relationships
        controller -> authbridge "Injects sidecar via mutating webhook" "HTTPS/9443"
        authbridge -> tokenBroker "Acquires tokens for outbound requests" "HTTP/8190"
        authbridge -> bundleService "Downloads OPA policy bundles" "HTTP/8080"

        # External integrations
        agentsOperator -> keycloak "Client registration, realm management, token exchange" "HTTP/8080, HTTPS/443"
        agentsOperator -> spire "X.509/JWT-SVID acquisition, trust domain management" "Unix socket, Kubernetes API"
        agentsOperator -> certManager "Certificate, Issuer, ClusterIssuer lifecycle" "Kubernetes API"
        agentsOperator -> istio "Namespace ambient mesh enrollment, CA rotation" "Kubernetes API"
        agentsOperator -> mlflow "Per-agent experiment provisioning" "HTTP/HTTPS"
        agentsOperator -> kuadrant "Kuadrant operand bootstrapping" "Kubernetes API"
        agentsOperator -> tekton "TektonConfig SCC and pruner configuration" "Kubernetes API"
        agentsOperator -> ovnKubernetes "Network routing validation" "Kubernetes API"
        agentsOperator -> dataScienceCluster "Watch for MLflow managed state" "Kubernetes API"
        agentsOperator -> kubernetesAPI "CRD watches, resource management" "HTTPS/6443"

        tokenBroker -> oauthProviders "PKCE authorization code exchange" "HTTPS/443"
        agentsOperator -> sigstoreRekor "Sigstore bundle verification (optional)" "HTTPS/443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Sidecar" {
                background #50c878
                color #ffffff
            }
            element "Support" {
                background #f5a623
                color #ffffff
            }
            element "CLI" {
                background #b0b0b0
                color #333333
            }
        }
    }
}
