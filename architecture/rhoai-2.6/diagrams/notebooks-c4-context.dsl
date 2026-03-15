workspace {
    model {
        user = person "Data Scientist" "Creates and deploys ML models using interactive notebook environments"

        notebookImages = softwareSystem "Notebook Images" "Pre-built container images for Jupyter notebooks and IDE environments optimized for data science and machine learning workloads" {
            baseImages = container "Base Images" "Foundation images with Python 3.8/3.9 on UBI8/UBI9/C9S" "Container Images"
            jupyterNotebooks = container "Jupyter Notebooks" "JupyterLab environments with varying ML library stacks" "Container Images"
            cudaImages = container "CUDA GPU Images" "GPU-accelerated notebook images with NVIDIA CUDA 11.8 and cuDNN 8.9" "Container Images"
            habanaImages = container "Habana AI Images" "Notebooks optimized for Habana AI accelerators" "Container Images"
            runtimeImages = container "Runtime Images" "Python environments without Jupyter for pipeline execution" "Container Images"
            ideImages = container "IDE Images" "Alternative IDEs: code-server (VS Code) and RStudio" "Container Images"
        }

        # External Dependencies
        ubi = softwareSystem "Red Hat UBI" "Universal Base Images for container foundations" "External"
        nvidiaCuda = softwareSystem "NVIDIA CUDA/cuDNN" "GPU acceleration libraries and deep learning primitives" "External"
        jupyterLab = softwareSystem "JupyterLab" "Interactive notebook interface" "External"
        pypi = softwareSystem "PyPI" "Python package repository for runtime installations" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image registry (quay.io/modh/*)" "External"

        # Internal RHOAI Dependencies
        notebookController = softwareSystem "Notebook Controller" "RHOAI component that spawns notebook pods as StatefulSets" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Tekton-based pipeline execution platform" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing data science workbenches" "Internal RHOAI"
        imageStreams = softwareSystem "OpenShift ImageStreams" "Image distribution and versioning mechanism" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifacts" "Internal RHOAI"

        # External Services
        s3Storage = softwareSystem "S3 Storage" "Object storage for datasets and model artifacts (AWS S3 or MinIO)" "External Service"
        databases = softwareSystem "Databases" "MongoDB, PostgreSQL, MS SQL Server for data access" "External Service"

        # Relationships - User Interactions
        user -> notebookImages "Develops ML models using notebook environments"
        user -> dashboard "Selects notebook image and creates workbench"

        # Relationships - Build Dependencies
        ubi -> notebookImages "Provides base container images" "registry.access.redhat.com"
        nvidiaCuda -> notebookImages "Provides GPU acceleration libraries for CUDA variants" "CUDA 11.8, cuDNN 8.9"
        jupyterLab -> notebookImages "Installed in Jupyter notebook images" "JupyterLab 3.2-3.6"

        # Relationships - Runtime Dependencies
        notebookImages -> pypi "Downloads Python packages at runtime" "HTTPS/443"
        notebookImages -> s3Storage "Reads/writes datasets and models" "HTTPS/443, boto3, AWS Signature v4"
        notebookImages -> databases "Connects to databases for data access" "Various protocols"
        notebookImages -> modelRegistry "Registers trained models" "HTTP/8080"
        notebookImages -> dsPipelines "Submits pipelines via Elyra" "HTTP/8888, kfp-tekton"

        # Relationships - Distribution
        notebookImages -> quayRegistry "Published to container registry" "HTTPS/443, Robot Account"
        quayRegistry -> imageStreams "Images imported into OpenShift" "HTTPS/443, Pull Secret"
        imageStreams -> notebookController "References images for pod creation" "Kubernetes API"
        imageStreams -> dashboard "Displays available notebook types" "ImageStream annotations"

        # Relationships - Execution
        notebookController -> notebookImages "Spawns as StatefulSets in user namespaces" "Kubernetes API"
        dsPipelines -> notebookImages "Executes runtime images in Tekton steps" "Container execution"
    }

    views {
        systemContext notebookImages "NotebookImagesContext" {
            include *
            autoLayout
        }

        container notebookImages "NotebookImagesContainers" {
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
                color #000000
            }
            element "External Service" {
                background #f5a623
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6c8ebf
                color #ffffff
            }
        }
    }
}
