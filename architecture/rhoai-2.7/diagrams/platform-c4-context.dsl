workspace {
    name "Red Hat OpenShift AI 2.7 Platform"
    description "Enterprise AI/ML platform architecture on OpenShift"

    model {
        # People
        dataScientist = person "Data Scientist" "Creates, trains, and deploys ML models using notebooks and pipelines"
        mlEngineer = person "ML Engineer" "Deploys and manages model serving infrastructure"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform configuration and monitoring"

        # Main System
        rhoai = softwareSystem "Red Hat OpenShift AI 2.7" "Enterprise AI/ML platform for the entire machine learning lifecycle" {
            # Control Plane
            controlPlane = container "Platform Control Plane" "Orchestrates all AI/ML components" "RHOAI Operator v1.6.0-441" {
                rhoaiOperator = component "RHOAI Operator" "Manages DataScienceCluster and component lifecycle" "Go Operator"
                dashboard = component "ODH Dashboard" "Web UI for project and resource management" "React Application"
            }

            # Development
            notebookMgmt = container "Notebook Management" "Interactive development environments" "ODH Notebook Controller v1.27.0" {
                notebookController = component "Notebook Controller" "Spawns and manages notebook instances" "Go Operator"
                workbenches = component "Workbench Images" "JupyterLab, code-server, RStudio environments" "Container Images v1.1.1"
            }

            # ML Pipelines
            pipelineSystem = container "ML Pipeline Orchestration" "Workflow automation for ML" "Data Science Pipelines Operator" {
                dspOperator = component "DSP Operator" "Manages pipeline infrastructure" "Go Operator"
                apiServer = component "Pipeline API Server" "KFP API for pipeline execution" "Python/Flask"
                tekton = component "Tekton Integration" "Pipeline execution engine" "Tekton Pipelines"
            }

            # Model Serving
            modelServing = container "Model Serving Infrastructure" "Single and multi-model serving" "KServe + ModelMesh" {
                kserve = component "KServe Controller" "Serverless single-model serving" "Go Operator 80cb15e08"
                modelmesh = component "ModelMesh Controller" "High-density multi-model serving" "Go Operator v1.27.0"
                modelController = component "ODH Model Controller" "OpenShift integration (Routes, NetworkPolicies, mTLS)" "Go Operator v1.27.0 (HA: 3 replicas)"
            }

            # Distributed Computing
            distributedCompute = container "Distributed Computing" "Batch workloads and distributed training" "CodeFlare + KubeRay" {
                codeflare = component "CodeFlare Operator" "Workload scheduling and cluster autoscaling" "Go Operator"
                mcad = component "MCAD" "Multi-cluster app dispatcher" "Go Service"
                instascale = component "InstaScale" "Dynamic cluster node provisioning" "Go Service"
                kuberay = component "KubeRay Operator" "Ray cluster lifecycle management" "Go Operator"
            }

            # Governance (Optional)
            governance = container "AI Governance" "Explainability and fairness monitoring" "TrustyAI Operator (Optional in 2.7)" {
                trustyaiOp = component "TrustyAI Operator" "Manages explainability services" "Go Operator"
            }

            # Monitoring
            monitoring = container "Platform Monitoring" "Observability and alerting" "Prometheus Stack" {
                prometheus = component "Prometheus" "Metrics collection and storage" "Prometheus"
                alertmanager = component "Alertmanager" "Alert routing" "Alertmanager"
                grafana = component "Grafana" "Metrics visualization" "Grafana"
            }
        }

        # External Systems - OpenShift Platform
        openshift = softwareSystem "OpenShift Container Platform 4.11+" "Kubernetes platform with enterprise features" "External Platform" {
            oauth = container "OpenShift OAuth" "Centralized authentication" "OAuth 2.0 Server"
            router = container "OpenShift Router" "Ingress with multiple TLS termination modes" "HAProxy"
            machineAPI = container "Machine API" "Cluster autoscaling" "Machine API Operator"
        }

        # External Systems - Service Mesh
        serviceMesh = softwareSystem "OpenShift Service Mesh (Maistra) 2.x" "Service mesh for model serving" "External Platform" {
            istio = container "Istio Control Plane" "Service mesh control plane" "istiod"
            istioGateway = container "Istio Gateway" "Mesh ingress gateway" "istio-ingressgateway"
        }

        # External Systems - Serverless
        knative = softwareSystem "Knative Serving 1.12+" "Serverless autoscaling platform" "External Platform"

        # External Systems - CI/CD
        tektonPipelines = softwareSystem "OpenShift Pipelines (Tekton)" "Pipeline execution engine" "External Platform"

        # External Systems - Storage
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact and pipeline artifact storage" "External Service" {
            aws = container "AWS S3" "S3 object storage" "s3.amazonaws.com"
            gcs = container "Google Cloud Storage" "GCS object storage" "storage.googleapis.com"
            azure = container "Azure Blob Storage" "Azure blob storage" "blob.core.windows.net"
        }

        # External Systems - Package Repositories
        packageRepos = softwareSystem "Package Repositories" "Runtime dependency installation" "External Service" {
            pypi = container "PyPI" "Python package repository" "pypi.org"
            cran = container "CRAN" "R package repository" "cran.rstudio.com"
            github = container "GitHub" "Git repository hosting" "github.com"
        }

        # External Systems - Container Registries
        containerRegistry = softwareSystem "Container Registries" "Container image distribution" "External Service" {
            quay = container "Quay.io" "Red Hat container registry" "quay.io"
            rh_registry = container "Red Hat Registry" "Red Hat certified images" "registry.redhat.io"
        }

        # External Systems - Cloud Providers
        cloudProviders = softwareSystem "Cloud Provider APIs" "Infrastructure provisioning for autoscaling" "External Service"

        # Relationships - Users to Platform
        dataScientist -> dashboard "Accesses via web browser" "HTTPS/443, OAuth Bearer"
        dataScientist -> workbenches "Develops models in" "HTTPS/443, OAuth Bearer"
        dataScientist -> apiServer "Submits pipelines via" "HTTPS/443, OAuth Bearer"
        mlEngineer -> kserve "Deploys models via" "kubectl, HTTPS"
        mlEngineer -> modelmesh "Deploys models via" "kubectl, HTTPS"
        platformAdmin -> rhoaiOperator "Configures platform via" "kubectl (DataScienceCluster CR)"
        platformAdmin -> prometheus "Monitors platform via" "HTTPS/443"

        # Platform Internal Relationships
        rhoaiOperator -> notebookController "Orchestrates" "Kubernetes API"
        rhoaiOperator -> dspOperator "Orchestrates" "Kubernetes API"
        rhoaiOperator -> kserve "Orchestrates" "Kubernetes API"
        rhoaiOperator -> modelmesh "Orchestrates" "Kubernetes API"
        rhoaiOperator -> codeflare "Orchestrates" "Kubernetes API"
        rhoaiOperator -> kuberay "Orchestrates" "Kubernetes API"
        rhoaiOperator -> istio "Configures service mesh" "Kubernetes API"

        notebookController -> workbenches "Spawns notebook pods" "Kubernetes API"
        dspOperator -> apiServer "Deploys pipeline infrastructure" "Kubernetes API"
        dspOperator -> tekton "Integrates with" "Kubernetes API"

        kserve -> modelController "Watched by" "Kubernetes API (InferenceService CR)"
        modelmesh -> modelController "Watched by" "Kubernetes API (InferenceService CR)"
        modelController -> router "Creates Routes for external access" "Kubernetes API"
        modelController -> istio "Creates PeerAuthentications (mTLS STRICT)" "Kubernetes API"
        modelController -> modelController "Creates NetworkPolicies (3x per namespace)" "Kubernetes API"

        codeflare -> mcad "Manages" "Kubernetes API"
        codeflare -> instascale "Manages" "Kubernetes API"
        codeflare -> kuberay "Creates RayClusters for distributed workloads" "Kubernetes API"

        trustyaiOp -> kserve "Integrates with (inference logging)" "Kubernetes API"
        trustyaiOp -> modelmesh "Patches deployments (payload processors)" "Kubernetes API"

        # Monitoring
        prometheus -> rhoaiOperator "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> notebookController "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> dspOperator "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> kserve "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> modelmesh "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> modelController "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> codeflare "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> kuberay "Scrapes metrics from" "HTTP/8080 /metrics"
        prometheus -> trustyaiOp "Scrapes metrics from" "HTTP/8080 /metrics"

        # Platform to OpenShift
        rhoaiOperator -> oauth "Configures OAuth clients" "Kubernetes API"
        notebookController -> oauth "Integrates notebooks with" "OAuth Proxy"
        dspOperator -> oauth "Integrates pipeline UI with" "OAuth Proxy"
        trustyaiOp -> oauth "Integrates TrustyAI UI with" "OAuth Proxy"

        dashboard -> router "Exposed via Route" "HTTPS/443 (TLS Edge)"
        workbenches -> router "Exposed via Route" "HTTPS/443 (TLS Edge)"
        apiServer -> router "Exposed via Route" "HTTPS/443 (TLS Reencrypt)"
        modelController -> router "Creates Routes for InferenceServices" "HTTPS/443 (TLS Passthrough)"

        instascale -> machineAPI "Provisions cluster nodes via" "Kubernetes API"

        # Platform to Service Mesh
        kserve -> istio "Depends on for traffic management" "Kubernetes API"
        kserve -> istioGateway "Routes traffic via" "VirtualService"
        modelmesh -> istio "Optional integration" "Kubernetes API"
        modelController -> istio "Configures mTLS (STRICT mode)" "Kubernetes API"

        # Platform to Knative
        kserve -> knative "Depends on for serverless autoscaling" "Kubernetes API (Knative Service)"

        # Platform to Tekton
        dspOperator -> tektonPipelines "Uses for pipeline execution" "Kubernetes API (PipelineRun CR)"

        # Platform to Storage
        workbenches -> s3Storage "Stores/retrieves training data and models" "HTTPS/443, AWS IAM/GCP SA/Azure MI"
        kserve -> s3Storage "Downloads model artifacts (storage-initializer)" "HTTPS/443, AWS IAM (IRSA)"
        modelmesh -> s3Storage "Downloads model artifacts" "HTTPS/443, AWS IAM"
        apiServer -> s3Storage "Stores pipeline artifacts" "HTTPS/443, AWS IAM"

        # Platform to Package Repositories
        workbenches -> packageRepos "Installs runtime dependencies" "HTTPS/443"

        # Platform to Container Registries
        rhoaiOperator -> containerRegistry "Pulls container images" "HTTPS/443"
        notebookController -> containerRegistry "Pulls notebook images" "HTTPS/443"
        kserve -> containerRegistry "Pulls model server images" "HTTPS/443"

        # Platform to Cloud Providers
        instascale -> cloudProviders "Provisions nodes from" "HTTPS/443, Cloud APIs (AWS/GCP/Azure)"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
            title "Red Hat OpenShift AI 2.7 - System Context"
            description "Enterprise AI/ML platform showing users, external systems, and key dependencies"
        }

        container rhoai "PlatformContainers" {
            include *
            autoLayout lr
            title "Red Hat OpenShift AI 2.7 - Platform Containers"
            description "Major functional components of the RHOAI platform"
        }

        component controlPlane "ControlPlaneComponents" {
            include *
            autoLayout tb
            title "Platform Control Plane - Components"
        }

        component modelServing "ModelServingComponents" {
            include *
            autoLayout tb
            title "Model Serving Infrastructure - Components"
        }

        component distributedCompute "DistributedComputeComponents" {
            include *
            autoLayout tb
            title "Distributed Computing - Components"
        }

        dynamic rhoai "ModelDeploymentFlow" "Model training to deployment workflow" {
            dataScientist -> dashboard "1. Access dashboard"
            dataScientist -> workbenches "2. Train model in notebook"
            workbenches -> s3Storage "3. Upload trained model"
            dataScientist -> dashboard "4. Deploy model (create InferenceService)"
            dashboard -> kserve "5. Create InferenceService CR"
            kserve -> modelController "6. Watch InferenceService"
            modelController -> router "7. Create Route"
            modelController -> istio "8. Configure mTLS"
            kserve -> s3Storage "9. Download model (storage-initializer)"
            dataScientist -> router "10. Send inference request"
            autoLayout lr
            title "Workflow: Model Training to Deployment"
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape person
                background #f5a623
                color #ffffff
            }
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Service" {
                background #d6d6d6
                color #333333
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
