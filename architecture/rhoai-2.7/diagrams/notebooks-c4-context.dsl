workspace {
    model {
        dataScientist = person "Data Scientist" "Creates ML models, performs data analysis, and runs experiments in notebook environments"
        mlEngineer = person "ML Engineer" "Develops ML pipelines, trains models, and deploys inference services"
        admin = person "Platform Administrator" "Manages notebook images, configures resources, and controls access"

        notebooks = softwareSystem "Notebook Workbench Images" "Containerized development environments (Jupyter, code-server, RStudio) for interactive data science and ML workflows" {
            jupyterMinimal = container "Jupyter Minimal" "Basic JupyterLab environment with minimal dependencies" "Python 3.9, JupyterLab 3.6"
            jupyterDataScience = container "Jupyter Data Science" "JupyterLab with ML/AI libraries (pandas, numpy, scikit-learn, matplotlib)" "Python 3.9, JupyterLab 3.6"
            jupyterPyTorch = container "Jupyter PyTorch" "Data Science + PyTorch framework for deep learning" "Python 3.9, PyTorch, CUDA"
            jupyterTensorFlow = container "Jupyter TensorFlow" "Data Science + TensorFlow framework for deep learning" "Python 3.9, TensorFlow, CUDA"
            jupyterTrustyAI = container "Jupyter TrustyAI" "Data Science + TrustyAI explainability libraries" "Python 3.9, TrustyAI"
            codeServer = container "code-server" "VS Code server in browser with Python environment" "code-server 4.16.1, NGINX"
            rstudio = container "RStudio Server" "RStudio IDE for R programming with Python support" "RStudio Server 2023.06.1, R 4.3.1"
            runtimeImages = container "Runtime Images" "Lightweight images for Elyra pipeline execution (no Jupyter UI)" "Python 3.9, Elyra"
        }

        notebookController = softwareSystem "ODH/RHOAI Notebook Controller" "Spawns and manages notebook instances as StatefulSets, handles authentication and authorization" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for selecting and launching notebook workbenches" "Internal ODH"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Stores and versions notebook container images" "OpenShift"
        routes = softwareSystem "OpenShift Routes/Ingress" "Routes external traffic to notebook services via controller proxy" "OpenShift"
        serviceMesh = softwareSystem "Service Mesh (Istio)" "Enforces service-to-service mTLS encryption and authorization policies" "Optional"

        ubi = softwareSystem "Red Hat UBI" "Universal Base Images (UBI8/UBI9) with Python 3.8/3.9" "External"
        pypi = softwareSystem "PyPI" "Python Package Index for runtime package installation" "External"
        s3 = softwareSystem "S3/Object Storage" "Data storage for datasets and model artifacts" "External"
        github = softwareSystem "GitHub" "Version control for notebooks and code" "External"
        databases = softwareSystem "Databases" "PostgreSQL, MySQL, MongoDB for data persistence" "External"
        kafka = softwareSystem "Kafka" "Event streaming platform for real-time data" "External"
        elyra = softwareSystem "Elyra Pipeline Execution" "Visual pipeline editor and execution engine (KFP/Tekton)" "Internal ODH"
        gpuNodeDiscovery = softwareSystem "GPU Node Feature Discovery" "Schedules CUDA notebooks on GPU-enabled nodes" "Kubernetes"

        # User interactions
        dataScientist -> notebooks "Creates and runs notebooks, trains models, analyzes data" "HTTPS/443"
        mlEngineer -> notebooks "Develops ML pipelines, integrates with model serving" "HTTPS/443"
        admin -> imageStreams "Manages image versions and updates" "OpenShift API"

        # Notebook interactions with ODH/RHOAI platform
        notebooks -> notebookController "Orchestrated by (StatefulSet creation)" "Kubernetes API"
        notebookController -> notebooks "Spawns instances, manages lifecycle"
        dashboard -> notebookController "Triggers notebook launches" "HTTP API"
        notebooks -> imageStreams "Pulls container images from" "Container Registry/5000"
        routes -> notebooks "Proxies user traffic to" "HTTP/8888, HTTP/8787"
        serviceMesh -> notebooks "Enforces mTLS and AuthZ" "mTLS"

        # Notebook interactions with external dependencies
        notebooks -> ubi "Built from base images" "Container Registry/443"
        notebooks -> pypi "Installs Python packages from" "HTTPS/443"
        notebooks -> s3 "Reads/writes datasets and models" "HTTPS/443"
        notebooks -> github "Clones repos, pushes code" "HTTPS/443, SSH/22"
        notebooks -> databases "Connects to for data access" "PostgreSQL/5432, MySQL/3306, MongoDB/27017"
        notebooks -> kafka "Streams data from/to" "Kafka/9093"
        notebooks -> elyra "Executes pipelines via runtime images" "KFP/Tekton API"
        gpuNodeDiscovery -> notebooks "Schedules GPU workloads" "Kubernetes API"

        # Internal container relationships
        jupyterMinimal -> jupyterDataScience "Base for"
        jupyterDataScience -> jupyterPyTorch "Base for"
        jupyterDataScience -> jupyterTensorFlow "Base for"
        jupyterDataScience -> jupyterTrustyAI "Base for"
        jupyterDataScience -> runtimeImages "Optimized for pipeline execution"
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
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Optional" {
                background #cccccc
                color #000000
            }
            element "Kubernetes" {
                background #326ce5
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
            element "Person" {
                shape Person
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
