workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages OGX server instances via OGXServer CRs"
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform components"

        ogxOperator = softwareSystem "ogx-k8s-operator" "Kubernetes operator that deploys and manages OGX server instances on OpenShift" {
            controller = container "OGXServer Controller" "Reconciles OGXServer CRs into workload resources using runtime kustomize rendering with Go transformer plugins" "Go Operator (controller-runtime)"
            webhook = container "OGXServer Webhook" "Validates OGXServer resources on CREATE and UPDATE; enforces distribution, provider, volume, and access rules" "Admission Webhook"
            kustomizePipeline = container "Kustomize Pipeline" "Embedded kustomize filesystem with Go-based transformer plugins for runtime manifest rendering" "In-process"
            securityWatcher = container "SecurityProfileWatcher" "Watches OpenShift cluster TLS profile and triggers graceful restart on change" "Go Controller"
            kubeRBACProxy = container "kube-rbac-proxy" "TLS termination and Kubernetes RBAC-based authorization proxy for metrics endpoint" "Sidecar Container"
        }

        ogxModule = softwareSystem "ogx-module" "Platform-level component controller that manages the root ogx-k8s-operator deployment as part of ODH/RHOAI" {
            moduleController = container "OGX Module Controller" "Reconciles cluster-scoped OGX CR to deploy or remove the root operator using kustomize overlays" "Go Controller (controller-runtime)"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Core Kubernetes control plane API" "External"
        odhPlatform = softwareSystem "ODH/RHOAI Platform Operator" "Platform operator that manages component lifecycle" "Internal Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring resources (ServiceMonitor, PrometheusRule)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Auto-provisions TLS certificates for cluster services" "External"
        openshiftTLSConfig = softwareSystem "OpenShift TLS Profile" "Cluster-wide TLS security policy configuration" "External"
        certManager = softwareSystem "cert-manager" "Certificate management for non-OpenShift clusters" "External"

        # User interactions
        dataScientist -> ogxOperator "Creates OGXServer CR via kubectl" "HTTPS/6443"
        platformAdmin -> odhPlatform "Configures platform components"

        # Platform tier
        odhPlatform -> ogxModule "Creates OGX CR" "Kubernetes API"
        ogxModule -> kubernetesAPI "Deploys root operator resources" "HTTPS/6443"
        ogxModule -> ogxOperator "Manages operator lifecycle"

        # Operator interactions
        ogxOperator -> kubernetesAPI "CRUD on CRs and managed resources via server-side apply" "HTTPS/6443"
        ogxOperator -> prometheusOperator "Creates ServiceMonitor and PrometheusRule CRs" "Kubernetes API"
        prometheus -> ogxOperator "Scrapes /metrics endpoint" "HTTPS/8443"
        openshiftServiceCA -> ogxOperator "Provisions TLS certificates" "Annotation-driven"
        openshiftTLSConfig -> ogxOperator "Provides TLS profile configuration" "Kubernetes API"
        certManager -> ogxOperator "Provisions TLS certificates (non-OpenShift)" "CRD-driven"

        # Internal container interactions
        controller -> webhook "Triggers validation"
        controller -> kustomizePipeline "Renders manifests"
        controller -> securityWatcher "Receives TLS profile updates"
        prometheus -> kubeRBACProxy "Authenticated metrics scrape" "HTTPS/8443"
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

        container ogxModule "ModuleContainers" {
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
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
