workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses workbenches for ML development, data exploration, and model training"

        notebooks = softwareSystem "Notebooks (Workbench & Runtime Images)" "Container image factory producing ~20 workbench and runtime images for interactive data science environments" {
            jupyterMinimal = container "jupyter/minimal" "Base JupyterLab workbench with Python 3.12" "Container Image"
            jupyterDatascience = container "jupyter/datascience" "JupyterLab with ML libraries, Elyra, DB connectors" "Container Image"
            jupyterPytorch = container "jupyter/pytorch" "JupyterLab with PyTorch + CUDA" "Container Image"
            jupyterPytorchLLM = container "jupyter/pytorch+llmcompressor" "JupyterLab with LLM quantization" "Container Image"
            jupyterTensorflow = container "jupyter/tensorflow" "JupyterLab with TensorFlow + CUDA" "Container Image"
            jupyterTrustyai = container "jupyter/trustyai" "JupyterLab with AI explainability + Java" "Container Image"
            jupyterRocmPytorch = container "jupyter/rocm/pytorch" "JupyterLab with PyTorch + AMD ROCm" "Container Image"
            jupyterRocmTf = container "jupyter/rocm/tensorflow" "JupyterLab with TensorFlow + AMD ROCm" "Container Image"
            codeserver = container "codeserver" "VS Code in browser (code-server) with nginx + CGI idle culling" "Container Image"
            rstudio = container "rstudio" "RStudio Server with R 4.5, nginx + CGI idle culling" "Container Image"
            runtimes = container "Pipeline Runtimes" "7 runtime images for Elyra pipeline step execution" "Container Images"
            manifests = container "Kustomize Manifests" "ImageStream definitions with 114 replacement rules for RHOAI/ODH" "Kustomize"
            buildinputs = container "buildinputs" "Go CLI that extracts Dockerfile dependencies via LLB for Konflux" "Go CLI"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Deploys workbench ImageStreams to cluster" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "User-facing UI for workbench creation and management" "Internal ODH"
        notebookController = softwareSystem "ODH Notebook Controller" "Manages Notebook CR lifecycle, sidecar injection, image resolution" "Internal ODH"
        notebookCuller = softwareSystem "Notebook Controller Culler" "Detects idle workbenches via /api/kernels/ polling" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "Pipeline orchestration using Elyra-submitted DAGs" "Internal ODH"

        konfluxCI = softwareSystem "Konflux CI" "Hermetic container image build system" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io / quay.io for image storage" "External"
        pypi = softwareSystem "PyPI / Package Registries" "Python and R package repositories" "External"
        databases = softwareSystem "User Databases" "PostgreSQL, MySQL, MongoDB user-configured data sources" "External"
        k8sAPI = softwareSystem "Kubernetes API" "OpenShift API server" "External"

        dataScientist -> odhDashboard "Selects workbench type and creates workbench"
        dataScientist -> notebooks "Uses workbench for ML development" "HTTPS via kube-rbac-proxy"

        konfluxCI -> notebooks "Builds hermetic container images" "cachi2 prefetched deps"
        konfluxCI -> containerRegistry "Pushes built images" "HTTPS/443"

        manifests -> rhodsOperator "Provides ImageStream definitions" "Kustomize"
        rhodsOperator -> k8sAPI "Deploys ImageStreams" "HTTPS/6443"
        odhDashboard -> k8sAPI "Reads ImageStream annotations" "HTTPS/6443"
        notebookController -> k8sAPI "Mutating webhook, resolves images, injects sidecar" "HTTPS/6443"
        notebookCuller -> notebooks "Polls /api/kernels/ for idle detection" "HTTPS/8443"
        notebooks -> dsPipelines "Submits Elyra pipelines" "HTTP/8888"
        dsPipelines -> runtimes "Launches pipeline step pods"
        notebooks -> pypi "User package installation" "HTTPS/443"
        notebooks -> databases "User-configured data connections" "TCP"
        containerRegistry -> notebooks "ImageStream image pull" "HTTPS/443"
        buildinputs -> konfluxCI "Provides minimal build context deps"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Container Image" {
                background #d5e8d4
                color #333333
            }
        }
    }
}
