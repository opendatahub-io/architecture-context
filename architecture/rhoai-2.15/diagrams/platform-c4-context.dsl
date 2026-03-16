workspace {
    model {
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using notebooks, pipelines, and serving infrastructure"
        mlEngineer = person "ML Engineer" "Manages model lifecycle, deployment pipelines, and production serving"
        platformAdmin = person "Platform Administrator" "Manages RHOAI platform, quotas, and multi-tenant access"

        rhoai = softwareSystem "Red Hat OpenShift AI 2.15" "Enterprise ML/AI platform providing notebooks, training, serving, pipelines, and monitoring" {
            rhoaiOperator = container "RHOAI Operator" "Central orchestrator managing all data science components" "Go Operator" {
                tags "Operator"
            }

            dashboard = container "ODH Dashboard" "Unified web UI for platform management" "React + Node.js" {
                tags "UI"
            }

            notebooks = container "Workbenches" "Interactive development environments" "Jupyter, RStudio, VS Code" {
                tags "Development"
            }

            kserve = container "KServe" "Serverless model serving with autoscaling" "Go + Python" {
                tags "Serving"
            }

            modelmesh = container "ModelMesh Serving" "High-density multi-model serving" "Go + C++" {
                tags "Serving"
            }

            pipelines = container "Data Science Pipelines" "ML workflow orchestration and automation" "Kubeflow Pipelines + Argo" {
                tags "MLOps"
            }

            training = container "Training Operator" "Distributed ML training framework" "Go Operator" {
                tags "Training"
            }

            ray = container "Ray (KubeRay + CodeFlare)" "Distributed computing platform" "Python + Go" {
                tags "Compute"
            }

            kueue = container "Kueue" "Job queueing and resource quotas" "Go Operator" {
                tags "Scheduling"
            }

            modelRegistry = container "Model Registry" "ML model metadata and versioning" "Python + PostgreSQL" {
                tags "MLOps"
            }

            trustyai = container "TrustyAI" "AI explainability and bias detection" "Java Quarkus" {
                tags "Monitoring"
            }
        }

        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes distribution providing enterprise container orchestration" "External Platform" {
            tags "External" "Platform"
        }

        istio = softwareSystem "Red Hat OpenShift Service Mesh" "Service mesh for traffic management, security, and observability" "External Platform" {
            tags "External" "Platform"
        }

        knative = softwareSystem "OpenShift Serverless" "Serverless platform based on Knative Serving" "External Platform" {
            tags "External" "Platform"
        }

        oauth = softwareSystem "OpenShift OAuth" "Authentication and authorization service" "External Platform" {
            tags "External" "Platform"
        }

        prometheus = softwareSystem "OpenShift Monitoring" "Platform and user workload monitoring" "External Platform" {
            tags "External" "Platform"
        }

        s3 = softwareSystem "S3-Compatible Storage" "Object storage for models, artifacts, and datasets" "External Storage" {
            tags "External" "Storage"
        }

        postgresql = softwareSystem "PostgreSQL/MySQL" "Relational database for metadata persistence" "External Storage" {
            tags "External" "Storage"
        }

        externalRegistry = softwareSystem "Container/Package Registries" "quay.io, registry.redhat.io, pypi.org" "External" {
            tags "External" "Registry"
        }

        cicd = softwareSystem "CI/CD System" "Automated ML pipeline triggers and deployments" "External" {
            tags "External" "Integration"
        }

        monitoringTools = softwareSystem "External Monitoring" "Grafana, Alertmanager, PagerDuty" "External" {
            tags "External" "Integration"
        }

        // User to RHOAI relationships
        dataScientist -> dashboard "Manages projects, notebooks, models via web UI" "HTTPS/443"
        dataScientist -> notebooks "Develops ML models interactively" "HTTPS/443"
        dataScientist -> pipelines "Submits and monitors ML workflows" "HTTPS/443"
        mlEngineer -> dashboard "Manages model deployments and monitoring" "HTTPS/443"
        mlEngineer -> kserve "Deploys and scales inference services" "HTTPS/443 (via Dashboard or kubectl)"
        mlEngineer -> modelRegistry "Versions and catalogs production models" "HTTPS/443, gRPC/9090"
        platformAdmin -> rhoaiOperator "Configures platform via DataScienceCluster CR" "kubectl"

        // RHOAI internal integrations
        rhoaiOperator -> dashboard "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> kserve "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> modelmesh "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> pipelines "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> training "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> ray "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> kueue "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> modelRegistry "Deploys and configures" "Kubernetes API"
        rhoaiOperator -> trustyai "Deploys and configures" "Kubernetes API"

        dashboard -> kserve "Manages InferenceServices via UI" "Kubernetes API"
        dashboard -> modelRegistry "Queries model metadata" "REST API/8080"
        dashboard -> pipelines "Displays pipeline runs" "REST API/8888"
        dashboard -> prometheus "Queries metrics for dashboards" "PromQL/9091"

        notebooks -> pipelines "Submits ML workflows via SDK" "REST API/8888, gRPC/8887"
        notebooks -> kserve "Deploys models via SDK" "Kubernetes API"
        notebooks -> modelRegistry "Registers trained models" "REST API/8080, gRPC/9090"
        notebooks -> s3 "Reads datasets, writes artifacts" "HTTPS/443"

        pipelines -> kserve "Auto-deploys models from workflows" "Kubernetes API"
        pipelines -> modelRegistry "Registers pipeline outputs" "REST API/8080"
        pipelines -> s3 "Stores pipeline artifacts" "HTTPS/443"
        pipelines -> postgresql "Stores pipeline metadata" "PostgreSQL/5432"

        kserve -> s3 "Loads model artifacts" "HTTPS/443"
        kserve -> prometheus "Exports inference metrics" "Prometheus scrape"

        modelmesh -> s3 "Loads model artifacts" "HTTPS/443"
        modelmesh -> prometheus "Exports serving metrics" "Prometheus scrape"

        training -> s3 "Reads training data, saves checkpoints" "HTTPS/443"
        training -> kueue "Requests job admission" "Kubernetes API"

        ray -> s3 "Reads/writes distributed datasets" "HTTPS/443"
        ray -> kueue "Requests cluster admission" "Kubernetes API"

        modelRegistry -> postgresql "Persists model metadata" "PostgreSQL/5432"
        modelRegistry -> istio "Uses for traffic management and mTLS" "Service mesh"

        trustyai -> kserve "Monitors inference requests for bias" "HTTP/8080 payload logging"
        trustyai -> postgresql "Stores inference data and metrics" "PostgreSQL/5432"
        trustyai -> prometheus "Exports fairness metrics" "Prometheus scrape"

        // RHOAI to OpenShift platform relationships
        rhoai -> openshift "Runs on, manages resources via API" "Kubernetes API/6443"
        kserve -> knative "Uses for serverless autoscaling" "Knative API"
        kserve -> istio "Uses for traffic routing and mTLS" "Istio API"
        modelmesh -> istio "Uses for service mesh (optional)" "Istio API"
        modelRegistry -> istio "Uses for traffic management and AuthZ" "Istio API"
        trustyai -> istio "Uses for inference logging" "Istio API"

        rhoai -> oauth "Authenticates users and services" "HTTPS/443"
        rhoai -> prometheus "Exports all component metrics" "Prometheus scrape"

        // External dependencies
        rhoai -> s3 "Stores/loads models, artifacts, datasets" "HTTPS/443"
        rhoai -> postgresql "Persists metadata for pipelines, models, monitoring" "PostgreSQL/5432, MySQL/3306"
        notebooks -> externalRegistry "Downloads packages and images" "HTTPS/443"
        pipelines -> externalRegistry "Pulls runtime images" "HTTPS/443"

        cicd -> pipelines "Triggers automated ML workflows" "REST API/8888"
        cicd -> kserve "Deploys models via GitOps" "Kubernetes API"
        prometheus -> monitoringTools "Federates metrics to external systems" "Prometheus remote write"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout lr
            description "System context diagram for Red Hat OpenShift AI 2.15"
        }

        container rhoai "Containers" {
            include *
            autoLayout lr
            description "Container diagram showing major RHOAI components"
        }

        dynamic rhoai "ModelDeploymentFlow" "Model deployment workflow from notebook to production serving" {
            dataScientist -> notebooks "1. Develop and train model"
            notebooks -> s3 "2. Save model artifacts"
            notebooks -> modelRegistry "3. Register model metadata"
            notebooks -> kserve "4. Create InferenceService"
            kserve -> s3 "5. Load model artifacts"
            kserve -> istio "6. Configure traffic routing"
            dataScientist -> kserve "7. Send inference requests"
            autoLayout lr
        }

        dynamic rhoai "PipelineExecutionFlow" "ML pipeline execution workflow" {
            dataScientist -> pipelines "1. Submit pipeline via SDK"
            pipelines -> s3 "2. Load input datasets"
            pipelines -> training "3. Execute distributed training"
            training -> s3 "4. Save model checkpoints"
            pipelines -> modelRegistry "5. Register trained model"
            pipelines -> kserve "6. Deploy model to production"
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

            element "External" {
                background #999999
                color #ffffff
            }

            element "Platform" {
                background #666666
                color #ffffff
            }

            element "Storage" {
                background #50e3c2
                color #000000
            }

            element "Registry" {
                background #bd10e0
                color #ffffff
            }

            element "Integration" {
                background #f5a623
                color #000000
            }

            element "Operator" {
                background #4a90e2
                color #ffffff
            }

            element "UI" {
                background #7ed321
                color #000000
            }

            element "Development" {
                background #f8e71c
                color #000000
            }

            element "Serving" {
                background #d0021b
                color #ffffff
            }

            element "MLOps" {
                background #9013fe
                color #ffffff
            }

            element "Training" {
                background #ff6900
                color #ffffff
            }

            element "Compute" {
                background #417505
                color #ffffff
            }

            element "Scheduling" {
                background #50e3c2
                color #000000
            }

            element "Monitoring" {
                background #b8e986
                color #000000
            }

            relationship "Relationship" {
                thickness 2
            }
        }
    }
}
