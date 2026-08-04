workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages OGX inference servers"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"

        ogxOperator = softwareSystem "ogx-k8s-operator" "Manages lifecycle of OGX inference servers on Kubernetes via OGXServer and LlamaStackDistribution CRDs" {
            ogxServerController = container "OGXServer Controller" "Reconciles OGXServer CRs into Deployments, Services, HPAs, PDBs, NetworkPolicies, Ingresses" "Go / controller-runtime 0.23.3"
            configMapReconciler = container "ConfigMap Reconciler" "Watches ConfigMaps for configuration-driven rollouts" "Go / controller-runtime"
            validatingWebhook = container "Validating Webhook" "Validates OGXServer CREATE/UPDATE operations (failurePolicy: Fail)" "Go / controller-runtime Webhook"
            ogxModuleController = container "OGX Module Controller" "Manages OGX operator lifecycle as platform component via OGX CR" "Go / controller-runtime 0.23.3"
            configGen = container "configgen" "Generates static configuration artifacts for OGX server deployments" "Go CLI"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane for resource operations" "External" {
            tags "External"
        }

        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring stack via ServiceMonitors and PrometheusRules" "Internal Platform" {
            tags "Internal Platform"
        }

        odhPlatformUtilities = softwareSystem "odh-platform-utilities" "Platform detection, kustomize rendering, garbage collection, labeling" "Internal Platform" {
            tags "Internal Platform"
        }

        openShiftAPI = softwareSystem "OpenShift API Server" "Provides cluster TLS profile configuration via config.openshift.io" "External" {
            tags "External"
        }

        odhPlatform = softwareSystem "OpenDataHub / RHOAI Platform" "Platform operator that creates OGX component CR" "Internal Platform" {
            tags "Internal Platform"
        }

        # Relationships - User
        user -> ogxOperator "Creates OGXServer / LlamaStackDistribution CRs via kubectl" "HTTPS/6443"
        platformAdmin -> odhPlatform "Configures platform components"

        # Relationships - Platform
        odhPlatform -> ogxOperator "Creates OGX CR to deploy operator" "Kubernetes API"

        # Relationships - Operator internals
        ogxServerController -> kubernetesAPI "CRUD on Deployments, Services, ConfigMaps, HPAs, PDBs, NetworkPolicies, Ingresses, PVCs" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        ogxServerController -> prometheusOperator "Creates ServiceMonitors and PrometheusRules" "Kubernetes API"
        validatingWebhook -> kubernetesAPI "Validates admission requests" "HTTPS/9443, TLS"
        ogxModuleController -> kubernetesAPI "Manages ClusterRoles, ClusterRoleBindings, Deployments, ValidatingWebhookConfigurations" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        ogxModuleController -> odhPlatformUtilities "Uses for kustomize rendering, platform detection, GC" "Go library (in-process)"
        ogxServerController -> openShiftAPI "Reads TLS profile for cipher suite configuration" "HTTPS/6443"
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
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
