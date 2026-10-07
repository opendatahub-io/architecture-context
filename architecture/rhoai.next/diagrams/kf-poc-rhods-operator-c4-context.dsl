workspace {
    model {
        admin = person "Platform Admin" "Configures RHOAI platform via DataScienceCluster and DSCInitialization CRDs"

        kfPocRhodsOperator = softwareSystem "kf-poc-rhods-operator" "Platform operator orchestrating lifecycle of all RHOAI data science components through cluster-scoped CRDs" {
            dscReconciler = container "DataScienceClusterReconciler" "Reconciles DSC CR to deploy/remove 11 data science components via kustomize manifests" "Go Controller"
            dsciReconciler = container "DSCInitializationReconciler" "Bootstraps platform infrastructure: namespace, monitoring, Service Mesh, trusted CA" "Go Controller"
            secretGen = container "SecretGeneratorReconciler" "Auto-generates OAuth secrets for components, manages OAuthClient lifecycle" "Go Controller"
            certGen = container "CertConfigmapGeneratorReconciler" "Distributes trusted CA bundle ConfigMaps across namespaces" "Go Controller"
            webhook = container "Admission Webhooks" "Validates singleton constraint, sets ModelRegistry defaults, CRD conversion" "Go Service"
        }

        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster control plane" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management" "External"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Maistra-based Istio service mesh" "External"
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform" "External"
        authorino = softwareSystem "Authorino" "Authentication and authorization (Kuadrant)" "External"
        prometheusOp = softwareSystem "prometheus-operator" "Monitoring and alerting" "External"
        tekton = softwareSystem "OpenShift Pipelines" "Tekton-based pipeline infrastructure" "External"
        modelRegistryOp = softwareSystem "Model Registry Operator" "Model registry instance management" "External"
        olm = softwareSystem "Operator Lifecycle Manager" "Operator installation and lifecycle" "External"

        dashboard = softwareSystem "Dashboard" "RHOAI web console" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving with serverless inference" "Internal RHOAI"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving platform" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "ML workflow pipelines" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Distributed compute framework" "Internal RHOAI"
        ray = softwareSystem "Ray" "Distributed computing runtime" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing and scheduling" "Internal RHOAI"
        trustyai = softwareSystem "TrustyAI" "Model explainability and fairness" "Internal RHOAI"
        trainingOp = softwareSystem "Training Operator" "Distributed training jobs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage" "Internal RHOAI"

        admin -> kfPocRhodsOperator "Creates DSC/DSCI CRs via kubectl" "HTTPS/6443"
        kfPocRhodsOperator -> kubernetesAPI "All resource CRUD and watches" "HTTPS/6443"
        kfPocRhodsOperator -> certManager "Manages Certificates and Issuers" "CRD CRUD"
        kfPocRhodsOperator -> serviceMesh "Manages SMCP, SMMR, SMM" "CRD CRUD"
        kfPocRhodsOperator -> knativeServing "Manages KnativeServing CR" "CRD CRUD"
        kfPocRhodsOperator -> authorino "Manages Authorino and AuthConfig" "CRD CRUD"
        kfPocRhodsOperator -> prometheusOp "Manages ServiceMonitor, PrometheusRule" "CRD CRUD"
        kfPocRhodsOperator -> tekton "Manages Tekton resources" "CRD CRUD"
        kfPocRhodsOperator -> modelRegistryOp "Manages ModelRegistry CR" "CRD CRUD"
        kfPocRhodsOperator -> olm "Watches CatalogSource, CSV" "CRD Watch"

        kfPocRhodsOperator -> dashboard "Deploys via kustomize manifests"
        kfPocRhodsOperator -> workbenches "Deploys via kustomize manifests"
        kfPocRhodsOperator -> kserve "Deploys via kustomize manifests"
        kfPocRhodsOperator -> modelmesh "Deploys via kustomize manifests"
        kfPocRhodsOperator -> dsPipelines "Deploys via kustomize manifests"
        kfPocRhodsOperator -> codeflare "Deploys via kustomize manifests"
        kfPocRhodsOperator -> ray "Deploys via kustomize manifests"
        kfPocRhodsOperator -> kueue "Deploys via kustomize manifests"
        kfPocRhodsOperator -> trustyai "Deploys via kustomize manifests"
        kfPocRhodsOperator -> trainingOp "Deploys via kustomize manifests"
        kfPocRhodsOperator -> modelRegistry "Deploys via kustomize manifests"
    }

    views {
        systemContext kfPocRhodsOperator "SystemContext" {
            include *
            autoLayout
        }

        container kfPocRhodsOperator "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
