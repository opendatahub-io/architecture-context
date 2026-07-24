workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys AI agents and tools on Kubernetes"
        platformeng = person "Platform Engineer" "Configures agent platform security and identity"

        kagentiOperator = softwareSystem "Kagenti Operator (agents-operator)" "Kubernetes operator that automates deployment, discovery, identity, mutual authentication, and observability of AI agents and tools" {
            manager = container "kagenti-operator" "Main operator binary — runs 10+ controllers and 3 webhooks for AgentRuntime, AgentCard, NetworkPolicy, MLflow, Keycloak, SharedTrust, TLSBridgeCA, AuthBridgeConfig, Kuadrant, TektonConfig" "Go Operator (controller-runtime)" "Operator"
            mutatingWebhook = container "Mutating Webhook" "Intercepts Pod CREATE events and injects AuthBridge sidecars, SPIRE volumes, proxy-init containers, and Keycloak credentials" "Go Webhook Handler" "Webhook"
            validatingWebhook = container "Validating Webhook" "Validates AgentRuntime and AgentCard CRs — enforces uniqueness, mTLS/authbridge compatibility" "Go Webhook Handler" "Webhook"
            authbridgeProxy = container "authbridge-proxy" "Sidecar injected into agent pods — provides JWT validation, token exchange, forward/reverse proxy, mTLS transport, TLS bridge" "Go Sidecar" "Sidecar"
            proxyInit = container "proxy-init" "Init container that configures iptables REDIRECT rules for transparent traffic interception" "Go Init Container" "InitContainer"
            bundleService = container "bundle-service" "Serves OPA authorization policy bundles to AuthBridge clients via HTTP with identity-based access control" "Go Service" "Service"
        }

        kubernetes = softwareSystem "Kubernetes" "Core platform — API server, RBAC, admission control" "External"
        keycloak = softwareSystem "Keycloak" "OAuth2/OIDC identity provider — client registration, JWT validation, token exchange" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management — webhook TLS, metrics TLS, TLS Bridge CA, SharedTrust CA chain" "External"
        spire = softwareSystem "SPIRE" "SPIFFE workload identity provider — SVID provisioning, mTLS, trust bundles via CSI driver" "External"
        mlflow = softwareSystem "MLflow" "ML experiment tracking and tracing" "External"
        kuadrant = softwareSystem "Kuadrant" "API gateway rate limiting and auth policy" "External"
        istio = softwareSystem "Istio" "Service mesh — ambient mode enrollment, CA cert chain sync" "External"
        tekton = softwareSystem "Tekton" "CI/CD pipeline platform — TektonConfig integration" "External"
        sigstore = softwareSystem "Sigstore" "Supply-chain attestation verification — Rekor transparency log, Fulcio CA" "External"
        openshift = softwareSystem "OpenShift" "Container platform — SCC, Routes, Network operator" "Internal RHOAI"
        rhoai = softwareSystem "RHOAI (DataScienceCluster)" "Red Hat OpenShift AI platform — detects MLflow component state" "Internal RHOAI"

        # User interactions
        datascientist -> kagentiOperator "Creates AgentRuntime and AgentCard CRs via kubectl" "HTTPS/6443"
        platformeng -> kagentiOperator "Configures platform identity, mTLS modes, feature gates" "HTTPS/6443"

        # Operator dependencies
        kagentiOperator -> kubernetes "CRD CRUD, RBAC, ConfigMap/Secret management" "HTTPS/6443"
        kagentiOperator -> keycloak "OAuth2 client registration, audience scopes, token exchange config" "HTTP/8080"
        kagentiOperator -> certManager "Certificate, Issuer, ClusterIssuer CR management" "HTTPS/6443 (K8s API)"
        kagentiOperator -> spire "SPIFFE workload identity, SVID provisioning" "gRPC/Unix Socket"
        kagentiOperator -> mlflow "Experiment creation and management" "HTTP(S)/80,443"
        kagentiOperator -> kuadrant "API gateway operand management" "HTTPS/6443 (K8s API)"
        kagentiOperator -> istio "Ambient mesh enrollment, CA cert sync" "HTTPS/6443 (K8s API)"
        kagentiOperator -> tekton "TektonConfig patching for kagenti integration" "HTTPS/6443 (K8s API)"
        kagentiOperator -> sigstore "Supply-chain bundle attestation verification" "In-process"
        kagentiOperator -> openshift "SCC management, Route discovery, Network validation" "HTTPS/6443 (K8s API)"
        kagentiOperator -> rhoai "Detect MLflow component enabled state" "HTTPS/6443 (K8s API)"

        # Container-level interactions
        manager -> mutatingWebhook "Hosts webhook handler" ""
        manager -> validatingWebhook "Hosts webhook handler" ""
        mutatingWebhook -> authbridgeProxy "Injects sidecar into pods" ""
        mutatingWebhook -> proxyInit "Injects init container into pods" ""
        bundleService -> authbridgeProxy "Serves OPA policy bundles" "HTTP/8080"
        authbridgeProxy -> keycloak "JWT validation, token exchange" "HTTP(S)"
        authbridgeProxy -> spire "mTLS identity (SVID)" "gRPC/Unix Socket"
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
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #e8744f
                color #ffffff
            }
            element "Sidecar" {
                background #9b59b6
                color #ffffff
            }
            element "InitContainer" {
                background #9b59b6
                color #ffffff
            }
            element "Service" {
                background #2ecc71
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
        }
    }
}
