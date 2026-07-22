workspace {
    model {
        datascientist = person "Data Scientist" "Creates and uses workbench environments for ML/AI development"
        mlEngineer = person "ML Engineer" "Builds and deploys ML pipelines using Elyra runtimes"

        notebooksDownstream = softwareSystem "Notebooks (Workbench & Runtime Images)" "Container image factory producing ~32 workbench and runtime image variants for RHOAI" {
            jupyterMinimal = container "Jupyter Minimal" "Lightweight JupyterLab with core Python data science env" "Container Image (Python 3.11/3.12, UBI9)" "workbench"
            jupyterDS = container "Jupyter Data Science" "Extended JupyterLab with pandas, scikit-learn, Elyra, MongoDB CLI, MSSQL" "Container Image (Python 3.11/3.12, UBI9)" "workbench"
            jupyterPyTorch = container "Jupyter PyTorch" "CUDA-accelerated JupyterLab with PyTorch" "Container Image (Python 3.11/3.12, CUDA 12.6.3, UBI9)" "workbench"
            jupyterTF = container "Jupyter TensorFlow" "CUDA-accelerated JupyterLab with TensorFlow" "Container Image (Python 3.11/3.12, CUDA 12.6.3, UBI9)" "workbench"
            jupyterTrustyAI = container "Jupyter TrustyAI" "JupyterLab with TrustyAI explainability/fairness (Java 17)" "Container Image (Python 3.11/3.12, UBI9)" "workbench"
            codeserver = container "CodeServer" "VS Code in browser with NGINX proxy and supervisord" "Container Image (Python 3.11/3.12, UBI9)" "workbench"
            rstudio = container "RStudio Server" "RStudio Server (R 4.4.3) with NGINX proxy and supervisord" "Container Image (Python 3.11, C9S/RHEL9)" "workbench"
            runtimeImages = container "Runtime Images" "Elyra pipeline runtimes (Minimal, DS, PyTorch, TF, ROCm variants)" "Container Images (6 variants)" "runtime"
            buildTooling = container "Build Tooling" "buildinputs (Go) + sandbox.py for Dockerfile analysis and build isolation" "Go CLI + Python Script" "tooling"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions with digest-pinned references and metadata annotations" "Kubernetes Manifests" "manifest"
        }

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Launches workbench pods from ImageStream references, injects kube-rbac-proxy sidecar" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Reads ImageStream annotations to display workbench selection UI" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "OAuth/RBAC auth sidecar injected into workbench pods" "Internal RHOAI"
        elyra = softwareSystem "Elyra" "Pipeline editor and runtime, bundled in DS/ML workbench images" "Internal RHOAI"
        konflux = softwareSystem "Konflux / AppStudio" "Tekton pipelines for multi-arch builds and SBOM generation" "Internal Red Hat"

        openshiftPlatform = softwareSystem "OpenShift Platform" "Container orchestration with OAuth, routing, and ImageStreams" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image registry (quay.io/modh/*, quay.io/opendatahub/*)" "External"
        githubActions = softwareSystem "GitHub Actions" "CI/CD pipeline for building and testing images" "External"
        redhatRegistries = softwareSystem "Red Hat Registries" "UBI9/RHEL9 base images (registry.access.redhat.com)" "External"
        pypi = softwareSystem "PyPI" "Python package index for dependency installation" "External"
        nvidiaRepos = softwareSystem "NVIDIA Repos" "CUDA toolkit, cuDNN, NCCL packages" "External"
        amdRepos = softwareSystem "AMD ROCm Repos" "ROCm GPU acceleration packages" "External"

        datascientist -> odhDashboard "Selects workbench type" "HTTPS/443"
        datascientist -> notebooksDownstream "Uses workbench" "HTTPS/443 via OpenShift ingress"
        mlEngineer -> notebooksDownstream "Runs pipeline runtimes" "via Elyra"

        odhNotebookController -> notebooksDownstream "Launches pods from ImageStreams" "Kubernetes API"
        odhDashboard -> kustomizeManifests "Reads ImageStream annotations" "Kubernetes API"
        kubeRBACProxy -> notebooksDownstream "Auth sidecar in workbench pods" "HTTP/8888, HTTP/8787"

        notebooksDownstream -> openshiftPlatform "Runs on, uses ServiceAccount, ImageStreams" "HTTPS/443"

        githubActions -> notebooksDownstream "Builds container images" "Docker/Podman"
        konflux -> notebooksDownstream "Multi-arch container builds" "Tekton"

        notebooksDownstream -> quayRegistry "Publishes built images" "HTTPS/443"
        notebooksDownstream -> redhatRegistries "Pulls UBI9 base images" "HTTPS/443"
        notebooksDownstream -> pypi "Installs Python packages" "HTTPS/443"
        notebooksDownstream -> nvidiaRepos "Downloads CUDA toolkit" "HTTPS/443"
        notebooksDownstream -> amdRepos "Downloads ROCm packages" "HTTPS/443"

        jupyterMinimal -> jupyterDS "base layer for"
        jupyterMinimal -> jupyterPyTorch "base layer for"
        jupyterMinimal -> jupyterTF "base layer for"
        jupyterMinimal -> jupyterTrustyAI "base layer for"
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
            element "Internal Red Hat" {
                background #cc0000
                color #ffffff
            }
            element "workbench" {
                background #4a90e2
                color #ffffff
            }
            element "runtime" {
                background #f5a623
                color #ffffff
            }
            element "tooling" {
                background #9b59b6
                color #ffffff
            }
            element "manifest" {
                background #34495e
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
