workspace {
    model {
        clusterAdmin = person "Cluster Admin" "Deploys and configures RHOAI platform"
        dataScientist = person "Data Scientist" "Consumes inference services"

        odhGitops = softwareSystem "odh-gitops" "GitOps configuration repository providing Helm charts and Kustomize manifests for deploying RHOAI platform dependencies" {
            xksChart = container "rhai-on-xks-chart" "Non-OLM deployment for external Kubernetes services (Azure, CoreWeave, AWS)" "Helm Chart v3.5.0"
            ocpChart = container "rhai-on-openshift-chart" "OpenShift-native dependency installation with OLM operator subscriptions" "Helm Chart v3.4.0"
            operatorSubs = container "operator-subscriptions" "OLM Subscription declarations for platform operator dependencies" "Kustomize Overlay"
            operatorConfigs = container "operator-configurations" "Post-install configuration overlays for operator tuning" "Kustomize Overlay"
        }

        rhaiOperator = softwareSystem "RHAI Operator" "Manages RHOAI component lifecycle (opendatahub-operator)" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        aiGateway = softwareSystem "AIGateway" "Models-as-a-Service module for external model routing" "Internal RHOAI"
        certManager = softwareSystem "cert-manager" "TLS certificate issuance and rotation" "Dependency Operator"
        istio = softwareSystem "Istio (Sail Operator)" "Service mesh for gateway routing and mTLS" "Dependency Operator"
        authorino = softwareSystem "Authorino (rhcl-operator)" "Cluster-wide authorization and policy enforcement" "Dependency Operator"
        kueue = softwareSystem "Kueue" "Workload queue management for AI/ML job scheduling" "Dependency Operator"
        gatewayAPI = softwareSystem "Gateway API" "Kubernetes Gateway API CRDs and controller" "Dependency Operator"
        observability = softwareSystem "Cluster Observability" "Metrics collection and monitoring" "Dependency Operator"
        opentelemetry = softwareSystem "OpenTelemetry" "Distributed tracing instrumentation" "Dependency Operator"
        tempo = softwareSystem "Tempo" "Trace data backend for OpenTelemetry" "Dependency Operator"
        lws = softwareSystem "Leader-Worker-Set" "Pod group management for distributed ML training" "Dependency Operator"
        jobSet = softwareSystem "JobSet Operator" "Batch job orchestration for training and data processing" "Dependency Operator"
        cma = softwareSystem "Custom Metrics Autoscaler" "Custom metric-driven horizontal pod autoscaling" "Dependency Operator"

        azureAKS = softwareSystem "Azure AKS" "Azure Kubernetes Service" "Cloud Provider"
        coreWeave = softwareSystem "CoreWeave" "CoreWeave GPU Cloud" "Cloud Provider"
        awsEKS = softwareSystem "AWS EKS" "Amazon Elastic Kubernetes Service" "Cloud Provider"
        openshift = softwareSystem "OpenShift" "Red Hat OpenShift Container Platform with OLM" "Cloud Provider"

        clusterAdmin -> odhGitops "Deploys RHOAI via helm install / kustomize apply"
        dataScientist -> kserve "Creates InferenceService resources"

        odhGitops -> rhaiOperator "Deploys RHAI Operator"
        odhGitops -> certManager "Deploys/subscribes cert-manager"
        odhGitops -> istio "Deploys Istio via sail-operator sub-chart (XKS)"
        odhGitops -> authorino "Configures Authorino with TLS-enabled listener"
        odhGitops -> kueue "Subscribes kueue-operator"
        odhGitops -> gatewayAPI "Deploys Gateway API CRDs (XKS)"
        odhGitops -> observability "Subscribes cluster-observability-operator"
        odhGitops -> opentelemetry "Subscribes opentelemetry-product"
        odhGitops -> tempo "Subscribes tempo-product"
        odhGitops -> lws "Deploys/subscribes leader-worker-set"
        odhGitops -> jobSet "Deploys/subscribes job-set-operator"
        odhGitops -> cma "Subscribes custom-metrics-autoscaler"

        rhaiOperator -> kserve "Creates KServe CR via post-install hook"
        rhaiOperator -> aiGateway "Creates AIGateway CR via post-install hook (optional)"

        xksChart -> azureAKS "Deploys to"
        xksChart -> coreWeave "Deploys to"
        xksChart -> awsEKS "Deploys to"
        ocpChart -> openshift "Deploys to"
    }

    views {
        systemContext odhGitops "SystemContext" {
            include *
            autoLayout
        }

        container odhGitops "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Dependency Operator" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Cloud Provider" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
