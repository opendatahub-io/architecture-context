workspace {
    model {
        dataScientist = person "Data Scientist" "Develops and trains ML models using interactive workbenches"
        mlEngineer = person "ML Engineer" "Deploys and monitors ML pipelines"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Provides containerized workbench environments (Jupyter, RStudio, CodeServer) for data science workflows" {
            jupyterImages = container "Jupyter Workbenches" "JupyterLab-based environments with variants for minimal, data science, PyTorch, TensorFlow, TrustyAI, and LLMCompressor" "Python 3.12, JupyterLab 4.4"
            rstudioImages = container "RStudio Workbenches" "RStudio Server for R-based statistical computing" "R 4.5.1, RStudio 2025.09.0"
            codeserverImages = container "CodeServer Workbenches" "Browser-based VS Code IDE for collaborative development" "Node.js 22.18.0, code-server 4.104.0"
            runtimeImages = container "Runtime Images" "Headless versions for Kubeflow pipeline execution (no UI)" "Python 3.12"
            nginxProxy = container "NGINX Proxy" "Reverse proxy for RStudio and CodeServer web interfaces" "NGINX (UBI9)"
        }

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Manages notebook pod lifecycle and authentication" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for creating and managing workbenches" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Orchestrates ML workflows using runtime images" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores and versions trained models" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Pipeline orchestration for ML workflows" "Internal RHOAI"

        openshift = softwareSystem "OpenShift Platform" "Kubernetes orchestration and OAuth authentication" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for training data and models" "External"
        pypi = softwareSystem "PyPI" "Python package repository" "External"
        cran = softwareSystem "CRAN" "R package repository" "External"
        github = softwareSystem "GitHub" "Source code version control" "External"
        quay = softwareSystem "Quay.io" "Container image registry" "External"
        konflux = softwareSystem "Konflux CI/CD" "Builds, scans, and signs container images" "External"

        # User interactions
        dataScientist -> odhDashboard "Creates workbench via web UI"
        dataScientist -> jupyterImages "Develops models in JupyterLab" "HTTPS/443 via OAuth"
        dataScientist -> rstudioImages "Analyzes data in RStudio" "HTTPS/443 via OAuth"
        dataScientist -> codeserverImages "Writes code in VS Code" "HTTPS/443 via OAuth"
        mlEngineer -> kubeflowPipelines "Deploys ML pipelines"

        # Dashboard to Notebook Controller
        odhDashboard -> odhNotebookController "Discovers available images via ImageStream API" "HTTPS/6443"
        odhDashboard -> openshift "Reads ImageStreams" "HTTPS/6443"

        # Notebook Controller manages workbenches
        odhNotebookController -> notebooks "Creates pod from selected image" "Kubernetes API"
        odhNotebookController -> openshift "Manages Notebook CRD and pods" "HTTPS/6443"

        # Workbench dependencies
        jupyterImages -> pypi "Installs Python packages" "HTTPS/443"
        jupyterImages -> github "Clones/pushes code repositories" "HTTPS/443, SSH/22"
        jupyterImages -> s3Storage "Reads/writes training data and models" "HTTPS/443, AWS IAM"
        jupyterImages -> openshift "Executes oc/kubectl commands" "HTTPS/6443"
        rstudioImages -> cran "Installs R packages" "HTTPS/443"
        rstudioImages -> github "Version control for R scripts" "HTTPS/443"
        rstudioImages -> s3Storage "Stores analysis results" "HTTPS/443"
        codeserverImages -> github "Git operations" "HTTPS/443, SSH/22"
        codeserverImages -> openshift "Kubernetes CLI operations" "HTTPS/6443"

        # Pipeline integration
        kubeflowPipelines -> runtimeImages "Executes pipeline steps using runtime containers" "Kubernetes Pod"
        dsPipelines -> runtimeImages "Orchestrates ML workflows" "Kubernetes Pod"
        runtimeImages -> s3Storage "Loads data and saves models" "HTTPS/443, AWS IAM"
        runtimeImages -> modelRegistry "Registers trained models" "HTTP/8080, mTLS"

        # Build and deployment
        konflux -> notebooks "Builds and signs images" "CI/CD Pipeline"
        konflux -> quay "Pushes signed images to registry" "HTTPS/443"
        openshift -> quay "Pulls workbench images" "HTTPS/443"
        notebooks -> openshift "Deployed as ImageStreams" "Kubernetes API"

        # Authentication
        openshift -> jupyterImages "OAuth proxy provides authentication" "OAuth 2.0"
        openshift -> rstudioImages "OAuth proxy provides authentication" "OAuth 2.0"
        openshift -> codeserverImages "OAuth proxy provides authentication" "OAuth 2.0"
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

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }

        theme default
    }
}
