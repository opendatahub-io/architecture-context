workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML workloads in workbench environments"
        mlEngineer = person "ML Engineer" "Builds and runs ML pipelines using Elyra"

        notebooksRepo = softwareSystem "notebooks-downstream-z-test" "Downstream z-stream build repo producing workbench and pipeline runtime container images for RHOAI" {
            jupyterMinimal = container "jupyter-minimal" "Minimal JupyterLab workbench with base Python 3.12 on UBI9" "Container Image"
            jupyterDatascience = container "jupyter-datascience" "JupyterLab with data science libraries, Elyra, database connectors" "Container Image"
            jupyterPytorch = container "jupyter-pytorch" "JupyterLab with PyTorch and CUDA for GPU deep learning" "Container Image"
            jupyterPytorchLLM = container "jupyter-pytorch+llmcompressor" "JupyterLab with PyTorch, vLLM, and LLM Compressor" "Container Image"
            jupyterTensorflow = container "jupyter-tensorflow" "JupyterLab with TensorFlow and CUDA" "Container Image"
            jupyterTrustyAI = container "jupyter-trustyai" "JupyterLab with TrustyAI for AI fairness/explainability" "Container Image"
            codeserverDS = container "codeserver-datascience" "VS Code in browser via code-server with NGINX proxy" "Container Image"
            runtimeMinimal = container "runtime-minimal" "Headless pipeline runtime with Elyra bootstrapper" "Container Image"
            runtimeDatascience = container "runtime-datascience" "Headless pipeline runtime with data science libraries" "Container Image"
            runtimePytorch = container "runtime-pytorch" "Headless pipeline runtime with PyTorch and CUDA" "Container Image"
            kustomizeManifests = container "Kustomize Manifests" "ImageStream definitions with parameterized image references" "Kubernetes Manifests"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Deploys workbench images as per-user StatefulSets, injects OAuth proxy sidecar" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Presents versioned workbench selections to users via ImageStream annotations" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Executes pipeline steps using runtime container images" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for data access and pipeline artifacts" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code management accessed from workbench" "External"
        ubi9 = softwareSystem "UBI 9 Base Images" "Red Hat Universal Base Image providing FIPS-capable OpenSSL" "External"
        odhBaseImages = softwareSystem "ODH Base Images" "Community base images with CUDA/ROCm accelerator support" "External"
        pypi = softwareSystem "PyPI" "Python package registry for dependency installation at build time" "External"

        dataScientist -> notebooksRepo "Uses workbench images for interactive ML work"
        mlEngineer -> notebooksRepo "Uses pipeline runtime images for automated ML pipelines"

        notebookController -> notebooksRepo "Pulls and deploys workbench container images"
        dashboard -> kustomizeManifests "Reads ImageStream annotations for workbench selection UI"
        kubeflowPipelines -> runtimeMinimal "Executes pipeline steps in runtime containers"
        kubeflowPipelines -> runtimeDatascience "Executes pipeline steps in runtime containers"
        kubeflowPipelines -> runtimePytorch "Executes pipeline steps in runtime containers"

        notebooksRepo -> ubi9 "Uses as CPU base image" "Container Build"
        notebooksRepo -> odhBaseImages "Uses as CUDA/ROCm base image" "Container Build"
        notebooksRepo -> pypi "Downloads Python packages with hash verification" "HTTPS/443"
        jupyterDatascience -> s3Storage "Accesses data via boto3" "HTTPS/443"
        runtimeMinimal -> s3Storage "Downloads/uploads pipeline artifacts" "HTTPS/443"
        jupyterMinimal -> gitRepos "Clones/pushes source code" "HTTPS/443"
    }

    views {
        systemContext notebooksRepo "SystemContext" {
            include *
            autoLayout
        }

        container notebooksRepo "Containers" {
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
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
            element "Kubernetes Manifests" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
