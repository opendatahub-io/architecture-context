workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages OGX inference servers on RHOAI"

        ogxOperator = softwareSystem "ogx-k8s-operator" "Kubernetes operator managing OGX inference servers on RHOAI, reconciling OGXServer CRs into fully configured deployments" {
            ogxController = container "OGXServerReconciler" "Watches OGXServer CRs and reconciles into Deployments, Services, HPAs, PDBs, NetworkPolicies, ConfigMaps, Ingresses, PVCs" "Go controller-runtime"
            webhook = container "Validating Webhook" "Enforces OGXServer schema integrity on CREATE and UPDATE with Fail policy" "Go controller-runtime webhook"
            configgen = container "configgen" "Generates runtime configuration from distribution specifications" "Go CLI"
        }

        ogxModule = softwareSystem "ogx-module" "Platform-level controller managing the OGX component CRD for RHOAI operator installation" {
            moduleReconciler = container "OGX Reconciler" "Watches OGX platform CR and renders kustomize manifests for operator installation" "Go controller-runtime"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            apiServer = container "API Server" "Kubernetes REST API for resource management" "Kubernetes"
        }

        openshift = softwareSystem "OpenShift Platform" "Red Hat OpenShift Container Platform" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Manages Prometheus monitoring resources" "External"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Shared library for platform detection, kustomize rendering, and deployment helpers" "Internal ODH"

        # Relationships
        user -> ogxOperator "Creates OGXServer CRs via kubectl/API"
        ogxController -> apiServer "CRUD operations on child resources" "HTTPS/6443 TLS 1.2+"
        ogxController -> prometheusOperator "Creates PrometheusRules and ServiceMonitors" "HTTPS"
        webhook -> apiServer "Receives admission reviews" "HTTPS/9443 TLS"
        ogxController -> openshift "Fetches APIServer TLS profile" "HTTPS/6443"

        moduleReconciler -> apiServer "Manages operator installation resources" "HTTPS/6443 TLS 1.2+"
        moduleReconciler -> odhPlatformUtils "Uses for kustomize rendering and platform detection" "Go library"

        ogxModule -> ogxOperator "Installs and manages operator lifecycle"
    }

    views {
        systemContext ogxOperator "SystemContext" {
            include *
            autoLayout
        }

        container ogxOperator "OGXOperatorContainers" {
            include *
            autoLayout
        }

        container ogxModule "OGXModuleContainers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
