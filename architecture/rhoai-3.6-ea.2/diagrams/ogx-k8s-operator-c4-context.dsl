workspace {
    model {
        user = person "Data Scientist / Admin" "Creates OGXServer CRs to deploy inference endpoints"
        platformAdmin = person "Platform Admin" "Enables OGX component via ODH/RHOAI platform"

        ogxOperator = softwareSystem "OGX K8s Operator" "Two-layer operator for OGX inference server lifecycle management" {
            ogxServerController = container "OGXServer Controller" "Reconciles OGXServer CRs to deploy inference server workloads" "Go Operator (controller-runtime)"
            ogxModuleController = container "OGX Module Controller" "Reconciles OGX platform CRs to deploy the root operator" "Go Operator (controller-runtime)"
            webhook = container "Validating Webhook" "Validates OGXServer create/update requests" "Go Service, 9443/TCP HTTPS"
            kustomizeRenderer = container "Kustomize Renderer" "In-process manifest rendering from embedded base templates" "Go Library"
            distributionsRegistry = container "distributions.json" "Embedded distribution image registry" "JSON Config"
            securityProfileWatcher = container "SecurityProfileWatcher" "Auto-reloads TLS on OpenShift profile changes" "Go Component"
        }

        odhPlatformOperator = softwareSystem "ODH/RHOAI Platform Operator" "Manages platform components" "Internal ODH"
        praxis = softwareSystem "Praxis (MaaS Gateway)" "Multi-tenant inference gateway" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring CRD management" "Internal ODH"
        odhTrustedCA = softwareSystem "ODH Trusted CA Bundle" "CA certificate distribution" "Internal ODH"

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource CRUD and admission" "External"
        openShiftAPI = softwareSystem "OpenShift API Server" "TLS profile and platform configuration" "External"
        containerRegistry = softwareSystem "Container Registry" "OCI image hosting and label inspection" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate provisioning (non-OpenShift)" "External"

        # User interactions
        user -> ogxOperator "Creates OGXServer CRs via kubectl"
        platformAdmin -> odhPlatformOperator "Enables OGX component"

        # Platform deployment flow
        odhPlatformOperator -> ogxOperator "Creates OGX CR to deploy operator" "Kubernetes API"

        # Internal flows
        ogxServerController -> kustomizeRenderer "Renders manifests" "In-process"
        ogxServerController -> distributionsRegistry "Resolves distribution images" "In-process"
        ogxServerController -> webhook "Admission validation" "HTTPS/9443"
        securityProfileWatcher -> ogxServerController "Triggers restart on TLS change"
        ogxModuleController -> ogxServerController "Deploys root operator" "Kubernetes API"

        # External integrations
        ogxOperator -> k8sAPI "Resource CRUD, SSA apply, leader election" "HTTPS/6443"
        ogxOperator -> openShiftAPI "Fetch TLS profile" "HTTPS/6443"
        ogxOperator -> containerRegistry "OCI label inspection" "HTTPS/443"
        ogxOperator -> certManager "TLS cert provisioning (non-OpenShift)" "Kubernetes API"
        ogxOperator -> prometheusOperator "Creates ServiceMonitor, PrometheusRule" "Kubernetes API"
        ogxOperator -> odhTrustedCA "Reads CA bundle ConfigMap" "Kubernetes API"

        # Praxis integration
        praxis -> ogxOperator "Sole authorized ingress in Praxis mode" "HTTP/8321"
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
            element "Internal ODH" {
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
