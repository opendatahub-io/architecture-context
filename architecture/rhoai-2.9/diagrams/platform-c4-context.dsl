workspace {
    name "Red Hat OpenShift AI 2.9 Platform"
    description "Enterprise AI/ML platform for the entire machine learning lifecycle"

    model {
        dataScientist = person "Data Scientist" "Develops ML models, trains models, deploys to production" "User"
        mlEngineer = person "ML Engineer" "Manages ML infrastructure, pipelines, and model deployment" "User"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform, configures components" "Admin"

        rhoai = softwareSystem "Red Hat OpenShift AI 2.9" "Enterprise AI/ML platform for model development, training, and serving" {
            !docs docs
            !adrs adrs

            # Core Platform
            rhodsOperator = container "RHODS Operator" "Manages platform lifecycle and component deployment" "Go Operator v1.6.0-556" "Core"
            dashboard = container "ODH Dashboard" "Web UI for platform management" "Node.js/React v1.21.0-18" "WebUI"

            # Workbench Services
            notebookController = container "Notebook Controller" "Manages Jupyter/VS Code/RStudio workbenches" "Go Operator v1.27.0" "Operator"
            notebookPods = container "Notebook Workbenches" "Interactive development environments" "JupyterLab/VS Code/RStudio" "Workload"

            # Model Serving
            kserveOperator = container "KServe Operator" "Serverless model serving with autoscaling" "Go Operator 69cb9fee0" "Operator"
            modelMeshOperator = container "ModelMesh Operator" "Multi-model serving runtime" "Go Operator v1.27.0-188" "Operator"
            odhModelController = container "ODH Model Controller" "OpenShift integration for model serving" "Go Operator v1.27.0-297" "Operator"
            inferenceServices = container "InferenceService Pods" "Model inference endpoints (KServe/ModelMesh)" "Python/C++ Runtimes" "Workload"

            # ML Pipelines
            dspOperator = container "Data Science Pipelines Operator" "ML workflow orchestration" "Go Operator cf823f3" "Operator"
            pipelinePods = container "Pipeline Workloads" "Argo/Tekton pipeline execution" "Python/Container Jobs" "Workload"

            # Distributed Computing
            kuberayOperator = container "KubeRay Operator" "Distributed Ray cluster management" "Go Operator v1.1.0" "Operator"
            codeflareOperator = container "CodeFlare Operator" "Security enhancements for Ray" "Go Operator v-2160" "Operator"
            kueueOperator = container "Kueue Operator" "Job queueing and resource management" "Go Operator v0.6.2" "Operator"
            rayClusters = container "Ray Clusters" "Distributed computing workloads" "Python Ray v2.x" "Workload"

            # Model Monitoring
            trustyaiOperator = container "TrustyAI Operator" "Model explainability and bias detection" "Go Operator f6fd5aa" "Operator"
            trustyaiServices = container "TrustyAI Services" "Fairness metrics and monitoring" "Java Service" "Workload"

            # Monitoring
            prometheus = container "Prometheus" "Metrics collection and monitoring" "Prometheus" "Monitoring"
            grafana = container "Grafana" "Metrics visualization" "Grafana" "Monitoring"
        }

        # OpenShift Platform
        openshift = softwareSystem "OpenShift Container Platform 4.12+" "Kubernetes platform with enterprise features" "Infrastructure"
        serviceMesh = softwareSystem "OpenShift Service Mesh" "Service mesh for mTLS and traffic management" "Infrastructure" {
            istio = container "Istio Control Plane" "Service mesh control plane" "Istio 2.x" "ServiceMesh"
            istioGateway = container "Istio Ingress Gateway" "Ingress gateway for serverless serving" "Envoy Proxy" "ServiceMesh"
        }
        oauthServer = softwareSystem "OpenShift OAuth" "Authentication provider" "Infrastructure"

        # External Storage
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for models, data, and artifacts" "External" {
            tags "External"
        }
        externalDB = softwareSystem "External Database" "MariaDB/PostgreSQL for pipeline metadata" "External" {
            tags "External"
        }

        # External Services
        containerRegistry = softwareSystem "Container Registry" "Quay.io, registry.redhat.io for images" "External" {
            tags "External"
        }
        packageRepos = softwareSystem "Package Repositories" "PyPI, Conda, GitHub for dependencies" "External" {
            tags "External"
        }

        # Relationships - Users to Platform
        dataScientist -> dashboard "Uses web UI to manage workbenches and models" "HTTPS/443"
        mlEngineer -> dashboard "Manages pipelines and deployments" "HTTPS/443"
        platformAdmin -> rhodsOperator "Configures platform via DSC/DSCI CRs" "kubectl"

        dataScientist -> notebookPods "Develops models in JupyterLab" "HTTPS/443"
        dataScientist -> inferenceServices "Sends inference requests" "HTTPS/443 REST/gRPC"
        mlEngineer -> pipelinePods "Creates and runs ML pipelines" "HTTPS/443"
        dataScientist -> rayClusters "Submits distributed training jobs" "HTTPS/443"

        # Dashboard relationships
        dashboard -> notebookController "Creates Notebook CRs" "K8s API/6443"
        dashboard -> kserveOperator "Creates InferenceService CRs" "K8s API/6443"
        dashboard -> dspOperator "Creates DSPA CRs" "K8s API/6443"
        dashboard -> prometheus "Queries metrics" "HTTPS/9092"

        # Operator relationships
        rhodsOperator -> notebookController "Deploys and manages" "K8s API/6443"
        rhodsOperator -> kserveOperator "Deploys and manages" "K8s API/6443"
        rhodsOperator -> modelMeshOperator "Deploys and manages" "K8s API/6443"
        rhodsOperator -> odhModelController "Deploys and manages" "K8s API/6443"
        rhodsOperator -> dspOperator "Deploys and manages" "K8s API/6443"
        rhodsOperator -> kuberayOperator "Deploys and manages" "K8s API/6443"
        rhodsOperator -> codeflareOperator "Deploys and manages" "K8s API/6443"
        rhodsOperator -> kueueOperator "Deploys and manages" "K8s API/6443"
        rhodsOperator -> trustyaiOperator "Deploys and manages" "K8s API/6443"

        # Workload creation
        notebookController -> notebookPods "Creates StatefulSets" "K8s API/6443"
        kserveOperator -> inferenceServices "Creates Knative Services" "K8s API/6443"
        modelMeshOperator -> inferenceServices "Creates Deployments" "K8s API/6443"
        odhModelController -> inferenceServices "Creates Routes, VirtualServices" "K8s API/6443"
        dspOperator -> pipelinePods "Creates Argo/Tekton resources" "K8s API/6443"
        kuberayOperator -> rayClusters "Creates Ray head/worker pods" "K8s API/6443"
        codeflareOperator -> rayClusters "Injects OAuth, mTLS, NetworkPolicies" "K8s API/6443"
        kueueOperator -> rayClusters "Manages resource allocation" "K8s API/6443"
        trustyaiOperator -> trustyaiServices "Creates TrustyAI service pods" "K8s API/6443"

        # Infrastructure dependencies
        rhoai -> openshift "Runs on Kubernetes platform" "K8s API/6443"
        rhoai -> serviceMesh "Uses for mTLS and traffic routing" "Istio API"
        inferenceServices -> istioGateway "Routes traffic through" "HTTP/8080 mTLS"
        rhoai -> oauthServer "Authenticates users" "HTTPS/443 OAuth2"

        # External dependencies
        inferenceServices -> s3Storage "Downloads model artifacts" "HTTPS/443 S3 API"
        notebookPods -> s3Storage "Stores datasets and models" "HTTPS/443 S3 API"
        pipelinePods -> s3Storage "Stores pipeline data" "HTTPS/443 S3 API"
        rayClusters -> s3Storage "Stores training checkpoints" "HTTPS/443 S3 API"

        pipelinePods -> externalDB "Stores pipeline metadata" "TCP/3306 or 5432"

        rhoai -> containerRegistry "Pulls container images" "HTTPS/443"
        notebookPods -> packageRepos "Installs Python packages" "HTTPS/443"

        # Monitoring
        prometheus -> rhodsOperator "Scrapes metrics" "HTTP/8080"
        prometheus -> kserveOperator "Scrapes metrics" "HTTP/8080"
        prometheus -> modelMeshOperator "Scrapes metrics" "HTTP/8080"
        prometheus -> inferenceServices "Scrapes metrics" "HTTP/8080"
        prometheus -> trustyaiServices "Scrapes metrics" "HTTP/9090"
        grafana -> prometheus "Queries metrics" "HTTP/9090"

        # Model monitoring
        inferenceServices -> trustyaiServices "Sends inference payloads" "HTTP/8080"
        trustyaiServices -> prometheus "Exposes fairness metrics" "ServiceMonitor"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for Red Hat OpenShift AI 2.9 platform"
        }

        container rhoai "PlatformContainers" {
            include *
            autoLayout tb
            description "Container diagram showing RHOAI platform components"
        }

        container rhoai "CorePlatform" {
            include dataScientist mlEngineer platformAdmin
            include rhodsOperator dashboard notebookController kserveOperator modelMeshOperator odhModelController
            include openshift oauthServer serviceMesh
            autoLayout lr
            description "Core platform operators and management"
        }

        container rhoai "ModelServing" {
            include dataScientist
            include dashboard kserveOperator modelMeshOperator odhModelController inferenceServices
            include serviceMesh s3Storage oauthServer
            autoLayout tb
            description "Model serving architecture (KServe and ModelMesh)"
        }

        container rhoai "MLPipelines" {
            include mlEngineer
            include dashboard dspOperator pipelinePods
            include s3Storage externalDB
            autoLayout tb
            description "ML pipeline orchestration architecture"
        }

        container rhoai "DistributedComputing" {
            include dataScientist
            include kuberayOperator codeflareOperator kueueOperator rayClusters
            include s3Storage oauthServer
            autoLayout tb
            description "Distributed computing with Ray and Kueue"
        }

        container rhoai "Monitoring" {
            include trustyaiOperator trustyaiServices inferenceServices prometheus grafana
            autoLayout lr
            description "Model monitoring and observability"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Core" {
                background #e74c3c
                color #ffffff
            }
            element "Operator" {
                background #3498db
                color #ffffff
            }
            element "Workload" {
                background #2ecc71
                color #ffffff
            }
            element "WebUI" {
                background #9b59b6
                color #ffffff
            }
            element "Monitoring" {
                background #16a085
                color #ffffff
            }
            element "ServiceMesh" {
                background #e67e22
                color #ffffff
            }
            element "Infrastructure" {
                background #95a5a6
                color #ffffff
            }
            element "External" {
                background #f39c12
                color #000000
            }
            element "Admin" {
                background #c0392b
                color #ffffff
            }
        }

        themes default
    }
}
