workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages the ODH/RHOAI platform deployment"
        dataScientist = person "Data Scientist" "Creates FeatureStore instances for ML feature management"

        feastModuleOperator = softwareSystem "Feast Module Operator" "Module operator that deploys and manages the upstream Feast operator on OpenShift as part of ODH/RHOAI" {
            controller = container "feast-module-operator" "Watches FeastOperator CR, renders kustomize manifests, deploys upstream Feast operator" "Go Operator (controller-runtime)"
            chartgen = container "chartgen" "Generates Helm chart from kustomize output for standalone deployment" "Go CLI Subcommand"
            initContainer = container "copy-manifests" "Copies bundled kustomize manifests from operator image to shared volume" "Init Container"
        }

        platformOperator = softwareSystem "rhods-operator / opendatahub-operator" "Parent platform operator that manages module operator lifecycle" "Internal Platform"
        upstreamFeastOperator = softwareSystem "Upstream Feast Operator" "feast-dev/feast-operator - manages FeatureStore CRs and deploys Feast components" "Deployed Artifact"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Cluster monitoring stack" "Internal Platform"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Infrastructure"

        # Relationships
        platformAdmin -> platformOperator "Configures platform"
        platformOperator -> feastModuleOperator "Creates FeastOperator CR and odh-feastoperator-config ConfigMap" "HTTPS/443"
        feastModuleOperator -> upstreamFeastOperator "Deploys via kustomize manifests (Deployment, CRDs, RBAC)"
        feastModuleOperator -> kubernetesAPI "CR watches, resource CRUD, leader election" "HTTPS/443 TLS 1.2+"
        dataScientist -> upstreamFeastOperator "Creates FeatureStore CRs via kubectl"
        prometheus -> feastModuleOperator "Scrapes metrics via ServiceMonitor" "HTTPS/8443 TLS"
        platformOperator -> kubernetesAPI "Platform version handshake via ConfigMap" "HTTPS/443"

        initContainer -> controller "Copies manifests to shared emptyDir volume"
    }

    views {
        systemContext feastModuleOperator "SystemContext" {
            include *
            autoLayout
            description "Feast Module Operator in the ODH/RHOAI ecosystem"
        }

        container feastModuleOperator "Containers" {
            include *
            autoLayout
            description "Internal components of the Feast Module Operator"
        }

        styles {
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Deployed Artifact" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
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
