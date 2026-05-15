workspace {
    model {
        admin = person "Platform Admin" "Configures and manages the RHOAI platform via DSC/DSCI CRs"
        endUser = person "Data Scientist" "Uses RHOAI platform services (notebooks, model serving, pipelines)"

        rhodsOperator = softwareSystem "rhods-operator" "Central control plane for RHOAI — orchestrates lifecycle of all platform components, gateway/ingress, auth, and monitoring" {
            manager = container "manager" "Main operator binary: DSC controller, DSCI controller, 16 component controllers, 5 service controllers, 14 webhook handlers" "Go Operator (controller-runtime)"
            cloudmanager = container "cloudmanager" "Cloud provider controller for AKS/CoreWeave — manages Helm-based dependency installation" "Go Controller (controller-runtime)"
            webhookServer = container "Webhook Server" "Admission webhooks: singleton validation, HW profile injection, connection mutation, deprecation blocking" "Go (port 9443/TCP)"
            kubeAuthProxy = container "kube-auth-proxy" "OAuth2/OIDC authentication proxy for gateway ext_authz" "oauth2-proxy (port 8443/TCP)"
            dashboardRedirect = container "dashboard-redirect" "Legacy URL redirect service (301 to new Gateway)" "nginx (port 8080/TCP)"
        }

        gatewayEnvoy = softwareSystem "Istio/Envoy Gateway" "Kubernetes Gateway API data plane with EnvoyFilter ext_authz for authentication" "Infrastructure"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for RHOAI platform" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference serving" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration (Argo-based)" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata storage" "Internal RHOAI"
        kubeRay = softwareSystem "KubeRay" "Ray cluster orchestration" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Batch scheduling and resource management" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Distributed ML training" "Internal RHOAI"
        trustyAI = softwareSystem "TrustyAI" "Model explainability" "Internal RHOAI"
        feast = softwareSystem "Feast Operator" "Feature store" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook controllers" "Internal RHOAI"
        mlflow = softwareSystem "MLflow Operator" "Experiment tracking" "Internal RHOAI"
        maas = softwareSystem "MaaS Controller" "Models-as-a-Service" "Internal RHOAI"
        ogx = softwareSystem "OGX" "OGX operator" "Internal RHOAI"
        sparkOp = softwareSystem "Spark Operator" "Spark job orchestration" "Internal RHOAI"
        modelController = softwareSystem "Model Controller" "ODH model controller" "Internal RHOAI"
        trainer = softwareSystem "Trainer" "Kubeflow Training v2" "Internal RHOAI"

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server" "Infrastructure"
        oauthServer = softwareSystem "OpenShift OAuth" "Integrated OAuth2 authentication" "Infrastructure"
        oidcProvider = softwareSystem "External OIDC Provider" "External identity provider" "External"
        certManager = softwareSystem "cert-manager" "X.509 certificate lifecycle" "Infrastructure"
        istio = softwareSystem "Istio (Sail)" "Service mesh and Envoy sidecar injection" "Infrastructure"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and upgrades" "Infrastructure"
        coo = softwareSystem "Cluster Observability Operator" "Platform monitoring stack (Prometheus, Thanos)" "Infrastructure"
        segmentIO = softwareSystem "Segment.IO" "Usage telemetry collection" "External"

        # Admin interactions
        admin -> rhodsOperator "Creates DSCInitialization + DataScienceCluster CRs" "kubectl/oc"
        endUser -> gatewayEnvoy "Accesses platform services" "HTTPS/443"

        # Operator → K8s
        manager -> k8sApi "CRUD on all managed resources" "HTTPS/6443 (SA token)"
        cloudmanager -> k8sApi "Deploy Helm charts" "HTTPS/6443 (SA token)"
        k8sApi -> webhookServer "Admission webhook calls" "HTTPS/9443 (mTLS)"

        # Gateway authentication chain
        gatewayEnvoy -> kubeAuthProxy "ext_authz check" "HTTPS/8443 (TLS)"
        kubeAuthProxy -> oauthServer "OAuth2 flow" "HTTPS/443 (TLS 1.2+)"
        kubeAuthProxy -> oidcProvider "OIDC flow" "HTTPS/443 (TLS 1.2+)"

        # Component deployments
        manager -> dashboard "Deploys via Kustomize + SSA"
        manager -> kserve "Deploys via Kustomize + SSA"
        manager -> dsp "Deploys via Kustomize + SSA"
        manager -> modelRegistry "Deploys via Kustomize + SSA"
        manager -> kubeRay "Deploys via Kustomize + SSA"
        manager -> kueue "Deploys via Kustomize + SSA"
        manager -> trainingOp "Deploys via Kustomize + SSA"
        manager -> trustyAI "Deploys via Kustomize + SSA"
        manager -> feast "Deploys via Kustomize + SSA"
        manager -> workbenches "Deploys via Kustomize + SSA"
        manager -> mlflow "Deploys via Kustomize + SSA"
        manager -> maas "Deploys via Kustomize + SSA"
        manager -> ogx "Deploys via Kustomize + SSA"
        manager -> sparkOp "Deploys via Kustomize + SSA"
        manager -> modelController "Deploys via Kustomize + SSA"
        manager -> trainer "Deploys via Kustomize + SSA"

        # Infrastructure dependencies
        manager -> gatewayEnvoy "Configures Gateway, EnvoyFilter, DestinationRule"
        manager -> certManager "TLS certificate management"
        manager -> coo "Deploys MonitoringStack, ThanosQuerier"

        # Cloud manager
        cloudmanager -> istio "Installs Sail Operator via Helm (XKS)"
        cloudmanager -> certManager "Installs cert-manager via Helm (XKS)"

        # Telemetry
        manager -> segmentIO "Usage telemetry" "HTTPS/443"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
