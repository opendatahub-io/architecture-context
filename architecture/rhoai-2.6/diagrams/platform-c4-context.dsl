workspace {
    model {
        // Users
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using notebooks, pipelines, and serving platforms"
        mlEngineer = person "ML Engineer" "Manages distributed workloads, model serving infrastructure, and pipeline orchestration"
        platformAdmin = person "Platform Administrator" "Configures and monitors RHOAI platform, manages components via DataScienceCluster"

        // RHOAI Platform System
        rhoai = softwareSystem "Red Hat OpenShift AI 2.6" "Enterprise ML platform providing notebooks, pipelines, distributed computing, and model serving" {
            // Control Plane
            rhods = container "RHODS Operator" "Platform orchestrator managing all RHOAI components via DataScienceCluster CRD" "Go Operator" {
                tags "Control Plane"
            }

            // User Interface
            dashboard = container "ODH Dashboard" "Web UI for managing workbenches, pipelines, models, and data connections" "React/TypeScript" {
                tags "User Interface"
            }

            // Development Environment
            notebooks = container "Notebook Controller" "Manages Jupyter, VS Code, and RStudio workbench environments with OAuth integration" "Go Controller" {
                tags "Development"
            }

            // ML Pipelines
            dspOperator = container "Data Science Pipelines Operator" "Deploys and manages Kubeflow Pipelines with Tekton backend" "Go Operator" {
                tags "Pipelines"
            }
            dspAPI = container "DSP API Server" "Pipeline management API and UI with MLMD lineage tracking" "Python/Go" {
                tags "Pipelines"
            }

            // Model Serving - Single Model
            kserve = container "KServe" "Serverless model serving with Knative autoscaling and Istio routing" "Go Operator" {
                tags "Model Serving"
            }

            // Model Serving - Multi-Model
            modelmesh = container "ModelMesh Serving" "High-density multi-model serving with intelligent caching" "Java/Go Operator" {
                tags "Model Serving"
            }

            // Integration Layer
            modelController = container "ODH Model Controller" "Bridges model serving with OpenShift Routes, Service Mesh, and monitoring" "Go Controller" {
                tags "Integration"
            }

            // Distributed Computing
            codeflare = container "CodeFlare Operator" "Manages distributed workloads with MCAD scheduling and InstaScale auto-scaling" "Go Operator" {
                tags "Distributed Computing"
            }
            kuberay = container "KubeRay Operator" "Deploys and manages Ray clusters for distributed ML workloads" "Go Operator" {
                tags "Distributed Computing"
            }

            // Model Monitoring
            trustyai = container "TrustyAI Service Operator" "Provides model fairness monitoring and explainability services" "Java Operator" {
                tags "Monitoring"
            }

            // Platform Monitoring
            prometheus = container "Prometheus" "Platform-wide metrics collection and alerting" "Prometheus" {
                tags "Monitoring"
            }
        }

        // External Dependencies - OpenShift Platform
        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes platform with Routes, OAuth, Service CA, and security features" {
            tags "External OpenShift"
        }

        // External Dependencies - Service Mesh
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Istio-based service mesh providing mTLS, traffic routing, and authorization" {
            tags "External OpenShift"
        }

        // External Dependencies - Pipelines
        openshiftPipelines = softwareSystem "OpenShift Pipelines" "Tekton-based CI/CD platform for pipeline execution" {
            tags "External OpenShift"
        }

        // External Dependencies - Knative
        knativeServing = softwareSystem "Knative Serving" "Serverless autoscaling platform for KServe model serving" {
            tags "External Dependency"
        }

        // External Storage
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts, pipeline data, and notebook data (AWS S3, MinIO, GCS, Azure Blob)" {
            tags "External Storage"
        }

        // External Registries
        containerRegistry = softwareSystem "Container Registries" "Container image repositories (quay.io, registry.redhat.io)" {
            tags "External Storage"
        }

        // Optional External Services
        externalDB = softwareSystem "External Databases" "Optional external PostgreSQL/MySQL for pipeline metadata" {
            tags "External Optional"
        }
        externalEtcd = softwareSystem "External etcd" "Optional external etcd cluster for ModelMesh state" {
            tags "External Optional"
        }
        cloudProvider = softwareSystem "Cloud Provider API" "Cloud infrastructure API for InstaScale auto-scaling (AWS, Azure, GCP)" {
            tags "External Optional"
        }

        // Relationships - Users to RHOAI
        dataScientist -> dashboard "Accesses via web browser (HTTPS/443, OAuth)"
        dataScientist -> notebooks "Develops models in Jupyter/VS Code (HTTPS/443, OAuth)"
        dataScientist -> dspAPI "Submits pipelines via Elyra or SDK (HTTPS/443)"
        dataScientist -> kserve "Deploys models for serving (kubectl or Dashboard)"
        mlEngineer -> dashboard "Manages infrastructure and monitors deployments"
        mlEngineer -> codeflare "Submits distributed Ray workloads (AppWrapper CRs)"
        mlEngineer -> prometheus "Monitors platform and model metrics (HTTPS/443, OAuth)"
        platformAdmin -> rhods "Configures platform via DataScienceCluster CR"
        platformAdmin -> dashboard "Monitors component health and user activity"
        platformAdmin -> prometheus "Views platform metrics and alerts"

        // Relationships - Control Plane
        rhods -> dashboard "Deploys and manages"
        rhods -> notebooks "Deploys and manages"
        rhods -> dspOperator "Deploys and manages"
        rhods -> kserve "Deploys and manages"
        rhods -> modelmesh "Deploys and manages"
        rhods -> modelController "Deploys and manages"
        rhods -> codeflare "Deploys and manages"
        rhods -> kuberay "Deploys and manages"
        rhods -> trustyai "Deploys and manages"
        rhods -> prometheus "Deploys and manages"
        rhods -> openshift "Reconciles via Kubernetes API (HTTPS/6443, ServiceAccount JWT)"

        // Relationships - Dashboard
        dashboard -> dspAPI "Calls pipeline API (HTTP/8888)"
        dashboard -> dspAPI "Queries ML metadata (gRPC/9090)"
        dashboard -> openshift "Authenticates users (OAuth)"

        // Relationships - Notebooks
        notebooks -> openshift "Integrates with Routes and OAuth"
        notebooks -> s3Storage "Accesses data and saves models (HTTPS/443, AWS IAM)"
        notebooks -> dspAPI "Submits pipelines via Elyra (HTTP)"
        notebooks -> containerRegistry "Pulls notebook images (HTTPS/443)"

        // Relationships - Data Science Pipelines
        dspOperator -> dspAPI "Deploys API server and MLMD stack"
        dspAPI -> openshiftPipelines "Creates Tekton PipelineRuns"
        dspAPI -> s3Storage "Stores pipeline artifacts (HTTPS/443, AWS IAM)"
        dspAPI -> externalDB "Stores pipeline metadata (MySQL/3306 or PostgreSQL/5432, TLS optional)"

        // Relationships - KServe
        kserve -> knativeServing "Uses for serverless autoscaling (scale to zero)"
        kserve -> serviceMesh "Uses for traffic routing and mTLS (VirtualServices)"
        kserve -> modelController "Integrates for OpenShift features"
        kserve -> s3Storage "Downloads model artifacts (HTTPS/443, AWS IAM)"

        // Relationships - ModelMesh
        modelmesh -> externalEtcd "Stores model registry state (HTTPS/2379)"
        modelmesh -> modelController "Integrates for OpenShift features"
        modelmesh -> s3Storage "Downloads model artifacts (HTTPS/443, AWS IAM)"

        // Relationships - Model Controller
        modelController -> openshift "Creates Routes for InferenceServices"
        modelController -> serviceMesh "Configures mTLS and authorization policies"
        modelController -> prometheus "Creates ServiceMonitors for model metrics"

        // Relationships - Distributed Computing
        codeflare -> kuberay "Creates RayCluster CRs in AppWrappers"
        codeflare -> cloudProvider "Scales nodes via Machine API (HTTPS/443, InstaScale)"
        kuberay -> s3Storage "Accesses data for Ray workloads (HTTPS/443)"

        // Relationships - TrustyAI
        trustyai -> kserve "Watches and patches InferenceServices for payload logging"
        trustyai -> prometheus "Exports fairness metrics (HTTP/8080)"
        trustyai -> openshift "Secures access with OAuth proxy"

        // Relationships - Monitoring
        prometheus -> dashboard "Scrapes metrics from all components"
        prometheus -> dspAPI "Scrapes pipeline metrics"
        prometheus -> kserve "Scrapes InferenceService metrics"
        prometheus -> modelmesh "Scrapes ModelMesh metrics"
        prometheus -> trustyai "Scrapes fairness metrics"
        prometheus -> openshift "Authenticates via OAuth for UI access"

        // Relationships - Platform Dependencies
        dashboard -> openshift "Uses Routes for external access"
        notebooks -> openshift "Uses Routes and OAuth proxy"
        dspAPI -> openshift "Uses Routes and OAuth proxy"
        kserve -> openshift "Uses Routes (via Model Controller)"
        modelmesh -> openshift "Uses Routes (via Model Controller)"
        prometheus -> openshift "Uses Routes and OAuth proxy"

        // External Registry Access
        rhods -> containerRegistry "Pulls operator images (HTTPS/443)"
        dspOperator -> containerRegistry "Pulls component images (HTTPS/443)"
        kserve -> containerRegistry "Pulls serving runtime images (HTTPS/443)"
        modelmesh -> containerRegistry "Pulls runtime images (HTTPS/443)"
        kuberay -> containerRegistry "Pulls Ray images (HTTPS/443)"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for Red Hat OpenShift AI 2.6 platform showing users, components, and external dependencies"
        }

        container rhoai "Containers" {
            include *
            autoLayout lr
            description "Container diagram showing RHOAI platform components and their relationships"
        }

        // Filtered views by audience
        filtered "DeveloperView" {
            include element.tag==Development
            include element.tag==Pipelines
            include element.tag=="Model Serving"
            include element.tag=="User Interface"
            include dataScientist
            include dashboard notebooks dspOperator dspAPI kserve modelmesh s3Storage openshift
            include -> element.tag==Development
            include -> element.tag==Pipelines
            include -> element.tag=="Model Serving"
            include -> element.tag=="User Interface"
            autoLayout
            description "Developer-focused view showing notebook development, pipelines, and model serving"
        }

        filtered "SecurityView" {
            include element.tag=="Control Plane"
            include element.tag==Integration
            include element.tag==Monitoring
            include element.tag=="External OpenShift"
            include platformAdmin
            include rhods modelController prometheus trustyai openshift serviceMesh
            include -> element.tag=="Control Plane"
            include -> element.tag==Integration
            include -> element.tag==Monitoring
            autoLayout
            description "Security-focused view showing control plane, integration, and monitoring components"
        }

        filtered "DistributedComputingView" {
            include element.tag=="Distributed Computing"
            include element.tag=="User Interface"
            include mlEngineer
            include dashboard codeflare kuberay s3Storage cloudProvider openshift
            include -> element.tag=="Distributed Computing"
            autoLayout
            description "Distributed computing view showing Ray cluster management and auto-scaling"
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "External OpenShift" {
                background #d63031
                color #ffffff
            }
            element "External Dependency" {
                background #999999
                color #ffffff
            }
            element "External Storage" {
                background #f39c12
                color #ffffff
            }
            element "External Optional" {
                background #95a5a6
                color #ffffff
            }
            element "Control Plane" {
                background #c0392b
                color #ffffff
            }
            element "User Interface" {
                background #2980b9
                color #ffffff
            }
            element "Development" {
                background #27ae60
                color #ffffff
            }
            element "Pipelines" {
                background #8e44ad
                color #ffffff
            }
            element "Model Serving" {
                background #e74c3c
                color #ffffff
            }
            element "Integration" {
                background #f39c12
                color #000000
            }
            element "Distributed Computing" {
                background #16a085
                color #ffffff
            }
            element "Monitoring" {
                background #9b59b6
                color #ffffff
            }
        }

        themes default
    }
}
