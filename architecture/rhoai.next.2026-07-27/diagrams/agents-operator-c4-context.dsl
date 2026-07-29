workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys AI agents using AgentRuntime and AgentCard CRs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration via DataScienceCluster"

        agentsOperator = softwareSystem "agents-operator" "Kubernetes operator for managing AI agent runtimes with AuthBridge authentication sidecars" {
            controllerManager = container "Controller Manager" "Reconciles AgentCard, AgentRuntime, and platform CRDs; manages agent lifecycle, certificates, network policies, and RBAC" "Go Operator"
            webhookServer = container "Webhook Server" "Validates AgentCard/AgentRuntime CRs and injects AuthBridge sidecars into agent Pods" "Go Admission Webhook"
            authbridgeEnvoy = container "authbridge-envoy" "Envoy External Processing sidecar for agent-to-agent authentication" "Go gRPC Service"
            authbridgeProxy = container "authbridge-proxy" "Full HTTP reverse/forward proxy sidecar with JWT, OPA, mTLS, and token exchange" "Go HTTP Proxy"
            authbridgeLite = container "authbridge-lite" "Size-optimized proxy sidecar variant" "Go HTTP Proxy"
            tokenBroker = container "token-broker" "Manages OAuth2 session tokens and credential exchange for agents" "Go HTTP Service"
            agentcardSigner = container "agentcard-signer" "Signs agent cards using sigstore for integrity verification" "Go CLI"
            bundleService = container "bundle-service" "Serves agent bundles" "Go HTTP Service"
        }

        certManager = softwareSystem "cert-manager" "Automated TLS certificate management for Kubernetes" "External"
        spire = softwareSystem "SPIRE / SPIFFE" "Workload identity issuance via X.509-SVIDs for mTLS" "External"
        keycloak = softwareSystem "Keycloak" "Identity provider and realm management" "External"
        kuadrant = softwareSystem "Kuadrant" "API gateway and rate limiting" "External"
        tekton = softwareSystem "Tekton" "CI/CD pipeline engine" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry" "Internal RHOAI"
        dsc = softwareSystem "DataScienceCluster" "RHOAI platform feature gating and component configuration" "Internal RHOAI"
        openshiftRoutes = softwareSystem "OpenShift Routes" "External traffic ingress for agent endpoints" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster resource management and RBAC enforcement" "External"
        envoyProxy = softwareSystem "Envoy Proxy" "Service proxy for external processing integration" "External"

        # User interactions
        dataScientist -> agentsOperator "Creates AgentRuntime and AgentCard CRs via kubectl"
        platformAdmin -> dsc "Configures platform features"

        # Operator → Platform dependencies
        agentsOperator -> certManager "Creates Certificate and Issuer CRDs for agent TLS" "Kubernetes API"
        agentsOperator -> spire "Requests X.509-SVIDs for workload mTLS" "SPIFFE Workload API"
        agentsOperator -> keycloak "Manages realm imports and identity provider config" "Kubernetes API"
        agentsOperator -> kuadrant "Configures API gateway policies" "Kubernetes API"
        agentsOperator -> tekton "Patches TektonConfig for pipeline integration" "Kubernetes API"
        agentsOperator -> mlflow "Watches MLflow instances for experiment tracking" "Kubernetes API"
        agentsOperator -> dsc "Reads enabled platform components for feature gating" "Kubernetes API"
        agentsOperator -> openshiftRoutes "Creates Routes for agent external exposure" "Kubernetes API"
        agentsOperator -> k8sAPI "Manages Deployments, StatefulSets, Services, NetworkPolicies, RBAC" "HTTPS/6443"
        agentsOperator -> envoyProxy "Receives per-request processing callouts" "gRPC ExtProc"

        # Internal container relationships
        controllerManager -> webhookServer "Serves admission webhooks"
        webhookServer -> authbridgeProxy "Injects as sidecar into agent Pods"
        webhookServer -> authbridgeEnvoy "Injects as sidecar into agent Pods"
        webhookServer -> authbridgeLite "Injects as sidecar into agent Pods"
        authbridgeProxy -> tokenBroker "Exchanges tokens for outbound requests" "HTTP POST /sessions/token"
        authbridgeEnvoy -> envoyProxy "Receives gRPC External Processing callouts" "gRPC"
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
            element "Internal RHOAI" {
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
