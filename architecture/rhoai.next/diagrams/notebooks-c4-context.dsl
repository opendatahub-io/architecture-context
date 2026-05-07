workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses interactive workbenches for ML/AI development"
        mlEngineer = person "ML Engineer" "Builds and deploys ML pipelines using Elyra"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and image lifecycle"

        notebooks = softwareSystem "Notebooks (Workbench & Runtime Images)" "Pre-built container images for interactive data science workbenches and pipeline runtimes" {
            jupyterMinimal = container "jupyter-minimal" "Foundation Jupyter workbench with minimal dependencies" "Container Image (CPU/CUDA/ROCm)"
            jupyterDatascience = container "jupyter-datascience" "Data science workbench with pandas, sklearn, mongocli (FIPS)" "Container Image (CPU)"
            jupyterPytorch = container "jupyter-pytorch" "GPU-accelerated PyTorch deep learning workbench" "Container Image (CUDA/ROCm)"
            jupyterTensorflow = container "jupyter-tensorflow" "GPU-accelerated TensorFlow deep learning workbench" "Container Image (CUDA/ROCm)"
            jupyterTrustyai = container "jupyter-trustyai" "AI explainability and fairness analysis workbench" "Container Image (CPU)"
            jupyterLlmcompressor = container "jupyter-pytorch-llmcompressor" "LLM compression and quantization workbench" "Container Image (CUDA)"
            codeserver = container "code-server" "VS Code-based workbench with nginx proxy" "Container Image (CPU)"
            rstudio = container "rstudio" "RStudio Server IDE for R and Python" "Container Image (CPU/CUDA)"
            runtimeMinimal = container "runtime-minimal" "Minimal pipeline runtime for Elyra nodes" "Container Image (CPU)"
            runtimeDatascience = container "runtime-datascience" "Pipeline runtime with data science libraries" "Container Image (CPU)"
            runtimePytorch = container "runtime-pytorch" "GPU-accelerated PyTorch pipeline runtime" "Container Image (CUDA/ROCm)"
            runtimeTensorflow = container "runtime-tensorflow" "GPU-accelerated TensorFlow pipeline runtime" "Container Image (CUDA/ROCm)"
            runtimeLlmcompressor = container "runtime-pytorch-llmcompressor" "LLM compression pipeline runtime" "Container Image (CUDA)"
            imagestreamManifests = container "ImageStream Manifests" "Kustomize manifests registering images with the platform" "Kustomize YAML"
            buildTooling = container "Build Tooling" "Lock file generators, Konflux pipeline integration" "Python/Bash Scripts"
        }

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Creates StatefulSets from ImageStream references; manages notebook pod lifecycle" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Reads ImageStream annotations to present available workbench images to users" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Applies kustomize manifests to create ImageStream resources on the cluster" "Internal RHOAI"
        elyra = softwareSystem "Elyra Pipeline Engine" "Uses runtime ImageStream annotations for pipeline node execution environment" "Internal RHOAI"
        openshiftImageStream = softwareSystem "OpenShift ImageStream" "Tracks container image references and tags" "OpenShift Platform"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes/OpenShift API for resource management" "OpenShift Platform"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io (RHOAI) / quay.io (ODH) for image storage" "External"
        konfluxBuild = softwareSystem "Konflux Build System" "Hermetic CI/CD pipeline with 102 Tekton PipelineRuns" "External"
        pypi = softwareSystem "PyPI / Package Registries" "Python package repositories for user-initiated installs" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for data access from notebooks" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code and notebook repositories" "External"
        mongodb = softwareSystem "MongoDB" "Document database accessed via mongocli" "External"

        # Relationships - Users
        dataScientist -> notebooks "Uses workbenches via Dashboard UI"
        mlEngineer -> notebooks "Runs pipelines using runtime images"
        platformAdmin -> rhodsOperator "Manages platform deployment"

        # Relationships - Build & Deploy
        konfluxBuild -> containerRegistry "Pushes built images" "HTTPS/443"
        rhodsOperator -> openshiftAPI "Applies kustomize manifests" "HTTPS/6443"
        rhodsOperator -> openshiftImageStream "Creates ImageStream resources"
        odhDashboard -> openshiftImageStream "Reads image annotations" "HTTPS/6443"
        odhNotebookController -> openshiftAPI "Creates StatefulSets" "HTTPS/6443"
        openshiftImageStream -> containerRegistry "References images" "HTTPS/443"

        # Relationships - Runtime
        dataScientist -> odhDashboard "Selects workbench image" "HTTPS/443"
        odhDashboard -> odhNotebookController "Triggers workbench creation"
        odhNotebookController -> notebooks "Creates notebook pods from images"
        elyra -> notebooks "Runs pipeline nodes using runtime images"

        # Relationships - Egress
        notebooks -> pypi "User pip install" "HTTPS/443"
        notebooks -> s3 "Data access" "HTTPS/443"
        notebooks -> gitRepos "Clone repositories" "HTTPS/443"
        notebooks -> mongodb "Database queries" "TCP/27017"

        # Internal image hierarchy
        jupyterMinimal -> jupyterDatascience "Base for"
        jupyterDatascience -> jupyterPytorch "Base for"
        jupyterDatascience -> jupyterTensorflow "Base for"
        jupyterDatascience -> jupyterTrustyai "Base for"
        jupyterPytorch -> jupyterLlmcompressor "Base for"
    }

    views {
        systemContext notebooks "SystemContext" {
            include *
            autoLayout
        }

        container notebooks "Containers" {
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
            element "OpenShift Platform" {
                background #ee0000
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
