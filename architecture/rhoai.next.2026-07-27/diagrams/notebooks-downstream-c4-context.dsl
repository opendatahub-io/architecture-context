workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML workbenches for interactive data science"
        platformAdmin = person "Platform Admin" "Configures RHOAI and manages notebook image availability"

        notebooksDownstream = softwareSystem "notebooks-downstream" "Downstream fork that builds RHOAI Notebook/Workbench container images across multiple IDE types and ML runtime variants" {
            jupyterImages = container "Jupyter Notebook Images" "Minimal, datascience, PyTorch, TensorFlow variants" "Dockerfile / UBI9 + Python 3.11/3.12"
            codeserverImages = container "code-server IDE Images" "VS Code-based IDE with nginx proxy" "Dockerfile / UBI9"
            rstudioImages = container "RStudio IDE Images" "R-based IDE with optional CUDA" "Dockerfile / UBI9"
            runtimeImages = container "ML Runtime Images" "Lightweight inference runtime containers" "Dockerfile / UBI9"
            buildInputs = container "Build Inputs Analyzer" "Dockerfile analysis tooling using BuildKit and OCI image-spec" "Go 1.24"
            checkPayload = container "Payload Checker" "Verifies payload compliance" "Go / openshift/check-payload"
            ciHarness = container "CI Test Harness" "Kustomize-based test deployments" "Python / make_test.py"
        }

        notebookController = softwareSystem "RHOAI Notebook Controller" "Manages workbench lifecycle as StatefulSet-backed pods" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and workbenches" "Internal RHOAI"
        oauthProxy = softwareSystem "OAuth Proxy" "Sidecar injected by Notebook Controller for authentication" "Internal RHOAI"

        s3Storage = softwareSystem "S3-Compatible Storage" "Dataset and model artifact storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for structured data" "External"
        mongodb = softwareSystem "MongoDB" "Document database" "External"
        mysql = softwareSystem "MySQL" "Relational database" "External"
        kafka = softwareSystem "Apache Kafka" "Event streaming platform" "External"
        nvidiaGPU = softwareSystem "NVIDIA CUDA Runtime" "GPU acceleration via CUDA 12.6" "External"
        amdGPU = softwareSystem "AMD ROCm Runtime" "GPU acceleration via ROCm" "External"

        dataScientist -> odhDashboard "Requests workbench creation"
        odhDashboard -> notebookController "Creates Notebook CR"
        notebookController -> notebooksDownstream "Deploys container images as StatefulSets"
        notebookController -> oauthProxy "Injects OAuth proxy sidecar"
        dataScientist -> oauthProxy "Accesses workbench via Route" "HTTPS/443"
        oauthProxy -> notebooksDownstream "Forwards authenticated requests" "HTTP/localhost"

        notebooksDownstream -> s3Storage "Reads/writes datasets and models" "HTTPS/443 boto3/minio"
        notebooksDownstream -> postgresql "Queries structured data" "5432/TCP psycopg"
        notebooksDownstream -> mongodb "Queries document data" "27017/TCP pymongo"
        notebooksDownstream -> mysql "Queries structured data" "3306/TCP mysql-connector-python"
        notebooksDownstream -> kafka "Streams event data" "9092/TCP kafka-python-ng"
        notebooksDownstream -> nvidiaGPU "GPU-accelerated computation" "CUDA 12.6"
        notebooksDownstream -> amdGPU "GPU-accelerated computation" "ROCm"

        platformAdmin -> notebooksDownstream "Configures available image variants"
    }

    views {
        systemContext notebooksDownstream "SystemContext" {
            include *
            autoLayout
        }

        container notebooksDownstream "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
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
        }
    }
}
