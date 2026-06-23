workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys AI agents on RHOAI"
        platformAdmin = person "Platform Admin" "Manages RHOAI cluster and agent infrastructure"

        kagentiOperator = softwareSystem "Kagenti Operator (agents-operator)" "Automates deployment, discovery, security, and observability of AI agents in RHOAI clusters" {
            operatorController = container "kagenti-operator" "Manages AgentRuntime, AgentCard, AuthorizationPolicy CRDs; injects AuthBridge sidecars via mutating webhook; manages agent identity, discovery, and network policies" "Go Operator (controller-runtime)"
            mutatingWebhook = container "Mutating Webhook" "Injects AuthBridge sidecar containers into agent pods at admission time" "Kubernetes Admission Webhook"
            validatingWebhook = container "Validating Webhook" "Validates AgentCard and AgentRuntime resources for uniqueness and configuration constraints" "Kubernetes Admission Webhook"
            bundleService = container "bundle-service" "Watches AuthorizationPolicy CRs and serves compiled OPA/Rego policy bundles to AuthBridge sidecar clients" "Go Service"
            authbridgeProxy = container "authbridge-proxy" "HTTP forward+reverse proxy sidecar providing JWT validation, token exchange, mTLS, OPA policy enforcement, and protocol-aware request parsing" "Go Sidecar Proxy"
        }

        # Platform Services
        keycloak = softwareSystem "Keycloak" "OAuth2/OIDC identity provider for agent authentication and client registration" "Platform Service"
        spire = softwareSystem "SPIRE" "SPIFFE-based workload identity for mTLS and JWT SVIDs" "Platform Service"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks, TLS bridge CA, and shared trust" "Platform Service"
        istio = softwareSystem "Istio" "Service mesh for ambient mesh enrollment and CA rotation" "Platform Service"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and model lifecycle management" "Internal RHOAI"
        dataScienceCluster = softwareSystem "DataScienceCluster" "RHOAI platform operator that manages component lifecycle" "Internal RHOAI"

        # External Services
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD reconciliation and RBAC" "Infrastructure"
        sigstore = softwareSystem "Sigstore (Rekor/Fulcio)" "Supply-chain verification for SignedAgentCard bundles" "External"
        phoenix = softwareSystem "Phoenix" "OpenInference trace export for agent observability" "External"

        # Optional Platform Components
        kuadrant = softwareSystem "Kuadrant" "Rate limiting for agent workloads" "Platform Service"
        tekton = softwareSystem "Tekton" "CI/CD pipeline configuration" "Platform Service"

        # Relationships - User to System
        dataScientist -> kagentiOperator "Creates AgentRuntime and AgentCard CRs to deploy and register AI agents" "kubectl / RHOAI Dashboard"
        platformAdmin -> kagentiOperator "Configures platform settings, feature gates, and AuthorizationPolicies" "kubectl / Helm"

        # Relationships - System to Dependencies
        kagentiOperator -> keycloak "Bootstraps realm, registers per-agent OAuth2 clients, validates JWTs" "REST API / OAuth2, 8080/TCP"
        kagentiOperator -> spire "Acquires X.509/JWT SVIDs for mTLS, verified card fetch, trust bundle" "gRPC, Unix Socket"
        kagentiOperator -> certManager "Manages webhook TLS certificates, TLS bridge CAs, shared trust assembly" "CRD Watch"
        kagentiOperator -> istio "Enrolls namespaces in ambient mesh, restarts on CA rotation" "Namespace Labels"
        kagentiOperator -> mlflow "Auto-discovers instances, creates experiments, injects tracking env vars" "CRD Watch + REST API, HTTPS"
        kagentiOperator -> dataScienceCluster "Detects RHOAI platform, triggers MLflow operand reconciliation" "CRD Watch"
        kagentiOperator -> kubernetesAPI "CRD reconciliation, RBAC, webhook registration, resource management" "HTTPS, 6443/TCP"
        kagentiOperator -> sigstore "Verifies SignedAgentCard supply-chain signatures" "HTTPS, 443/TCP"
        kagentiOperator -> phoenix "Exports OpenInference traces via OTel collector" "gRPC, 4317/TCP"
        kagentiOperator -> kuadrant "Creates and drift-reconciles Kuadrant CR for rate limiting" "CRD Create/Patch"
        kagentiOperator -> tekton "Patches TektonConfig for security context and SCC" "CRD Patch"

        # Container-level relationships
        operatorController -> mutatingWebhook "Registers" ""
        operatorController -> validatingWebhook "Registers" ""
        operatorController -> keycloak "Client registration, realm management" "REST API"
        operatorController -> spire "Verified card fetch, trust bundle" "gRPC"
        operatorController -> certManager "Certificate/Issuer CRD management" "CRD Watch"
        authbridgeProxy -> keycloak "JWT validation, token exchange" "OAuth2/OIDC"
        authbridgeProxy -> spire "X.509/JWT SVID acquisition" "gRPC"
        authbridgeProxy -> bundleService "OPA policy bundle download" "HTTP, 8080/TCP"
    }

    views {
        systemContext kagentiOperator "SystemContext" {
            include *
            autoLayout
        }

        container kagentiOperator "Containers" {
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
            element "Platform Service" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
