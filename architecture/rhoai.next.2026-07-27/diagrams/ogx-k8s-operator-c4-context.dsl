workspace {
    model {
        admin = person "Platform Admin" "Configures and deploys OGX server instances via OGXServer CRs"

        ogxOperator = softwareSystem "ogx-k8s-operator" "Kubernetes operator that manages OGX and OGXServer custom resources for ML/AI inference serving" {
            controllerManager = container "ogx-k8s-operator-controller-manager" "Main operator deployment running OGX and OGXServer controllers" "Go Operator"
            ogxController = container "OGX Controller" "Reconciles OGX component-level resources (CRDs, RBAC, webhooks, deployments)" "Go Controller"
            ogxServerController = container "OGXServer Controller" "Reconciles OGXServer instances (deployments, services, config, networking)" "Go Controller"
            webhookValidator = container "OGXServerValidator" "Validates OGXServer CRs on CREATE/UPDATE for distribution name, provider ID uniqueness" "Go Webhook Handler"
            configgen = container "configgen" "Offline CLI tool for generating declarative config from OGXServer CR specs via OCI label resolution" "Go CLI"
            metricsProxy = container "kube-rbac-proxy" "Protects /metrics endpoint via TokenReview and SubjectAccessReview" "Sidecar"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "kube-apiserver" "Kubernetes API server" "Kubernetes"
        }

        prometheus = softwareSystem "Prometheus Operator" "Monitoring and alerting platform" "Internal RHOAI"
        openshift = softwareSystem "OpenShift" "OpenShift platform APIs (config.openshift.io, security.openshift.io)" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Stores container images and OCI artifacts" "External"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection, manifest rendering, and deployment helpers" "Internal RHOAI"

        # Relationships
        admin -> ogxOperator "Creates OGX and OGXServer CRs via kubectl"
        ogxOperator -> kubernetes "Watches CRs, creates/manages Kubernetes resources" "HTTPS/6443 TLS 1.2+"
        ogxOperator -> prometheus "Creates ServiceMonitors and PrometheusRules" "Kubernetes API"
        ogxOperator -> openshift "Reads OpenShift API server config, uses SCCs" "HTTPS/6443"
        ogxOperator -> ociRegistry "Resolves OCI labels for config generation" "HTTPS/443"

        ogxController -> apiServer "Reconciles OGX component resources" "HTTPS/WSS TLS 1.2+"
        ogxServerController -> apiServer "Reconciles OGXServer instance resources" "HTTPS/WSS TLS 1.2+"
        webhookValidator -> apiServer "Receives admission webhook calls" "TLS/9443"

        prometheus -> metricsProxy "Scrapes metrics" "HTTPS/8443 TokenReview+SAR"
    }

    views {
        systemContext ogxOperator "SystemContext" {
            include *
            autoLayout
        }

        container ogxOperator "Containers" {
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
                shape person
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
