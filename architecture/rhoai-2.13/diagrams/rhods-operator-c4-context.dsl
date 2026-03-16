workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML workloads, notebooks, and models"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform deployment and configuration"
        gitOps = person "GitOps System" "Automates deployment via DataScienceCluster CRs"

        rhodsOperator = softwareSystem "RHODS Operator" "Primary operator for Red Hat OpenShift AI that deploys and manages data science platform components" {
            dscController = container "DataScienceCluster Controller" "Manages lifecycle of ODH/RHOAI components" "Go Operator" {
                reconciler = component "Reconciler" "Watches DataScienceCluster CRs and reconciles component state"
                manifestFetcher = component "Manifest Fetcher" "Fetches component manifests from Git repositories"
                kustomizer = component "Kustomize Engine" "Applies Kustomize transformations to manifests"
                deployer = component "Deployer" "Applies manifests to Kubernetes API"
            }

            dsciController = container "DSCInitialization Controller" "Initializes platform-level resources" "Go Operator" {
                namespaceManager = component "Namespace Manager" "Creates and configures application and monitoring namespaces"
                serviceMeshConfig = component "Service Mesh Configurator" "Configures Istio ServiceMeshMember resources"
                monitoringDeployer = component "Monitoring Deployer" "Deploys Prometheus and Alertmanager stack"
            }

            secretGenerator = container "SecretGenerator Controller" "Generates OAuth clients and secrets" "Go Operator"
            certGenerator = container "CertConfigmapGenerator Controller" "Manages trusted CA bundle ConfigMaps" "Go Operator"

            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics" "HTTP API" {
                tags "Monitoring"
            }
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane" "External"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Istio-based service mesh for mTLS and traffic management" "External"
        serverless = softwareSystem "OpenShift Serverless" "Knative Serving for serverless model serving" "External"
        authorino = softwareSystem "Authorino Operator" "Kubernetes-native authorization service" "External"
        pipelines = softwareSystem "OpenShift Pipelines" "Tekton-based CI/CD pipelines" "External"
        prometheus = softwareSystem "Prometheus Operator" "Monitoring and alerting platform" "External"

        dashboard = softwareSystem "ODH Dashboard" "Web UI for data science platform" "Internal ODH"
        notebooks = softwareSystem "ODH Notebook Controller" "Jupyter notebook lifecycle management" "Internal ODH"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Traditional model serving runtime" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines Operator" "ML pipeline orchestration" "Internal ODH"
        codeflare = softwareSystem "CodeFlare Operator" "Distributed computing for AI workloads" "Internal ODH"
        kuberay = softwareSystem "KubeRay Operator" "Ray cluster management" "Internal ODH"
        training = softwareSystem "Training Operator" "Distributed ML training jobs" "Internal ODH"
        kueue = softwareSystem "Kueue" "Job queueing and resource management" "Internal ODH"
        trustyai = softwareSystem "TrustyAI Operator" "Model explainability and fairness" "Internal ODH"

        github = softwareSystem "GitHub" "Git repository hosting for component manifests" "External Service"
        quay = softwareSystem "Quay.io" "Container image registry (public)" "External Service"
        rhio = softwareSystem "Red Hat Registry" "Red Hat container image registry" "External Service"

        # Relationships - Users
        dataScientist -> dashboard "Uses web UI to manage workloads"
        dataScientist -> notebooks "Creates and runs Jupyter notebooks"
        dataScientist -> kserve "Deploys models for serving"
        platformAdmin -> rhodsOperator "Configures via DataScienceCluster and DSCInitialization CRs"
        gitOps -> rhodsOperator "Automates deployment via CRs" "HTTPS/6443"

        # Relationships - Operator Core
        dscController -> k8sAPI "Watches CRs and applies manifests" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        dsciController -> k8sAPI "Creates namespaces and platform resources" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        secretGenerator -> k8sAPI "Manages OAuth clients and secrets" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        certGenerator -> k8sAPI "Distributes trusted CA bundles" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"

        # Relationships - External Dependencies (Required)
        rhodsOperator -> k8sAPI "Primary control plane interface" "HTTPS/6443"

        # Relationships - External Dependencies (Conditional)
        rhodsOperator -> serviceMesh "Configures for KServe and SSO" "HTTPS/6443, conditional"
        rhodsOperator -> serverless "Required for KServe autoscaling" "HTTPS/6443, conditional"
        rhodsOperator -> authorino "Required for KServe authorization" "HTTPS/6443, conditional"
        rhodsOperator -> pipelines "Required for DataSciencePipelines" "HTTPS/6443, conditional"
        rhodsOperator -> prometheus "Deploys monitoring stack" "HTTPS/6443, optional"

        # Relationships - Component Deployment
        rhodsOperator -> dashboard "Deploys and manages" "Manifest deployment"
        rhodsOperator -> notebooks "Deploys and manages" "Manifest deployment"
        rhodsOperator -> kserve "Deploys and manages" "Manifest deployment"
        rhodsOperator -> modelmesh "Deploys and manages" "Manifest deployment"
        rhodsOperator -> dsp "Deploys and manages" "Manifest deployment"
        rhodsOperator -> codeflare "Deploys and manages" "Manifest deployment"
        rhodsOperator -> kuberay "Deploys and manages" "Manifest deployment"
        rhodsOperator -> training "Deploys and manages" "Manifest deployment"
        rhodsOperator -> kueue "Deploys and manages" "Manifest deployment"
        rhodsOperator -> trustyai "Deploys and manages" "Manifest deployment"

        # Relationships - External Services
        manifestFetcher -> github "Fetches component manifests" "HTTPS/443, TLS 1.2+"
        dscController -> quay "Pulls container images" "HTTPS/443, TLS 1.2+"
        dscController -> rhio "Pulls Red Hat container images" "HTTPS/443, TLS 1.2+, Pull secret"

        # Relationships - Monitoring
        prometheus -> metricsEndpoint "Scrapes metrics" "HTTP/8443, ServiceAccount Token"

        # Relationships - Component Integration
        kserve -> serviceMesh "Uses for traffic routing and mTLS"
        kserve -> serverless "Uses for autoscaling"
        kserve -> authorino "Uses for authorization"
        dsp -> pipelines "Uses for pipeline execution"
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

        component dscController "DSCController_Components" {
            include *
            autoLayout
        }

        component dsciController "DSCIController_Components" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Monitoring" {
                background #9b59b6
                color #ffffff
            }
        }

        theme default
    }
}
