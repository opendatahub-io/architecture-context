workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages the ODH/RHOAI platform installation and configuration"

        feastModuleOperator = softwareSystem "Feast Module Operator" "Module operator that deploys and manages the upstream Feast operator as a component within ODH/RHOAI" {
            controller = container "feast-module-operator" "Watches FeastOperator CRs and reconciles feast-operator deployment via kustomize" "Go Operator (controller-runtime)"
            chartgen = container "chartgen" "Generates Helm chart from kustomize output at build time" "Go CLI Tool"
            initContainer = container "copy-manifests" "Copies bundled kustomize manifests from operator image to emptyDir volume" "Init Container"
        }

        platformOperator = softwareSystem "ODH Platform Operator" "Manages platform-level components and creates FeastOperator CRs" "Internal Platform"
        feastOperator = softwareSystem "Feast Operator (upstream)" "Manages FeatureStore CRs for the Feast feature store" "Deployed Workload"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management, watches, and RBAC" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook server management (read-only watch)" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Route management for service exposure" "Infrastructure"

        # Relationships
        platformAdmin -> platformOperator "Configures platform components"
        platformOperator -> feastModuleOperator "Creates FeastOperator CR and deploys via Helm chart" "HTTPS/443"
        platformOperator -> kubernetesAPI "Writes platformVersion to ConfigMap" "HTTPS/443"

        feastModuleOperator -> kubernetesAPI "Watches CRs, applies resources, leader election" "HTTPS/443 TLS 1.2+ SA Token"
        feastModuleOperator -> feastOperator "Deploys via rendered kustomize manifests" "HTTPS/443"

        feastOperator -> kubernetesAPI "Manages FeatureStore CRs" "HTTPS/443"

        prometheus -> feastModuleOperator "Scrapes operator metrics" "HTTPS/8443 TLS Bearer Token"

        # Build-time relationship
        chartgen -> controller "Generates Helm chart from kustomize" "Build-time"
        initContainer -> controller "Populates /opt/manifests via emptyDir" "Runtime init"
    }

    views {
        systemContext feastModuleOperator "SystemContext" {
            include *
            autoLayout
        }

        container feastModuleOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Deployed Workload" {
                background #e1d5e7
                color #333333
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
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
