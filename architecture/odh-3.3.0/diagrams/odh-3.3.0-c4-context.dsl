workspace "Open Data Hub 3.3.0" "C4 Context Diagram for ODH Platform" {

    model {
        # People
        dataScientist = person "Data Scientist" "Develops and deploys ML models using notebooks and pipelines"
        mlEngineer = person "ML Engineer" "Trains and fine-tunes models, manages ML workflows"
        platformAdmin = person "Platform Administrator" "Manages ODH platform configuration and components"
        externalClient = person "External Client" "Consumes model inference APIs"

        # The main system
        odh = softwareSystem "Open Data Hub 3.3.0" "Cloud-native AI/ML platform for OpenShift providing end-to-end data science capabilities from development to production" {
            tags "Platform"
        }

        # External systems
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for model artifacts, datasets, and pipeline outputs" {
            tags "External"
        }

        pypi = softwareSystem "PyPI Registry" "Python package index for installing ML libraries" {
            tags "External"
        }

        huggingface = softwareSystem "HuggingFace Hub" "Repository for pre-trained models and datasets" {
            tags "External"
        }

        containerRegistry = softwareSystem "Container Registry" "Stores container images for notebooks, operators, and runtimes" {
            tags "External"
        }

        kubernetes = softwareSystem "Kubernetes API Server" "OpenShift/Kubernetes control plane API" {
            tags "Infrastructure"
        }

        istio = softwareSystem "Service Mesh (Istio)" "Provides mTLS, traffic management, and observability" {
            tags "Infrastructure"
        }

        # Relationships - Users to ODH
        dataScientist -> odh "Develops models, creates notebooks, deploys models" "HTTPS/443 (OAuth)"
        mlEngineer -> odh "Trains models, fine-tunes LLMs, orchestrates pipelines" "HTTPS/443 (OAuth)"
        platformAdmin -> odh "Configures platform, manages components" "HTTPS/6443 (K8s API)"
        externalClient -> odh "Sends inference requests" "HTTPS/443"

        # ODH to external systems
        odh -> s3Storage "Stores/retrieves model artifacts, datasets, pipeline outputs" "HTTPS/443 (AWS IAM)"
        odh -> pypi "Installs Python packages" "HTTPS/443"
        odh -> huggingface "Downloads pre-trained models and datasets" "HTTPS/443 (API Keys)"
        odh -> containerRegistry "Pulls container images" "HTTPS/443 (Token)"

        # ODH to infrastructure
        odh -> kubernetes "Manages Kubernetes resources (CRDs, Pods, Services)" "HTTPS/6443 (ServiceAccount)"
        odh -> istio "Integrates with service mesh for mTLS and traffic routing" "mTLS"
    }

    views {
        systemContext odh "ODH-Context" {
            include *
            autoLayout lr
            description "System context diagram for Open Data Hub 3.3.0 showing users, external systems, and infrastructure dependencies"
        }

        styles {
            element "Platform" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "External" {
                background #e0e0e0
                color #000000
                shape RoundedBox
            }
            element "Infrastructure" {
                background #f5a623
                color #000000
                shape Cylinder
            }
            element "Person" {
                background #50e3c2
                color #000000
                shape Person
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
