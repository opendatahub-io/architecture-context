workspace {
    model {
        admin = person "Platform Administrator" "Manages OpenShift AI platform deployment and configuration"
        datascientist = person "Data Scientist" "Uses deployed components for ML/AI workflows"

        rhodsOperator = softwareSystem "RHODS Operator" "Primary platform operator for Red Hat OpenShift AI that orchestrates deployment and lifecycle management of data science components" {
            dscController = container "DataScienceCluster Controller" "Manages component deployment and lifecycle" "Go Kubernetes Controller"
            dsciController = container "DSCInitialization Controller" "Initializes platform infrastructure" "Go Kubernetes Controller"
            featureController = container "FeatureTracker Controller" "Tracks cross-namespace resources for garbage collection" "Go Kubernetes Controller"
            secretGen = container "SecretGenerator Controller" "Generates and manages platform secrets" "Go Kubernetes Controller"
            certGen = container "CertConfigMapGenerator Controller" "Generates TLS certificate ConfigMaps" "Go Kubernetes Controller"
            webhookServer = container "Webhook Server" "CRD conversion webhook for API version compatibility" "Go HTTPS Service"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint" "Go HTTP Service"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Container orchestration platform control plane" "External"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Service mesh for authentication, traffic management, and mTLS" "External Conditional"
        serverless = softwareSystem "OpenShift Serverless" "Knative-based serverless platform" "External Conditional"
        authorino = softwareSystem "Authorino Operator" "Authentication and authorization service" "External Conditional"
        pipelines = softwareSystem "OpenShift Pipelines" "Tekton-based CI/CD pipelines" "External Conditional"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring and alerting platform" "External Optional"
        certManager = softwareSystem "cert-manager" "Automated TLS certificate management" "External Optional"
        github = softwareSystem "GitHub" "Component manifest repository hosting" "External"
        quay = softwareSystem "Quay.io" "Container image registry" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for platform management" "Internal ODH"
        notebooks = softwareSystem "Notebook Controller" "Jupyter notebook lifecycle management" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines for ML workflows" "Internal ODH"
        kserve = softwareSystem "KServe" "Serverless model serving infrastructure" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving infrastructure" "Internal ODH"
        codeflare = softwareSystem "CodeFlare Operator" "Distributed workload orchestration" "Internal ODH"
        kuberay = softwareSystem "KubeRay Operator" "Ray cluster management" "Internal ODH"
        trustyai = softwareSystem "TrustyAI Operator" "AI fairness and explainability" "Internal ODH"
        training = softwareSystem "Training Operator" "Distributed training orchestration" "Internal ODH"
        kueue = softwareSystem "Kueue" "Multi-tenant job queueing" "Internal ODH"

        # User interactions
        admin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization CRs via kubectl/GitOps" "HTTPS/6443 via Kubernetes API"
        datascientist -> dashboard "Accesses platform features and creates resources" "HTTPS/443"

        # RHODS Operator interactions
        rhodsOperator -> k8sAPI "Manages cluster resources across namespaces" "HTTPS/6443, ServiceAccount Token, TLS 1.2+"
        dscController -> github "Fetches component Kustomize manifests" "HTTPS/443, TLS 1.2+"
        dscController -> dashboard "Deploys and manages" "via Kubernetes API"
        dscController -> notebooks "Deploys and manages" "via Kubernetes API"
        dscController -> dsp "Deploys and manages" "via Kubernetes API"
        dscController -> kserve "Deploys and manages" "via Kubernetes API"
        dscController -> modelmesh "Deploys and manages" "via Kubernetes API"
        dscController -> codeflare "Deploys and manages" "via Kubernetes API"
        dscController -> kuberay "Deploys and manages" "via Kubernetes API"
        dscController -> trustyai "Deploys and manages" "via Kubernetes API"
        dscController -> training "Deploys and manages" "via Kubernetes API"
        dscController -> kueue "Deploys and manages" "via Kubernetes API"

        dsciController -> serviceMesh "Configures ServiceMeshControlPlane and ServiceMeshMemberRoll" "via Kubernetes API"
        dsciController -> prometheus "Deploys ServiceMonitors, Prometheus, Alertmanager" "via Kubernetes API"
        dsciController -> authorino "Deploys AuthConfig resources" "via Kubernetes API"

        # External dependencies
        rhodsOperator -> quay "Pulls container images for components" "HTTPS/443, TLS 1.2+"
        k8sAPI -> webhookServer "CRD conversion webhook calls" "HTTPS/9443, mTLS, TLS 1.2+"
        prometheus -> metricsServer "Scrapes operator metrics" "HTTPS/8443, ServiceAccount Token"

        # Component dependencies
        kserve -> serviceMesh "Requires for authentication and traffic management" "via Kubernetes API"
        kserve -> serverless "Requires for serverless deployment mode" "via Kubernetes API"
        kserve -> authorino "Requires for authentication" "via Kubernetes API"
        dsp -> pipelines "Requires for pipeline execution" "via Kubernetes API"

        # Certificate management
        webhookServer -> certManager "Uses for TLS certificate automation" "via Kubernetes API"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Conditional" {
                background #cccccc
                color #000000
            }
            element "External Optional" {
                background #e6e6e6
                color #000000
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
        }
    }
}
