workspace {
    model {
        dataScientist = person "Data Scientist" "Develops and trains ML models using interactive notebooks"
        mlEngineer = person "ML Engineer" "Builds automated ML pipelines for training and deployment"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Provides containerized development environments and pipeline runtimes for data science workflows" {
            workbenches = container "Workbench Images" "Interactive development environments" "JupyterLab 4.4, VS Code, RStudio" {
                jupyterImages = component "Jupyter Images" "JupyterLab notebook environments with ML frameworks" "Python 3.12, PyTorch, TensorFlow, TrustyAI"
                codeserverImages = component "Code Server Images" "VS Code-based development environments" "Python 3.12, code-server"
                rstudioImages = component "RStudio Images" "R-based data science environments" "R 4.x, Python 3.11"
            }

            runtimes = container "Runtime Images" "Lightweight pipeline execution environments" "Python 3.12, ML frameworks" {
                runtimeMinimal = component "Runtime Minimal" "Minimal Python runtime" "Python 3.12"
                runtimeML = component "Runtime ML" "ML framework runtimes" "PyTorch, TensorFlow"
            }

            buildSystem = container "Build Infrastructure" "Multi-architecture image building" "Konflux, Tekton"
        }

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Manages workbench pod lifecycle and OAuth proxy injection" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for creating and managing workbenches" "Internal ODH"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Orchestrates ML pipeline execution using runtime images" "Internal ODH"
        imageStreams = softwareSystem "OpenShift ImageStreams" "References to workbench and runtime container images" "Internal ODH"

        quayRegistry = softwareSystem "Quay.io Registry" "Stores built container images for distribution" "External"
        redhatRegistry = softwareSystem "Red Hat Registry" "Provides UBI9 base images and Python runtimes" "External"
        s3Storage = softwareSystem "S3 Storage" "Stores user data, model artifacts, and pipeline outputs" "External"
        pypi = softwareSystem "PyPI" "Python package repository for installing dependencies" "External"
        konflux = softwareSystem "Konflux CI/CD" "Red Hat's build platform for multi-arch container images" "External"
        github = softwareSystem "GitHub" "Source code repository for notebook images" "External"

        # Relationships - User Interactions
        dataScientist -> odhDashboard "Creates workbenches via web UI"
        mlEngineer -> kubeflowPipelines "Defines pipeline tasks using runtime images"

        # Relationships - Dashboard Flow
        odhDashboard -> imageStreams "Queries available workbench images" "HTTPS/6443"
        odhDashboard -> odhNotebookController "Creates Notebook CR for workbench launch" "Kubernetes API"

        # Relationships - Workbench Lifecycle
        odhNotebookController -> workbenches "Launches pods using workbench images" "Kubernetes API"
        odhNotebookController -> imageStreams "Resolves image references" "Kubernetes API"
        dataScientist -> workbenches "Accesses via browser (OAuth proxy protected)" "HTTPS/443"

        # Relationships - Pipeline Flow
        kubeflowPipelines -> runtimes "Executes tasks in runtime containers" "Kubernetes API"
        runtimes -> s3Storage "Reads/writes pipeline artifacts" "HTTPS/443, AWS SigV4"

        # Relationships - Data Access
        workbenches -> s3Storage "Loads datasets and saves models" "HTTPS/443, S3 Credentials"

        # Relationships - Image Management
        imageStreams -> quayRegistry "Pulls workbench and runtime images" "HTTPS/443"
        workbenches -> quayRegistry "Pulled from registry by Kubelet" "HTTPS/443"
        runtimes -> quayRegistry "Pulled from registry by Kubelet" "HTTPS/443"

        # Relationships - Build Flow
        konflux -> github "Clones source code" "HTTPS/443, Git Token"
        konflux -> redhatRegistry "Pulls UBI9 base images" "HTTPS/443, Pull Secret"
        konflux -> pypi "Installs Python packages during build" "HTTPS/443"
        konflux -> quayRegistry "Pushes built images" "HTTPS/443, Push Secret"
        konflux -> imageStreams "Updates image references" "Kubernetes API, SA Token"
        buildSystem -> konflux "Executed on Konflux platform" "Tekton Pipelines"
    }

    views {
        systemContext notebooks "NotebooksSystemContext" {
            include *
            autoLayout
        }

        container notebooks "NotebooksContainers" {
            include *
            autoLayout
        }

        component workbenches "WorkbenchImages" {
            include *
            autoLayout
        }

        component runtimes "RuntimeImages" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #50e3c2
                color #ffffff
            }
            element "Component" {
                background #bd10e0
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape person
            }
        }
    }
}
