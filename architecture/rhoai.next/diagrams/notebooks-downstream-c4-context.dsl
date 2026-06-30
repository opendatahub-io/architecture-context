workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses workbench environments for ML experimentation"
        mlEngineer = person "ML Engineer" "Authors and runs ML pipelines using Elyra"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and image catalog"

        notebooksDownstream = softwareSystem "notebooks-downstream" "Container image build factory producing 32+ workbench and runtime images for RHOAI" {
            jupyterMinimal = container "Jupyter Minimal" "Base JupyterLab workbench with minimal Python dependencies" "Container Image (UBI9 Python 3.11/3.12)" "Workbench"
            jupyterDataScience = container "Jupyter Data Science" "Full-featured data science workbench with ML libraries and database connectors" "Container Image" "Workbench"
            jupyterPyTorch = container "Jupyter PyTorch" "GPU-accelerated deep learning workbench with PyTorch 2.6 + CUDA 12.6" "Container Image" "Workbench"
            jupyterTensorFlow = container "Jupyter TensorFlow" "GPU-accelerated deep learning workbench with TensorFlow + CUDA 12.6" "Container Image" "Workbench"
            jupyterTrustyAI = container "Jupyter TrustyAI" "AI fairness, explainability, and bias detection workbench" "Container Image" "Workbench"
            codeServer = container "Code Server" "VS Code-based web IDE with nginx reverse proxy (code-server 4.98)" "Container Image" "Workbench"
            rstudioServer = container "RStudio Server" "RStudio Server 2024.04.2 with R 4.4 and Python, built on RHEL9" "Container Image" "Workbench"
            runtimeMinimal = container "Runtime Minimal" "Lightweight Python runtime for Elyra pipeline node execution" "Container Image" "Runtime"
            runtimeDataScience = container "Runtime Data Science" "Data science Python runtime with pre-installed ML libraries" "Container Image" "Runtime"
            runtimePyTorch = container "Runtime PyTorch" "GPU-accelerated PyTorch runtime for pipeline training steps" "Container Image" "Runtime"
            buildTooling = container "Build Tooling" "Makefile, sandbox.py, buildinputs (Go), CI helper scripts" "Build Scripts" "Build"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream and BuildConfig definitions (18 base + 14 additional)" "YAML Manifests" "Config"
        }

        odhNotebookController = softwareSystem "odh-notebook-controller" "Deploys workbench images as StatefulSets per user" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Displays available workbench images from ImageStream metadata" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests to cluster" "Internal RHOAI"
        elyra = softwareSystem "Elyra" "Executes pipeline nodes using runtime images" "Internal RHOAI"
        kfpSdk = softwareSystem "Kubeflow Pipelines SDK" "Pipeline authoring library (bundled in images)" "Internal RHOAI"
        codeflareSdk = softwareSystem "Codeflare SDK" "Distributed Ray workload management (bundled in images)" "Internal RHOAI"
        tektonKonflux = softwareSystem "Tekton/Konflux" "Multi-arch container image build pipelines" "CI/CD"

        pypi = softwareSystem "PyPI" "Python package repository" "External"
        quayOdh = softwareSystem "quay.io/opendatahub" "Upstream container image registry" "External"
        quayModh = softwareSystem "quay.io/modh" "Downstream RHOAI container image registry" "External"
        nvidiaRepos = softwareSystem "NVIDIA CUDA/cuDNN/NCCL" "GPU compute libraries (CUDA 12.6, cuDNN 9.5, NCCL 2.23)" "External"
        amdRocm = softwareSystem "AMD ROCm" "AMD GPU compute libraries (ROCm 6.2.4)" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for data science workflows" "External"
        databases = softwareSystem "Databases" "PostgreSQL, MongoDB, MySQL, MSSQL via ODBC" "External"
        kafkaBrokers = softwareSystem "Kafka Brokers" "Event streaming via Kafka-Python-ng" "External"

        # Relationships
        dataScientist -> notebooksDownstream "Uses workbench environments" "HTTPS/443 via RHOAI Gateway"
        mlEngineer -> elyra "Submits ML pipelines"
        platformAdmin -> rhoaiDashboard "Manages workbench image catalog"

        rhodsOperator -> kustomizeManifests "Deploys ImageStream manifests" "kustomize"
        odhNotebookController -> notebooksDownstream "Deploys workbench images as StatefulSets" "Kubernetes API/6443"
        rhoaiDashboard -> kustomizeManifests "Reads ImageStream annotations" "Kubernetes API"
        elyra -> runtimeMinimal "Executes pipeline nodes" "HTTP/8080"
        elyra -> runtimeDataScience "Executes pipeline nodes" "HTTP/8080"
        elyra -> runtimePyTorch "Executes pipeline nodes" "HTTP/8080"

        tektonKonflux -> notebooksDownstream "Builds container images" "Multi-arch pipeline"
        tektonKonflux -> quayOdh "Publishes upstream images" "HTTPS/443"
        tektonKonflux -> quayModh "Publishes downstream images" "HTTPS/443"

        buildTooling -> pypi "Downloads Python packages" "HTTPS/443"
        buildTooling -> nvidiaRepos "Downloads CUDA toolkit" "HTTPS/443"
        buildTooling -> amdRocm "Downloads ROCm libraries" "HTTPS/443"

        jupyterDataScience -> s3Storage "Accesses object storage" "HTTPS/443"
        jupyterDataScience -> databases "Connects to databases" "TCP/various"
        jupyterDataScience -> kafkaBrokers "Event streaming" "TCP/9092"
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
            element "CI/CD" {
                background #f5a623
                color #ffffff
            }
            element "Workbench" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #d6b656
                color #ffffff
            }
            element "Build" {
                background #b85450
                color #ffffff
            }
            element "Config" {
                background #9673a6
                color #ffffff
            }
        }
    }
}
