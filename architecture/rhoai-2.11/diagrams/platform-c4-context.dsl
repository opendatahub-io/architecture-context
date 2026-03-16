workspace {
    model {
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using notebooks and pipelines"
        mlEngineer = person "ML Engineer" "Deploys and manages model serving, monitoring, and infrastructure"
        endUser = person "End User" "Consumes ML model predictions via APIs"

        rhoai = softwareSystem "Red Hat OpenShift AI 2.11" "Enterprise AI/ML platform for model development, training, serving, and monitoring" {
            platformOps = container "RHODS Operator" "Platform orchestrator managing all component lifecycles" "Go Operator" {
                tags "Platform Management"
            }

            dashboard = container "ODH Dashboard" "Web UI for platform management and component access" "React + Node.js" {
                tags "User Interface"
            }

            notebooks = container "Notebook Workbenches" "JupyterLab, RStudio, VS Code development environments" "Container Images" {
                tags "Development"
            }

            modelServing = container "Model Serving" "KServe + ModelMesh for scalable inference" "Go Operators + Python Servers" {
                kserve = component "KServe Controller" "Single-model serverless serving with autoscaling" "Go Operator"
                modelController = component "ODH Model Controller" "OpenShift Routes, Istio, Authorino integration" "Go Operator"
                modelMesh = component "ModelMesh Serving" "Multi-model serving with intelligent placement" "Go Operator"
            }

            pipelines = container "Data Science Pipelines" "ML pipeline orchestration and experiment tracking" "Argo Workflows + MariaDB" {
                tags "ML Pipelines"
            }

            training = container "Distributed Training" "PyTorch, TensorFlow, MPI training at scale" "Training Operator" {
                tags "Training"
            }

            ray = container "Distributed Computing" "Ray clusters for distributed Python workloads" "KubeRay + CodeFlare" {
                tags "Distributed Computing"
            }

            queue = container "Resource Management" "Job queueing and quota management" "Kueue" {
                tags "Resource Management"
            }

            monitoring = container "Model Monitoring" "Explainability, fairness, bias detection" "TrustyAI" {
                tags "Monitoring"
            }

            observability = container "Observability" "Metrics, alerts, and monitoring" "Prometheus + Alertmanager" {
                tags "Observability"
            }
        }

        openshift = softwareSystem "OpenShift Container Platform" "Kubernetes-based container orchestration platform" {
            tags "Infrastructure"
        }

        serviceMesh = softwareSystem "Istio Service Mesh" "Traffic management, mTLS, and observability" {
            tags "Infrastructure"
        }

        knative = softwareSystem "Knative Serving" "Serverless autoscaling and request routing" {
            tags "Infrastructure"
        }

        oauth = softwareSystem "OpenShift OAuth" "Unified authentication and SSO" {
            tags "Infrastructure"
        }

        s3 = softwareSystem "S3 Storage" "Object storage for models, datasets, artifacts" {
            tags "External Storage"
        }

        registry = softwareSystem "Container Registry" "Quay.io, Red Hat registries for container images" {
            tags "External Service"
        }

        git = softwareSystem "Git Repositories" "GitHub, GitLab for source code and notebooks" {
            tags "External Service"
        }

        packageRepos = softwareSystem "Package Repositories" "PyPI, Conda for Python packages" {
            tags "External Service"
        }

        externalDB = softwareSystem "External Database" "Optional MySQL/PostgreSQL for pipeline metadata" {
            tags "External Service"
        }

        // User interactions
        dataScientist -> dashboard "Accesses platform, launches notebooks, deploys models" "HTTPS/443 OAuth"
        mlEngineer -> dashboard "Manages infrastructure, monitors models" "HTTPS/443 OAuth"
        endUser -> modelServing "Sends inference requests" "HTTPS/443 Bearer/mTLS"

        // Dashboard interactions
        dashboard -> notebooks "Launches workbenches via Notebook Controller" "HTTP/8080"
        dashboard -> modelServing "Manages InferenceServices" "HTTP/8080"
        dashboard -> pipelines "Creates and monitors pipelines" "HTTP/8080"
        dashboard -> observability "Queries metrics" "HTTP/9090"

        // Platform orchestration
        platformOps -> dashboard "Deploys and configures" "Kubernetes API"
        platformOps -> notebooks "Deploys Notebook Controller" "Kubernetes API"
        platformOps -> modelServing "Deploys serving components" "Kubernetes API"
        platformOps -> pipelines "Deploys DSP Operator" "Kubernetes API"
        platformOps -> training "Deploys Training Operator" "Kubernetes API"
        platformOps -> ray "Deploys KubeRay and CodeFlare" "Kubernetes API"
        platformOps -> queue "Deploys Kueue" "Kubernetes API"
        platformOps -> monitoring "Deploys TrustyAI Operator" "Kubernetes API"

        // Component interactions
        notebooks -> s3 "Uploads/downloads models and data" "HTTPS/443 AWS IAM"
        notebooks -> git "Clones repos, pushes code" "HTTPS/443 SSH/PAT"
        notebooks -> packageRepos "Installs Python packages" "HTTPS/443"

        modelServing -> s3 "Downloads model artifacts" "HTTPS/443 AWS IAM"
        modelServing -> knative "Creates serverless services" "Kubernetes API"
        modelServing -> serviceMesh "Configures traffic routing, mTLS" "Kubernetes API"

        pipelines -> s3 "Stores pipeline artifacts" "HTTPS/443 S3 keys"
        pipelines -> externalDB "Stores metadata (optional)" "MySQL/3306 TLS"

        training -> s3 "Saves model checkpoints" "HTTPS/443 S3 keys"
        training -> queue "Submits jobs for queueing" "Kubernetes API"

        ray -> queue "Submits Ray workloads via AppWrapper" "Kubernetes API"

        queue -> training "Admits training jobs when resources available" "Kubernetes API"
        queue -> ray "Admits Ray clusters when quota permits" "Kubernetes API"

        monitoring -> modelServing "Monitors InferenceServices for bias" "HTTP payload processor"
        monitoring -> observability "Exports fairness metrics" "ServiceMonitor"

        // Infrastructure dependencies
        rhoai -> openshift "Runs on, uses Routes, OAuth, Service CA" "Kubernetes API/HTTPS"
        rhoai -> oauth "Authenticates users" "OpenShift OAuth protocol"
        modelServing -> serviceMesh "Uses for mTLS, traffic management" "Istio API"
        modelServing -> knative "Uses for autoscaling" "Knative API"

        // Observability
        observability -> dashboard "Scrapes metrics" "HTTP/8080"
        observability -> notebooks "Scrapes metrics" "HTTP/8080"
        observability -> modelServing "Scrapes metrics" "HTTP/8080"
        observability -> pipelines "Scrapes metrics" "HTTP/8080"
        observability -> training "Scrapes metrics" "HTTP/8080"
        observability -> ray "Scrapes metrics" "HTTP/8080"
        observability -> queue "Scrapes metrics" "HTTP/8080"
        observability -> monitoring "Scrapes metrics" "HTTP/8080"

        // Image pulls
        notebooks -> registry "Pulls workbench images" "HTTPS/443 Pull secrets"
        modelServing -> registry "Pulls server images" "HTTPS/443 Pull secrets"
        training -> registry "Pulls training images" "HTTPS/443 Pull secrets"
    }

    views {
        systemContext rhoai "SystemContext" {
            include *
            autoLayout tb
        }

        container rhoai "Containers" {
            include *
            autoLayout tb
        }

        component modelServing "ModelServingComponents" {
            include *
            autoLayout lr
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
            element "Platform Management" {
                background #e74c3c
                color #ffffff
            }
            element "User Interface" {
                background #3498db
                color #ffffff
            }
            element "Development" {
                background #9b59b6
                color #ffffff
            }
            element "ML Pipelines" {
                background #9b59b6
                color #ffffff
            }
            element "Training" {
                background #f39c12
                color #ffffff
            }
            element "Distributed Computing" {
                background #1abc9c
                color #ffffff
            }
            element "Resource Management" {
                background #34495e
                color #ffffff
            }
            element "Monitoring" {
                background #e67e22
                color #ffffff
            }
            element "Observability" {
                background #95a5a6
                color #000000
            }
            element "Infrastructure" {
                background #ecf0f1
                color #000000
            }
            element "External Storage" {
                background #f5a623
                color #000000
            }
            element "External Service" {
                background #d5d8dc
                color #000000
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
