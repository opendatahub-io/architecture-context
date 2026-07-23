workspace {
    model {
        platformAdmin = person "Platform Admin" "Installs and configures RHOAI platform components"
        dataScientist = person "Data Scientist" "Creates FeatureStore instances for ML feature management"

        feastModuleOperator = softwareSystem "Feast Module Operator" "Module operator that manages the lifecycle of the upstream Feast operator within RHOAI" {
            controller = container "feast-module-operator" "Reconciles FeastOperator CR, renders and applies kustomize manifests for the upstream feast-operator" "Go Operator (controller-runtime)"
            initContainer = container "copy-manifests" "Copies bundled feast-operator kustomize manifests from operator image to shared emptyDir volume" "Init Container"
            chartgen = container "chartgen" "Build-time tool that generates Helm chart from kustomize output for standalone deployment" "Go CLI"
        }

        platformOperator = softwareSystem "Platform Operator" "opendatahub-operator / rhods-operator - manages platform component lifecycle" "Internal Platform"
        feastOperator = softwareSystem "Feast Operator (Upstream)" "Upstream feast-dev/feast operator that reconciles FeatureStore CRs" "Managed Component"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource management" "Infrastructure"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting" "Infrastructure"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook CRs read by feast-operator for notebook integration" "Internal Platform"

        # Relationships
        platformAdmin -> platformOperator "Installs platform and configures components"
        platformOperator -> feastModuleOperator "Creates FeastOperator CR and writes platform version ConfigMap" "HTTPS/443"
        feastModuleOperator -> kubernetesAPI "CRUD operations on CRDs, Deployments, RBAC, ConfigMaps" "HTTPS/443"
        feastModuleOperator -> feastOperator "Deploys and manages upstream feast-operator Deployment, CRDs, RBAC" "Kustomize manifests"
        dataScientist -> feastOperator "Creates FeatureStore CRs via kubectl" "HTTPS/443"
        feastOperator -> kubernetesAPI "Reconciles FeatureStore CRs, creates Deployments, Services, Routes" "HTTPS/443"
        feastOperator -> kubeflowNotebooks "Reads Notebook CRs for notebook integration" "HTTPS/443"
        prometheus -> feastModuleOperator "Scrapes /metrics endpoint via ServiceMonitor" "HTTPS/8443"

        # Container relationships
        initContainer -> controller "Copies manifests to shared emptyDir volume"
        controller -> kubernetesAPI "Watches FeastOperator CR, reads ConfigMaps, applies manifests" "HTTPS/443"
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
            element "Managed Component" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
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
