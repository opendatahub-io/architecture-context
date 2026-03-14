workspace {
    model {
        dataScientist = person "Data Scientist" "Develops and trains ML models using interactive workbenches"
        mlEngineer = person "ML Engineer" "Builds and executes ML pipelines using runtime images"

        notebooks = softwareSystem "Workbench Notebooks" "Pre-configured container images for data science and ML workflows" {
            baseImages = container "Base Images" "Foundation images with Python runtime and dependencies" "Container Images (CPU, CUDA, ROCm)"
            workbenchImages = container "Workbench Images" "Interactive development environments" "Jupyter, CodeServer, RStudio"
            runtimeImages = container "Runtime Images" "Lightweight pipeline execution images" "Python + ML Frameworks"
            kustomizeManifests = container "Kustomize Manifests" "Kubernetes deployment configurations" "YAML"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Manages notebook workbench lifecycle" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for managing workbenches" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "ML pipeline orchestration platform" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model versioning and metadata storage" "Internal ODH"

        jupyterLab = softwareSystem "JupyterLab" "Interactive notebook IDE" "External"
        vsCode = softwareSystem "VS Code Server" "Web-based IDE" "External"
        rstudio = softwareSystem "RStudio Server" "R development IDE" "External"

        pypi = softwareSystem "PyPI" "Python package repository" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for datasets and model artifacts" "External"
        git = softwareSystem "Git Repositories" "Source code version control" "External"
        quay = softwareSystem "Quay.io" "Container image registry" "External"

        pytorch = softwareSystem "PyTorch" "Deep learning framework" "External"
        tensorflow = softwareSystem "TensorFlow" "Machine learning framework" "External"
        cuda = softwareSystem "CUDA Toolkit" "NVIDIA GPU acceleration" "External"
        rocm = softwareSystem "ROCm" "AMD GPU acceleration" "External"

        # User interactions
        dataScientist -> dashboard "Creates and manages notebook instances via web UI"
        dataScientist -> notebooks "Develops models in Jupyter/VSCode/RStudio workbenches"
        mlEngineer -> dsp "Builds ML pipelines that use runtime images"

        # Component relationships
        dashboard -> notebookController "Requests notebook creation and lifecycle operations"
        notebookController -> notebooks "Launches workbench StatefulSets with image references"

        notebooks -> jupyterLab "Includes as IDE for interactive development"
        notebooks -> vsCode "Includes as web-based IDE option"
        notebooks -> rstudio "Includes for R development workflows"

        notebooks -> pytorch "Includes ML framework in PyTorch images"
        notebooks -> tensorflow "Includes ML framework in TensorFlow images"
        notebooks -> cuda "Includes GPU support in CUDA images"
        notebooks -> rocm "Includes GPU support in ROCm images"

        notebooks -> pypi "Installs Python packages at runtime" "HTTPS/443"
        notebooks -> s3 "Accesses training datasets and model artifacts" "HTTPS/443"
        notebooks -> git "Clones code repositories" "HTTPS/443"
        notebooks -> modelRegistry "Registers trained models" "HTTP/8080"
        notebooks -> quay "Pulls container images" "HTTPS/443"

        dsp -> notebooks "Executes pipeline steps using runtime images"

        # Internal container relationships
        baseImages -> workbenchImages "Provides foundation for workbench builds"
        baseImages -> runtimeImages "Provides foundation for runtime builds"
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
                color #000000
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }

        theme default
    }
}
