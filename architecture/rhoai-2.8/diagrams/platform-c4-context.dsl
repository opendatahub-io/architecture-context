workspace {
    model {
        dataScientist = person "Data Scientist" "Develops and trains ML models using notebooks and pipelines"
        mlEngineer = person "ML Engineer" "Deploys and monitors models in production"
        platformAdmin = person "Platform Administrator" "Manages RHOAI installation and configuration"

        rhoai = softwareSystem "Red Hat OpenShift AI 2.8" "Comprehensive ML/AI platform for model development, training, and deployment" {
            !docs "Red Hat OpenShift AI platform providing integrated tools for the complete ML lifecycle"

            operatorControlPlane = container "Operator Control Plane" "Manages platform components and lifecycle" "Kubernetes Operators" {
                rhodsOperator = component "RHODS Operator" "Primary operator deploying all platform components" "Go Operator v1.6.0"
                kserveOperator = component "KServe Operator" "Manages serverless model serving" "Go Operator c7788a198"
                modelmeshOperator = component "ModelMesh Operator" "Manages multi-model serving" "Go Operator v1.27.0-rhods-217"
                dspOperator = component "Data Science Pipelines Operator" "Manages pipeline deployments" "Go Operator 266aee4"
                codeflareOperator = component "CodeFlare Operator" "Manages distributed ML workloads" "Go Operator c7e38f8"
                kuberayOperator = component "KubeRay Operator" "Manages Ray clusters" "Go Operator e603d04d"
                kueueOperator = component "Kueue Operator" "Job queueing and resource allocation" "Go Operator f99252525"
                trustyaiOperator = component "TrustyAI Operator" "AI explainability and fairness" "Go Operator 288fadf"
            }

            platformServices = container "Platform Services" "Central services for user interactions" "Web + Controllers" {
                dashboard = component "ODH Dashboard" "Central web console for managing workloads" "React SPA + Go Backend v1.21.0"
                notebookController = component "Notebook Controller" "Extends Kubeflow notebooks with OpenShift integration" "Go Controller v1.27.0-rhods-319"
                modelController = component "Model Controller" "Extends model serving with Routes and Service Mesh" "Go Controller v1.27.0-rhods-216"
            }

            userWorkloads = container "User Workloads" "User-deployed ML workloads" "Notebooks, Models, Pipelines, Jobs" {
                notebooks = component "Notebook Workbenches" "Interactive development environments" "Jupyter, VS Code, RStudio v1.1.1-434"
                inferenceServices = component "KServe InferenceServices" "Serverless model serving" "Knative-based predictors"
                modelmeshRuntime = component "ModelMesh Runtime" "Multi-model serving runtime" "Deployment-based serving"
                pipelines = component "Data Science Pipelines" "ML workflow orchestration" "KFP + Tekton backend"
                rayClusters = component "Ray Clusters" "Distributed compute framework" "Ray head + workers"
                trustyaiServices = component "TrustyAI Services" "AI explainability analysis" "Quarkus service"
            }

            monitoring = container "Platform Monitoring" "Observability and metrics" "Prometheus Stack" {
                prometheus = component "Prometheus" "Metrics collection and storage" "Prometheus StatefulSet"
                alertmanager = component "Alertmanager" "Alert routing and notification" "Alertmanager Deployment"
            }
        }

        openshift = softwareSystem "OpenShift Container Platform" "Enterprise Kubernetes platform" "External - Red Hat" {
            !docs "OpenShift 4.12+ providing container orchestration, networking, and security"
        }

        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic management and security" "External - OpenShift Service Mesh" {
            !docs "Provides mTLS, traffic routing, and telemetry for model serving"
        }

        knative = softwareSystem "Knative Serving" "Serverless platform for autoscaling workloads" "External - OpenShift Serverless" {
            !docs "Enables scale-to-zero and request-based autoscaling for KServe"
        }

        tekton = softwareSystem "OpenShift Pipelines" "CI/CD pipeline execution engine" "External - OpenShift Pipelines" {
            !docs "Tekton-based pipeline execution for Data Science Pipelines"
        }

        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for models and data" "External - AWS S3 / Minio / Ceph" {
            !docs "Stores model artifacts, training data, and pipeline artifacts"
        }

        oauth = softwareSystem "OpenShift OAuth" "Authentication and authorization service" "External - OpenShift" {
            !docs "Provides user authentication via OAuth 2.0"
        }

        containerRegistry = softwareSystem "Container Registries" "Container image storage" "External - quay.io / registry.redhat.io" {
            !docs "Provides workbench images, runtime images, and operator images"
        }

        gitRepositories = softwareSystem "Git Repositories" "Source code version control" "External - GitHub / GitLab" {
            !docs "Stores notebooks, pipeline definitions, and model code"
        }

        pypi = softwareSystem "PyPI" "Python package repository" "External - pypi.org" {
            !docs "Provides Python libraries for data science and ML"
        }

        databases = softwareSystem "External Databases" "Data sources for ML workloads" "External - PostgreSQL / MySQL / MongoDB" {
            !docs "Provides training and inference data"
        }

        machineAPI = softwareSystem "OpenShift Machine API" "Cluster node management" "External - OpenShift" {
            !docs "Enables node autoscaling for distributed workloads"
        }

        # User to RHOAI relationships
        dataScientist -> dashboard "Manages notebooks, pipelines, and models via web UI" "HTTPS/443"
        dataScientist -> notebooks "Develops models in interactive environments" "HTTPS/443"
        dataScientist -> pipelines "Authors and runs ML pipelines" "HTTPS/443"
        dataScientist -> inferenceServices "Tests model deployments" "HTTPS/443"

        mlEngineer -> dashboard "Deploys and monitors production models" "HTTPS/443"
        mlEngineer -> inferenceServices "Manages inference endpoints" "HTTPS/443"
        mlEngineer -> modelmeshRuntime "Deploys multi-model serving" "HTTPS/443"
        mlEngineer -> trustyaiServices "Monitors model fairness and explainability" "HTTPS/443"

        platformAdmin -> rhodsOperator "Configures platform via DataScienceCluster CR" "Kubernetes API"
        platformAdmin -> dashboard "Monitors platform health" "HTTPS/443"
        platformAdmin -> prometheus "Views platform metrics" "HTTPS/443"

        # RHOAI internal relationships
        rhodsOperator -> dashboard "Deploys and manages" "Kubernetes API"
        rhodsOperator -> notebookController "Deploys and manages" "Kubernetes API"
        rhodsOperator -> modelController "Deploys and manages" "Kubernetes API"

        dashboard -> notebookController "Creates Notebook CRs" "Kubernetes API"
        dashboard -> kserveOperator "Creates InferenceService CRs" "Kubernetes API"
        dashboard -> modelmeshOperator "Creates Predictor CRs" "Kubernetes API"
        dashboard -> dspOperator "Creates DataSciencePipelinesApplication CRs" "Kubernetes API"

        notebookController -> notebooks "Provisions workbenches with Routes" "Kubernetes API"
        kserveOperator -> inferenceServices "Creates predictor pods" "Kubernetes API"
        modelController -> inferenceServices "Adds Routes and Service Mesh config" "Kubernetes API"
        modelmeshOperator -> modelmeshRuntime "Creates runtime deployments" "Kubernetes API"
        dspOperator -> pipelines "Deploys pipeline components" "Kubernetes API"
        kuberayOperator -> rayClusters "Creates Ray head and worker pods" "Kubernetes API"
        trustyaiOperator -> trustyaiServices "Deploys TrustyAI services" "Kubernetes API"

        codeflareOperator -> kuberayOperator "Wraps RayCluster in AppWrapper" "Kubernetes API"
        kueueOperator -> codeflareOperator "Admits workloads based on quota" "Kubernetes API"
        trustyaiOperator -> kserveOperator "Patches InferenceServices with logging" "Kubernetes API"

        dashboard -> prometheus "Queries platform and model metrics" "HTTPS/9091"
        prometheus -> inferenceServices "Scrapes inference metrics" "ServiceMonitor"
        prometheus -> modelmeshRuntime "Scrapes serving metrics" "ServiceMonitor"
        prometheus -> trustyaiServices "Scrapes fairness metrics" "ServiceMonitor"

        # RHOAI to external dependencies
        rhoai -> openshift "Runs on, uses API, networking, storage" "Kubernetes API/6443"
        rhoai -> oauth "Authenticates users" "OAuth 2.0/6443"

        inferenceServices -> knative "Uses for serverless autoscaling" "Kubernetes API"
        inferenceServices -> istio "Uses for traffic routing and mTLS" "Istio API"
        modelController -> istio "Configures VirtualServices and PeerAuthentication" "Istio API"

        pipelines -> tekton "Executes pipeline tasks" "Tekton API"

        notebooks -> s3Storage "Stores training data and model artifacts" "S3 API/443"
        inferenceServices -> s3Storage "Downloads model artifacts" "S3 API/443"
        modelmeshRuntime -> s3Storage "Downloads model artifacts" "S3 API/443"
        pipelines -> s3Storage "Stores pipeline artifacts" "S3 API/443"

        notebooks -> pypi "Installs Python packages" "HTTPS/443"
        notebooks -> gitRepositories "Clones repositories and pushes code" "HTTPS/443, SSH/22"
        notebooks -> databases "Queries training and inference data" "TCP/5432,3306,27017"

        rhoai -> containerRegistry "Pulls container images" "HTTPS/443"

        codeflareOperator -> machineAPI "Triggers node autoscaling" "Kubernetes API/6443"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
            title "Red Hat OpenShift AI 2.8 - System Context"
            description "High-level view of RHOAI platform and its interactions with users and external systems"
        }

        container rhoai "PlatformContainers" {
            include *
            autoLayout tb
            title "Red Hat OpenShift AI 2.8 - Platform Containers"
            description "Major containers within the RHOAI platform"
        }

        component operatorControlPlane "OperatorComponents" {
            include *
            autoLayout tb
            title "RHOAI Operator Control Plane"
            description "Operators managing platform lifecycle"
        }

        component platformServices "PlatformServiceComponents" {
            include *
            autoLayout lr
            title "RHOAI Platform Services"
            description "Central services for user interactions"
        }

        component userWorkloads "UserWorkloadComponents" {
            include *
            autoLayout tb
            title "RHOAI User Workloads"
            description "User-deployed ML workloads"
        }

        dynamic rhoai "ModelDeploymentWorkflow" "Model Development to Deployment Workflow" {
            dataScientist -> dashboard "1. Create notebook workspace"
            dashboard -> notebookController "2. Create Notebook CR"
            notebookController -> notebooks "3. Provision notebook pod"
            dataScientist -> notebooks "4. Develop and train model"
            notebooks -> s3Storage "5. Save model artifacts"
            dataScientist -> pipelines "6. Create and run pipeline"
            pipelines -> tekton "7. Execute pipeline tasks"
            pipelines -> s3Storage "8. Store pipeline artifacts"
            dataScientist -> dashboard "9. Create InferenceService"
            dashboard -> kserveOperator "10. Submit InferenceService CR"
            kserveOperator -> inferenceServices "11. Create predictor pod"
            modelController -> inferenceServices "12. Add Route and Service Mesh config"
            inferenceServices -> s3Storage "13. Download model"
            inferenceServices -> istio "14. Register with service mesh"
            dataScientist -> inferenceServices "15. Test inference endpoint"
            autoLayout lr
        }

        dynamic rhoai "DistributedTrainingWorkflow" "Distributed Training with Ray and Kueue" {
            dataScientist -> notebooks "1. Submit RayCluster CR"
            notebooks -> kuberayOperator "2. Create RayCluster"
            codeflareOperator -> kuberayOperator "3. Wrap in AppWrapper"
            kueueOperator -> codeflareOperator "4. Admit workload"
            kuberayOperator -> rayClusters "5. Create Ray head and workers"
            dataScientist -> rayClusters "6. Submit distributed training job"
            rayClusters -> s3Storage "7. Store training checkpoints"
            autoLayout lr
        }

        dynamic rhoai "AIExplainabilityWorkflow" "AI Explainability with TrustyAI" {
            mlEngineer -> dashboard "1. Create TrustyAIService CR"
            dashboard -> trustyaiOperator "2. Deploy TrustyAI"
            trustyaiOperator -> trustyaiServices "3. Create service and Route"
            trustyaiOperator -> kserveOperator "4. Patch InferenceService with logger"
            dataScientist -> inferenceServices "5. Send inference request"
            inferenceServices -> trustyaiServices "6. Send payload copy"
            trustyaiServices -> prometheus "7. Expose fairness metrics"
            mlEngineer -> dashboard "8. View bias analysis"
            dashboard -> prometheus "9. Query fairness metrics"
            autoLayout lr
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }

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

            element "External" {
                background #999999
                color #ffffff
            }

            element "External - Red Hat" {
                background #cc0000
                color #ffffff
            }

            element "External - OpenShift Service Mesh" {
                background #cc0000
                color #ffffff
            }

            element "External - OpenShift Serverless" {
                background #cc0000
                color #ffffff
            }

            element "External - OpenShift Pipelines" {
                background #cc0000
                color #ffffff
            }

            element "External - OpenShift" {
                background #cc0000
                color #ffffff
            }

            element "External - AWS S3 / Minio / Ceph" {
                background #ff9900
                color #ffffff
            }

            element "External - quay.io / registry.redhat.io" {
                background #cc0000
                color #ffffff
            }

            element "External - GitHub / GitLab" {
                background #24292e
                color #ffffff
            }

            element "External - pypi.org" {
                background #3776ab
                color #ffffff
            }

            element "External - PostgreSQL / MySQL / MongoDB" {
                background #336791
                color #ffffff
            }
        }
    }
}
