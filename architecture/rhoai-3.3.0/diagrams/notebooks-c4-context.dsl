workspace {
    model {
        datascientist = person "Data Scientist" "Develops and trains ML models using interactive notebooks"
        devops = person "DevOps Engineer" "Manages workbench infrastructure and CI/CD pipelines"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Provides containerized IDE environments (Jupyter, RStudio, CodeServer) for data science workloads" {
            jupyterWorkbenches = container "Jupyter Workbenches" "Interactive notebook environments with ML frameworks" "Python 3.12, JupyterLab 4.4" {
                jupyterMinimal = component "Jupyter Minimal" "Lightweight Jupyter with core libraries" "Container Image"
                jupyterDatascience = component "Jupyter DataScience" "Jupyter with pandas, sklearn, numpy" "Container Image"
                jupyterPyTorch = component "Jupyter PyTorch" "Jupyter with PyTorch for GPU" "Container Image"
                jupyterTensorFlow = component "Jupyter TensorFlow" "Jupyter with TensorFlow for GPU" "Container Image"
                jupyterTrustyAI = component "Jupyter TrustyAI" "Jupyter with AI explainability tools" "Container Image"
            }

            otherIDEs = container "Alternative IDEs" "Non-Jupyter development environments" "RStudio, VS Code" {
                rstudio = component "RStudio Workbench" "R IDE for statistical computing" "Container Image"
                codeserver = component "CodeServer Workbench" "VS Code in browser" "Container Image"
            }

            runtimeImages = container "Runtime Images" "Headless execution environments for Elyra pipelines" "Python 3.12" {
                runtimeMinimal = component "Runtime Minimal" "Core libraries for pipeline execution" "Container Image"
                runtimePyTorch = component "Runtime PyTorch" "PyTorch for GPU pipeline nodes" "Container Image"
                runtimeTensorFlow = component "Runtime TensorFlow" "TensorFlow for GPU pipeline nodes" "Container Image"
            }

            baseImages = container "Base Images" "Foundation images with CPU/GPU libraries" "UBI9, CUDA, ROCM" {
                baseCPU = component "CPU Base" "UBI9 Python runtime" "Container Image"
                baseCUDA = component "CUDA Base" "NVIDIA GPU acceleration" "Container Image"
                baseROCM = component "ROCM Base" "AMD GPU acceleration" "Container Image"
            }
        }

        notebookController = softwareSystem "odh-notebook-controller" "Kubernetes operator that deploys and manages user workbenches" "Internal ODH"
        dashboard = softwareSystem "odh-dashboard" "Web UI for browsing and launching workbench images" "Internal ODH"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Executes Elyra pipeline workflows using runtime images" "Internal ODH"
        oauthProxy = softwareSystem "oauth-proxy" "Authentication sidecar for workbench access control" "Internal ODH"

        kubernetes = softwareSystem "Kubernetes API" "Container orchestration and resource management" "External"
        pypi = softwareSystem "PyPI" "Python package index for runtime package installation" "External"
        s3storage = softwareSystem "S3 Storage" "Object storage for datasets and model artifacts" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code version control" "External"
        konflux = softwareSystem "Konflux CI/CD" "Automated multi-arch container builds and image publishing" "External"
        quay = softwareSystem "Quay.io" "Container image registry (ODH)" "External"
        redhatreg = softwareSystem "registry.redhat.io" "Container image registry (RHOAI)" "External"

        # User interactions
        datascientist -> dashboard "Browses and launches workbenches via web UI" "HTTPS/443"
        datascientist -> notebooks "Accesses Jupyter/RStudio/CodeServer via browser" "HTTPS/443, OAuth"
        devops -> konflux "Triggers builds via Git commits" "HTTPS/443"

        # Platform interactions
        dashboard -> kubernetes "Reads ImageStreams to discover available images" "HTTPS/6443"
        dashboard -> notebookController "Creates Notebook CRD to request workbench deployment" "HTTPS/6443"
        notebookController -> kubernetes "Creates StatefulSet, Service, Route for workbench" "HTTPS/6443"
        notebookController -> notebooks "Deploys workbench pods using selected image" "Container orchestration"
        oauthProxy -> kubernetes "Validates OAuth tokens for workbench access" "HTTPS/6443"
        oauthProxy -> notebooks "Protects workbench access with authentication" "HTTP/8888 internal"
        kubeflowPipelines -> runtimeImages "Executes pipeline nodes in runtime containers" "Container orchestration"
        kubeflowPipelines -> kubernetes "Creates pods for Elyra pipeline execution" "HTTPS/6443"

        # Workbench runtime interactions
        notebooks -> kubernetes "Executes kubectl/oc commands from workbench terminal" "HTTPS/6443"
        notebooks -> pypi "Installs Python packages at runtime (pip/uv)" "HTTPS/443"
        notebooks -> s3storage "Loads datasets and saves model artifacts" "HTTPS/443, AWS IAM"
        notebooks -> gitRepos "Clones repositories and pushes code" "HTTPS/443, SSH"

        # Build and deployment
        konflux -> kubernetes "Updates ImageStream tags with new image digests" "HTTPS/6443"
        konflux -> quay "Publishes ODH workbench images" "HTTPS/443"
        konflux -> redhatreg "Publishes RHOAI workbench images" "HTTPS/443"
        kubernetes -> quay "Pulls workbench images for pod creation" "HTTPS/443"
        kubernetes -> redhatreg "Pulls RHOAI workbench images for pod creation" "HTTPS/443"
    }

    views {
        systemContext notebooks "NotebooksSystemContext" {
            include *
            autoLayout lr
        }

        container notebooks "NotebooksContainers" {
            include *
            autoLayout tb
        }

        component jupyterWorkbenches "JupyterWorkbenchesComponents" {
            include *
            autoLayout lr
        }

        component runtimeImages "RuntimeImagesComponents" {
            include *
            autoLayout lr
        }

        styles {
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }

            element "Software System" {
                background #7ed321
                color #000000
            }

            element "External" {
                background #999999
                color #ffffff
            }

            element "Internal ODH" {
                background #f5a623
                color #000000
            }

            element "Container" {
                background #4a90e2
                color #ffffff
            }

            element "Component" {
                background #dae8fc
                color #000000
            }

            element "Container Image" {
                shape hexagon
                background #4a90e2
                color #ffffff
            }
        }

        theme default
    }
}
