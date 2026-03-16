workspace {
    model {
        admin = person "Platform Administrator" "Manages Red Hat OpenShift AI platform and components"
        datascientist = person "Data Scientist" "Uses AI/ML components deployed by the operator"

        rhodsOperator = softwareSystem "RHODS Operator" "Central control plane for Red Hat OpenShift AI, managing deployment and lifecycle of data science and ML components" {
            controllerManager = container "Controller Manager" "Main operator process managing all controllers" "Go Operator" {
                dscInitController = component "DSCInitialization Controller" "Initializes platform-level resources (namespaces, service mesh, monitoring)" "Go Controller"
                dscController = component "DataScienceCluster Controller" "Manages component lifecycle (Dashboard, Workbenches, KServe, etc.)" "Go Controller"
                secretGenController = component "SecretGenerator Controller" "Generates and manages secrets for component authentication" "Go Controller"
                certGenController = component "CertConfigmapGenerator Controller" "Generates and distributes certificate ConfigMaps" "Go Controller"
            }
            webhookServer = container "Webhook Server" "Validates and mutates DataScienceCluster and DSCInitialization resources" "Go Admission Webhook"
            metricsExporter = container "Metrics Exporter" "Exposes operator metrics for Prometheus" "Go Service"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane API" "External Platform"
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management, mTLS, and authorization" "External Platform"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring and alerting platform" "External Platform"
        certManager = softwareSystem "cert-manager" "Certificate management for service mesh integration" "External Platform"
        oauth = softwareSystem "OpenShift OAuth" "User authentication and authorization" "External Platform"

        dashboard = softwareSystem "ODH Dashboard" "Web console for data science platform" "Internal ODH"
        workbenches = softwareSystem "Workbenches" "Jupyter notebook environments for data scientists" "Internal ODH"
        kserve = softwareSystem "KServe" "Standardized serverless model serving" "Internal ODH"
        modelmesh = softwareSystem "ModelMesh Serving" "Multi-model serving runtime" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines v2 for ML workflows" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "Distributed compute orchestration" "Internal ODH"
        ray = softwareSystem "KubeRay" "Ray cluster management for distributed computing" "Internal ODH"
        kueue = softwareSystem "Kueue" "Job scheduling and resource management" "Internal ODH"
        trustyai = softwareSystem "TrustyAI" "Model explainability and fairness" "Internal ODH"

        imageRegistry = softwareSystem "Image Registries" "Container image storage (registry.redhat.io, quay.io)" "External"
        gitRepos = softwareSystem "Component Git Repositories" "Source repositories for component manifests" "External"

        # Relationships
        admin -> rhodsOperator "Creates DataScienceCluster and DSCInitialization via kubectl"
        datascientist -> dashboard "Uses web console to manage workbenches and models"
        datascientist -> workbenches "Develops ML models in Jupyter notebooks"

        rhodsOperator -> k8sAPI "Reconciles resources, creates/updates components" "HTTPS/6443, TLS 1.2+, ServiceAccount Token"
        k8sAPI -> webhookServer "Validates and mutates CRs" "HTTPS/9443, TLS 1.2+, TLS Client Cert"

        dscInitController -> istio "Configures service mesh for KServe" "HTTPS/6443 via K8s API"
        dscInitController -> prometheusOperator "Deploys monitoring stack" "HTTPS/6443 via K8s API"
        dscController -> certManager "Requests certificates for components" "HTTPS/6443 via K8s API"
        dscController -> oauth "Integrates dashboard authentication" "HTTPS/6443 via K8s API"

        dscController -> dashboard "Deploys and manages" "K8s API"
        dscController -> workbenches "Deploys and manages" "K8s API"
        dscController -> kserve "Deploys and manages" "K8s API"
        dscController -> modelmesh "Deploys and manages" "K8s API"
        dscController -> pipelines "Deploys and manages" "K8s API"
        dscController -> codeflare "Deploys and manages" "K8s API"
        dscController -> ray "Deploys and manages" "K8s API"
        dscController -> kueue "Deploys and manages" "K8s API"
        dscController -> trustyai "Deploys and manages" "K8s API"

        rhodsOperator -> imageRegistry "Pulls component container images" "HTTPS/443, TLS 1.2+, Pull Secrets"
        rhodsOperator -> gitRepos "Fetches manifests (when devFlags.manifestsUri set)" "HTTPS/443, TLS 1.2+"

        metricsExporter -> prometheusOperator "Exposes metrics" "HTTP/8080"

        kserve -> istio "Uses for traffic routing and mTLS" "Service Mesh Integration"
        dashboard -> oauth "Delegates user authentication" "OAuth Integration"
    }

    views {
        systemContext rhodsOperator "SystemContext" {
            include *
            autoLayout lr
        }

        container rhodsOperator "Containers" {
            include *
            autoLayout tb
        }

        component controllerManager "Components" {
            include *
            autoLayout tb
        }

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "External" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
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
        }
    }

    configuration {
        scope softwaresystem
    }
}
