workspace {
    model {
        user = person "User / Data Scientist" "Creates OGXServer CRs to deploy AI inference stacks"
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform components"

        ogxOperator = softwareSystem "ogx-k8s-operator" "Kubernetes operator managing OGX inference server workloads with multiple distribution backends" {
            controllerManager = container "ogx-k8s-operator-controller-manager" "Reconciles OGXServer CRs into Deployments, Services, PVCs, NetworkPolicies, PDBs, HPAs, Ingresses, and monitoring resources" "Go controller-runtime Operator"
            webhookServer = container "Webhook Server" "Validates OGXServer CREATE/UPDATE with distribution name, Praxis mode, and immutability checks" "Go Admission Webhook" "9443/TCP"
            kustomizeRenderer = container "Kustomize Renderer" "Renders base manifests with runtime transforms (name prefixes, namespace injection, mutations)" "In-process kustomize"
            distributionRegistry = container "Distribution Registry" "Maps distribution names to container images (starter, remote-vLLM, meta-reference-gpu, postgres-demo)" "Embedded JSON config"
            securityProfileWatcher = container "SecurityProfileWatcher" "Monitors OpenShift TLS profile changes and triggers operator restart" "Go watcher"
        }

        ogxModule = softwareSystem "ogx-module" "ODH/RHOAI platform module that manages ogx-k8s-operator deployment lifecycle" {
            moduleController = container "OGX Reconciler" "Reconciles cluster-scoped OGX CRs to deploy the root operator with platform-specific overlays" "Go controller-runtime Operator"
        }

        kubeAPI = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "External"
        openshiftAPI = softwareSystem "OpenShift APIServer" "Provides cluster TLS profiles and platform configuration" "External"
        prometheus = softwareSystem "Prometheus / Cluster Monitoring" "Collects metrics via ServiceMonitor" "External"
        certSigner = softwareSystem "service-serving-cert-signer" "Provisions TLS certificates for OpenShift services" "External"
        certManager = softwareSystem "cert-manager" "Provisions TLS certificates for non-OpenShift clusters" "External"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Shared library for platform detection, manifest rendering, and garbage collection" "Internal ODH"
        platformOperator = softwareSystem "ODH/RHOAI Platform Operator" "Manages platform component lifecycle via component CRs" "Internal ODH"

        ogxServerPods = softwareSystem "OGX Server Pods" "AI inference server workloads running various distribution backends" "Managed"

        // User interactions
        user -> ogxOperator "Creates OGXServer CRs via kubectl" "HTTPS/6443"
        platformAdmin -> platformOperator "Enables OGX component"

        // Platform deployment flow
        platformOperator -> ogxModule "Creates OGX CR (cluster-scoped)"
        ogxModule -> kubeAPI "Deploys operator resources via kustomize" "HTTPS/6443"
        moduleController -> odhPlatformUtils "Uses for platform detection, manifest rendering, GC" "Go library"

        // Operator flows
        ogxOperator -> kubeAPI "Resource CRUD, watches, leader election, SSA" "HTTPS/6443"
        ogxOperator -> openshiftAPI "Reads cluster TLS profile" "HTTPS/6443"
        ogxOperator -> ogxServerPods "Health polling (/v1/providers, /v1/version)" "HTTP"
        ogxOperator -> prometheus "Exposes metrics via ServiceMonitor" "HTTPS/8443"

        // Certificate provisioning
        certSigner -> ogxOperator "Provisions webhook and metrics TLS certs"
        certManager -> ogxOperator "Provisions certs on non-OpenShift" "Alternative"

        // Internal relationships
        controllerManager -> webhookServer "Hosts"
        controllerManager -> kustomizeRenderer "Renders manifests"
        controllerManager -> distributionRegistry "Resolves distribution images"
        controllerManager -> securityProfileWatcher "TLS profile monitoring"
    }

    views {
        systemContext ogxOperator "SystemContext" {
            include *
            autoLayout
        }

        container ogxOperator "OperatorContainers" {
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Managed" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
