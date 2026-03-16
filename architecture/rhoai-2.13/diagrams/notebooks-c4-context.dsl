workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and runs data science workbenches for ML development, analysis, and experimentation"

        notebooks = softwareSystem "Workbench Images (Notebooks)" "Pre-built container images providing Jupyter, VS Code, and RStudio environments with ML frameworks and GPU support" {
            jupyterImages = container "Jupyter Images" "Interactive notebook environments with ML frameworks" "JupyterLab 3.6.7, PyTorch, TensorFlow" {
                jupyterMinimal = component "Jupyter Minimal" "Base notebook environment" "Python 3.9/3.11"
                jupyterDataScience = component "Jupyter DataScience" "Full data science stack" "pandas, numpy, scikit-learn, boto3, Elyra"
                jupyterPyTorch = component "Jupyter PyTorch" "Deep learning with PyTorch" "PyTorch + CUDA/ROCm"
                jupyterTensorFlow = component "Jupyter TensorFlow" "Deep learning with TensorFlow" "TensorFlow + CUDA/ROCm"
            }

            codeServer = container "CodeServer" "VS Code in browser for Python development" "code-server 4.22.0 + NGINX"
            rstudio = container "RStudio Server" "R-based data analysis environment" "R 4.3.3 + tidyverse"
            runtimeImages = container "Runtime Images" "Minimal serving containers for model deployment" "Lightweight Python"
        }

        notebookController = softwareSystem "Notebook Controller" "Manages workbench pod lifecycle from Notebook CRDs" "ODH/RHOAI Platform"
        oauthProxy = softwareSystem "OAuth Proxy" "Provides authentication for workbench access" "OpenShift Security"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for launching and managing workbenches" "ODH/RHOAI Platform"
        kfp = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration and execution" "ODH/RHOAI Platform"
        modelMesh = softwareSystem "Model Mesh" "Model serving platform using runtime images" "ODH/RHOAI Platform"

        pypi = softwareSystem "PyPI" "Python package repository for runtime installation" "External"
        cran = softwareSystem "CRAN" "R package repository for runtime installation" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for datasets and model artifacts" "External"
        git = softwareSystem "Git Repositories" "Source code repositories (GitHub, GitLab)" "External"
        k8sAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes cluster management" "OpenShift"
        imageRegistry = softwareSystem "OpenShift Image Registry" "Container image storage and distribution" "OpenShift"

        # Relationships
        user -> notebooks "Creates workbench instances via ODH Dashboard or kubectl"
        user -> odhDashboard "Launches workbenches through web UI"

        notebooks -> pypi "Installs Python packages at runtime via pip" "HTTPS/443"
        notebooks -> cran "Installs R packages at runtime" "HTTPS/443"
        notebooks -> s3 "Reads/writes datasets and model artifacts via boto3" "HTTPS/443"
        notebooks -> git "Clones repositories via jupyterlab-git" "HTTPS/443 or SSH/22"
        notebooks -> kfp "Submits ML pipeline runs from Elyra extension" "HTTP/8888"
        notebooks -> k8sAPI "Interacts with cluster via oc client" "HTTPS/6443"

        notebookController -> notebooks "Launches workbench pods from images"
        notebookController -> imageRegistry "Pulls images during pod creation" "HTTPS/5000"

        oauthProxy -> notebooks "Provides authentication sidecar for workbench access" "HTTP/8888 localhost"

        odhDashboard -> notebooks "Lists available workbench images from ImageStreams"
        odhDashboard -> notebookController "Creates Notebook CRD instances"

        modelMesh -> notebooks "Uses runtime images as serving containers"
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

        component jupyterImages "JupyterImagesComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH/RHOAI Platform" {
                background #7ed321
                color #000000
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "OpenShift Security" {
                background #cc0000
                color #ffffff
            }
        }

        theme default
    }
}
