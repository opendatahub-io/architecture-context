workspace {
    model {
        dataScientist = person "Data Scientist" "Develops, trains, and deploys ML models using interactive workbenches"
        mlEngineer = person "ML Engineer" "Creates and executes ML pipelines using runtime images"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Containerized workbench environments for data science workflows" {
            jupyterMinimal = container "Jupyter Minimal" "Minimal JupyterLab environment" "Python 3.12 + JupyterLab 4.4"
            jupyterDataScience = container "Jupyter DataScience" "Comprehensive data science libraries" "Python 3.12 + pandas, numpy, scikit-learn"
            jupyterPyTorch = container "Jupyter PyTorch" "Deep learning workbench" "Python 3.12 + PyTorch 2.x + CUDA/ROCm"
            jupyterTensorFlow = container "Jupyter TensorFlow" "ML model training workbench" "Python 3.12 + TensorFlow 2.16+"
            jupyterTrustyAI = container "Jupyter TrustyAI" "Model explainability workbench" "Python 3.12 + TrustyAI"
            rstudio = container "RStudio Server" "R-based statistical computing IDE" "R 4.5.1 + RStudio 2025.09"
            codeserver = container "CodeServer" "Browser-based VS Code IDE" "VS Code v4.104.0"
            runtimeImages = container "Runtime Images" "Headless pipeline execution containers" "Python 3.12 (no UI)"
            nginxProxy = container "NGINX Proxy" "Reverse proxy for RStudio/CodeServer" "NGINX on UBI9"
            apacheHttpd = container "Apache httpd" "RStudio authentication server" "Apache httpd on UBI9"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Manages workbench pod lifecycle and authentication" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "User interface for RHOAI platform" "Internal ODH"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML workflow orchestration platform" "Internal ODH"
        dataScPipelines = softwareSystem "Data Science Pipelines" "Pipeline execution framework" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Model metadata storage and versioning" "Internal ODH"

        openshift = softwareSystem "OpenShift Platform" "Container orchestration and routing" "External Platform"
        kubernetes = softwareSystem "Kubernetes API" "Cluster resource management" "External Platform"
        oauthProxy = softwareSystem "OAuth Proxy" "OpenShift authentication proxy" "External Platform"

        pypi = softwareSystem "PyPI" "Python package repository" "External Service"
        cran = softwareSystem "CRAN" "R package repository" "External Service"
        github = softwareSystem "GitHub" "Source code version control" "External Service"
        s3 = softwareSystem "S3 Storage" "Object storage for data and models" "External Service"
        quay = softwareSystem "Quay.io" "Container image registry" "External Service"

        # User interactions
        dataScientist -> notebooks "Creates and uses workbenches via ODH Dashboard"
        dataScientist -> jupyterDataScience "Develops models in JupyterLab"
        dataScientist -> rstudio "Performs statistical analysis in R"
        dataScientist -> codeserver "Writes code in VS Code"
        mlEngineer -> kubeflowPipelines "Creates and executes ML pipelines"

        # Notebook component internal
        rstudio -> nginxProxy "Proxied via NGINX"
        rstudio -> apacheHttpd "Authenticated via Apache"
        codeserver -> nginxProxy "Proxied via NGINX"

        # ODH Platform integration
        notebookController -> jupyterMinimal "Creates and manages pods" "Kubernetes API"
        notebookController -> jupyterDataScience "Creates and manages pods" "Kubernetes API"
        notebookController -> jupyterPyTorch "Creates and manages pods" "Kubernetes API"
        notebookController -> jupyterTensorFlow "Creates and manages pods" "Kubernetes API"
        notebookController -> rstudio "Creates and manages pods" "Kubernetes API"
        notebookController -> codeserver "Creates and manages pods" "Kubernetes API"
        notebookController -> oauthProxy "Injects as sidecar" "Kubernetes API"

        odhDashboard -> notebookController "Triggers workbench creation" "Kubernetes API/6443"
        odhDashboard -> openshift "Queries ImageStreams for available images" "Kubernetes API/6443"

        kubeflowPipelines -> runtimeImages "Executes pipeline steps" "Container runtime"
        dataScPipelines -> runtimeImages "Orchestrates ML workflows" "Container runtime"

        # External platform dependencies
        dataScientist -> openshift "Accesses workbench via route" "HTTPS/443"
        openshift -> oauthProxy "Routes traffic through OAuth proxy" "HTTPS/8443"
        oauthProxy -> jupyterDataScience "Forwards authenticated requests" "HTTP/8888"
        oauthProxy -> rstudio "Forwards authenticated requests" "HTTP/8888"
        oauthProxy -> codeserver "Forwards authenticated requests" "HTTP/8888"

        jupyterDataScience -> kubernetes "Executes oc CLI commands" "HTTPS/6443"
        jupyterPyTorch -> kubernetes "Executes oc CLI commands" "HTTPS/6443"

        # External service dependencies
        jupyterMinimal -> pypi "Installs Python packages" "HTTPS/443"
        jupyterDataScience -> pypi "Installs Python packages" "HTTPS/443"
        jupyterPyTorch -> pypi "Installs Python packages" "HTTPS/443"
        jupyterTensorFlow -> pypi "Installs Python packages" "HTTPS/443"

        rstudio -> cran "Installs R packages" "HTTPS/443"

        jupyterDataScience -> github "Clone/push repositories" "HTTPS/443 or SSH/22"
        codeserver -> github "Clone/push repositories" "HTTPS/443 or SSH/22"

        jupyterDataScience -> s3 "Store/retrieve data and models" "HTTPS/443"
        jupyterPyTorch -> s3 "Store/retrieve data and models" "HTTPS/443"
        jupyterTensorFlow -> s3 "Store/retrieve data and models" "HTTPS/443"
        runtimeImages -> s3 "Store/retrieve data and models" "HTTPS/443"

        jupyterDataScience -> modelRegistry "Register trained models" "HTTP/8080"
        jupyterPyTorch -> modelRegistry "Register trained models" "HTTP/8080"
        jupyterTensorFlow -> modelRegistry "Register trained models" "HTTP/8080"
        runtimeImages -> modelRegistry "Register trained models" "HTTP/8080"

        jupyterDataScience -> quay "Pull base and utility images" "HTTPS/443"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "External Platform" {
                background #6c8ebf
                color #ffffff
            }
            element "External Service" {
                background #999999
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
        }

        theme default
    }
}
