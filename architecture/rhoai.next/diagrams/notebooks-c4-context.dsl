workspace {
    model {
        dataScientist = person "Data Scientist" "Creates workbenches and runs ML experiments in JupyterLab, Code-Server, or RStudio"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, deploys workbench ImageStreams"

        notebooks = softwareSystem "Notebooks (Workbench & Runtime Images)" "Container image factory producing ~20 workbench and pipeline runtime images for RHOAI" {
            jupyterMinimal = container "jupyter/minimal" "Base JupyterLab with Python 3.12" "Container Image (UBI9)"
            jupyterDatascience = container "jupyter/datascience" "Data science workbench with ML libraries, DB connectors, Elyra" "Container Image (UBI9)"
            jupyterPytorch = container "jupyter/pytorch" "PyTorch + CUDA GPU workbench" "Container Image (UBI9+CUDA)"
            jupyterTensorflow = container "jupyter/tensorflow" "TensorFlow + CUDA GPU workbench" "Container Image (UBI9+CUDA)"
            jupyterTrustyai = container "jupyter/trustyai" "AI explainability workbench with Java 17" "Container Image (UBI9)"
            codeserver = container "Code-Server" "VS Code in the browser with nginx proxy + idle culling CGI" "Container Image (UBI9)"
            rstudio = container "RStudio" "RStudio Server with R 4.5.1, nginx proxy + idle culling CGI" "Container Image (UBI9)"
            runtimes = container "Pipeline Runtimes" "Lightweight execution environments for Elyra pipeline steps" "Container Image (UBI9)"
            manifests = container "Kustomize Manifests" "ImageStream definitions with 114 replacement rules, sha256-pinned" "YAML/Kustomize"
            idleCulling = container "Idle Culling Stack" "nginx + httpd CGI emulating /api/kernels/ for non-Jupyter workbenches" "nginx + httpd + bash CGI"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Deploys workbench ImageStreams to cluster from kustomize manifests" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "UI for data scientists to select and create workbenches" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Notebook CR lifecycle, injects kube-rbac-proxy sidecar" "Internal RHOAI"
        notebookCuller = softwareSystem "Notebook Controller Culler" "Polls /api/kernels/ to detect and cull idle workbenches" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Pipeline execution platform for ML workflows" "Internal RHOAI"
        konflux = softwareSystem "Konflux CI" "Hermetic build pipeline with cachi2 dependency prefetch" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io - stores published workbench images" "External"
        pypi = softwareSystem "PyPI / CRAN" "Python and R package repositories" "External"
        databases = softwareSystem "User Databases" "PostgreSQL, MySQL, MongoDB data sources" "External"
        s3 = softwareSystem "Object Storage" "S3-compatible storage for datasets and models" "External"

        # Relationships
        dataScientist -> odhDashboard "Selects workbench type via UI"
        dataScientist -> notebooks "Uses workbench for ML development" "HTTPS/8443 via kube-rbac-proxy"
        platformAdmin -> rhodsOperator "Deploys RHOAI platform"

        odhDashboard -> notebooks "Reads ImageStream annotations to populate workbench selection" "HTTPS/6443"
        notebookController -> notebooks "Creates workbench pods, injects sidecars, resolves images" "Kubernetes API"
        notebookCuller -> notebooks "Polls /api/kernels/ for idle detection" "HTTPS/8443"
        rhodsOperator -> notebooks "Deploys ImageStream manifests" "Kubernetes API"
        dsp -> notebooks "Runs pipeline steps using runtime images" "Pod creation"

        notebooks -> dsp "Submits pipelines via Elyra" "HTTP/8888"
        notebooks -> pypi "Installs packages at runtime" "HTTPS/443"
        notebooks -> databases "User-configured data connections" "TCP/5432,3306,27017"
        notebooks -> s3 "Reads/writes datasets and models" "HTTPS/443"

        konflux -> notebooks "Builds container images hermetically" "CI/CD"
        konflux -> containerRegistry "Pushes built images" "HTTPS/443"
        containerRegistry -> notebooks "Provides images via ImageStream pull" "HTTPS/443"

        # Internal container relationships
        jupyterMinimal -> jupyterDatascience "Base image for" "Dockerfile FROM"
        jupyterDatascience -> jupyterPytorch "Base image for" "Dockerfile FROM"
        jupyterDatascience -> jupyterTensorflow "Base image for" "Dockerfile FROM"
        jupyterDatascience -> jupyterTrustyai "Base image for" "Dockerfile FROM"
        codeserver -> idleCulling "Uses for Jupyter API emulation"
        rstudio -> idleCulling "Uses for Jupyter API emulation"
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
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
