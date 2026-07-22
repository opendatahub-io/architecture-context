workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs interactive notebooks, trains ML models, builds pipelines"
        mlEngineer = person "ML Engineer" "Deploys pipeline runtime images for automated model training"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and workbench image availability"

        notebooks = softwareSystem "Notebooks" "Container image build repository producing 18 workbench and pipeline runtime images for interactive data science on OpenShift" {
            jupyterWorkbenches = container "Jupyter Workbenches" "10 container image variants (CPU, CUDA, ROCm) with JupyterLab IDE" "Container Images"
            pipelineRuntimes = container "Pipeline Runtimes" "7 container image variants for Elyra notebook pipeline execution" "Container Images"
            codeServerWorkbench = container "Code-Server Workbench" "VS Code in the browser with nginx proxy and httpd CGI for idle culling" "Container Image"
            imageStreamManifests = container "ImageStream Manifests" "Kustomize-managed ImageStream resources for RHOAI and ODH" "Kubernetes Manifests"
            buildSystem = container "Build System" "Makefile, versions_config.yml, lock files for hermetic Konflux builds" "Python/Make"
        }

        aipccBaseImages = softwareSystem "AIPCC Base Images" "RHEL 9.6 container base images with Python 3.12 and accelerator drivers (CPU, CUDA, ROCm)" "External"
        rhaiPyPI = softwareSystem "RHEL AI Python Package Index" "Curated Python wheel repository for AIPCC ecosystem" "External"
        nvidiaRuntime = softwareSystem "NVIDIA CUDA Toolkit" "GPU compute runtime v13.0.2 and v12.9.1" "External"
        amdRuntime = softwareSystem "AMD ROCm Runtime" "GPU compute runtime v7.14 for AMD hardware" "External"

        odhOperator = softwareSystem "ODH/RHOAI Operator" "Deploys ImageStream resources to OpenShift clusters" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and workbenches" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Notebook CR lifecycle, injects sidecars, handles idle culling" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines Application" "Pipeline orchestration backend for Elyra pipeline submission" "Internal RHOAI"
        elyra = softwareSystem "Elyra" "Visual pipeline editor for JupyterLab (ODH fork)" "Internal RHOAI"

        konflux = softwareSystem "Konflux / Tekton" "CI/CD build system for hermetic container image builds" "External"
        cachi2 = softwareSystem "Cachi2 / Hermeto" "Dependency prefetching for fully offline hermetic builds" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io / quay.io for image storage and distribution" "External"

        gitRepos = softwareSystem "Git Repositories" "External source code repositories (GitHub, GitLab)" "External"
        packageRegistries = softwareSystem "Package Registries" "External Python package registries (pypi.org)" "External"

        # Relationships - Users
        dataScientist -> notebooks "Uses workbench images for interactive data science"
        dataScientist -> dspa "Submits pipelines via Elyra"
        mlEngineer -> notebooks "Uses pipeline runtime images in automated workflows"
        platformAdmin -> odhOperator "Manages platform deployment"

        # Relationships - Build chain
        aipccBaseImages -> notebooks "Provides container base layer (SHA256 pinned)" "Container Registry/443"
        rhaiPyPI -> cachi2 "Provides Python wheels for prefetch" "HTTPS/443"
        nvidiaRuntime -> notebooks "Provides CUDA drivers in base images"
        amdRuntime -> notebooks "Provides ROCm drivers in base images"
        konflux -> notebooks "Builds hermetic container images" "Tekton Pipeline"
        cachi2 -> konflux "Provides prefetched dependencies (RPM, pip, npm)"
        notebooks -> containerRegistry "Pushes built images" "HTTPS/443"

        # Relationships - Deployment
        imageStreamManifests -> odhOperator "Provides kustomize manifests for ImageStream deployment" "HTTPS/6443"
        odhOperator -> odhDashboard "ImageStreams discoverable by Dashboard"
        odhDashboard -> notebookController "Triggers Notebook CR creation"

        # Relationships - Runtime
        notebookController -> jupyterWorkbenches "Deploys workbench pods, injects kube-rbac-proxy sidecar"
        notebookController -> codeServerWorkbench "Deploys code-server pods, injects kube-rbac-proxy sidecar"
        notebookController -> pipelineRuntimes "Configures pipeline runtime metadata via ConfigMap"
        jupyterWorkbenches -> dspa "Submits pipeline runs (Elyra)" "HTTPS/443"
        jupyterWorkbenches -> gitRepos "Git clone/pull/push (JupyterLab Git extension)" "HTTPS/443"
        jupyterWorkbenches -> packageRegistries "User-initiated pip installs" "HTTPS/443"
        elyra -> pipelineRuntimes "References runtime images for pipeline execution"
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Container Images" {
                background #4a90e2
                color #ffffff
            }
            element "Container Image" {
                background #9b59b6
                color #ffffff
            }
            element "Kubernetes Manifests" {
                background #f5a623
                color #ffffff
            }
            element "Python/Make" {
                background #e8e8e8
                color #333333
            }
        }
    }
}
