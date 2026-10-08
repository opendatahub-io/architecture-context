workspace {
    model {
        platformAdmin = person "Platform Admin" "Manages ODH/RHOAI platform components"

        feastModuleOperator = softwareSystem "Feast Module Operator" "Module operator that deploys and manages the upstream Feast feature store operator on the ODH/RHOAI platform" {
            controller = container "opendatahub-feast-operator" "Main controller binary; reconciles FeastOperator CRs to deploy the upstream feast-operator via kustomize manifests" "Go Operator"
            chartgen = container "chartgen" "Generates Helm charts from kustomize manifests for alternative deployment without the ODH operator" "Go CLI subcommand"
            manifests = container "Kustomize Manifests" "Embedded kustomize bases and platform-specific overlays (ODH/RHOAI)" "Kustomize"
            kubeRbacProxy = container "kube-rbac-proxy" "Protects /metrics endpoint with TokenReview and SubjectAccessReview" "Sidecar"
        }

        odhOperator = softwareSystem "ODH Operator" "Platform operator that deploys module operators via Helm charts and creates component CRs" "Internal RHOAI"
        feastOperator = softwareSystem "Feast Operator" "Upstream feast-operator that manages FeatureStore CRs and deploys feast infrastructure" "Deployed Component"

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "Infrastructure"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Infrastructure"

        feastFeatureStore = softwareSystem "Feast FeatureStore" "Feature store resources managed by feast-operator" "feast.dev"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Notebook resources for ML workflows" "kubeflow.org"
        mlflow = softwareSystem "MLflow" "ML experiment tracking" "mlflow.opendatahub.io"
        openshiftRoutes = softwareSystem "OpenShift Routes" "External route exposure" "route.openshift.io"
        spark = softwareSystem "Spark" "Spark applications for data processing" "sparkoperator.k8s.io"
        odhPlatformUtils = softwareSystem "odh-platform-utilities" "Platform detection and cache optimization" "Go Library"
        odhOperatorLib = softwareSystem "opendatahub-operator/v2" "Reconciler framework and action pipeline" "Go Library"

        # Relationships
        platformAdmin -> odhOperator "Configures platform components"
        odhOperator -> feastModuleOperator "Deploys via Helm chart and creates FeastOperator CR" "HTTPS/6443"

        controller -> manifests "Reads and renders kustomize manifests"
        controller -> kubeRbacProxy "Metrics proxied through"

        controller -> kubernetesAPI "CRD watches, resource CRUD, leader election, status updates" "HTTPS/6443"
        controller -> feastOperator "Deploys feast-operator controller manager, CRDs, RBAC" "via Kubernetes API"

        prometheus -> kubeRbacProxy "Scrapes /metrics" "HTTPS/8443"

        feastOperator -> feastFeatureStore "Manages FeatureStore lifecycle" "HTTPS/6443"
        feastOperator -> kubeflowNotebooks "Watches Notebook resources" "HTTPS/6443"
        feastOperator -> mlflow "Watches MLflow resources" "HTTPS/6443"
        feastOperator -> openshiftRoutes "Manages Routes for external access" "HTTPS/6443"
        feastOperator -> spark "Manages SparkApplications" "HTTPS/6443"

        controller -> odhPlatformUtils "Platform detection, cache field stripping"
        controller -> odhOperatorLib "Reconciler framework, action pipeline, deploy/GC/status actions"
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
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Deployed Component" {
                background #9b59b6
                color #ffffff
            }
            element "Go Library" {
                background #e8e8e8
                color #333333
            }
            element "feast.dev" {
                background #f5a623
                color #ffffff
            }
            element "kubeflow.org" {
                background #f5a623
                color #ffffff
            }
            element "mlflow.opendatahub.io" {
                background #f5a623
                color #ffffff
            }
            element "route.openshift.io" {
                background #f5a623
                color #ffffff
            }
            element "sparkoperator.k8s.io" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
