workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits InstructLab fine-tuning pipelines"

        ilabOnOcp = softwareSystem "ilab-on-ocp" "Orchestrates InstructLab LLM fine-tuning workflow via Kubeflow Pipelines" {
            pipelineCompiler = container "Pipeline Compiler" "Defines and compiles InstructLab pipeline DAGs using KFP SDK" "Python / KFP SDK"
            runtimeImage = container "Runtime Generic Image" "Container image embedding pipeline code, dependencies, and Mixtral tokenizer" "Container / UBI9 Python 3.12"
            sdgComponents = container "SDG Components" "Synthetic data generation using teacher model" "Python"
            trainingComponents = container "Training Components" "Distributed training via PyTorchJob with FSDP" "Python"
            evalComponents = container "Evaluation Components" "MT-Bench and MMLU model evaluation" "Python"
            utilComponents = container "Utility Components" "Model upload, prerequisite checks, OCI operations" "Python"
        }

        dspa = softwareSystem "Data Science Pipelines Application" "Hosts and executes compiled Kubeflow Pipelines" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serves teacher and judge models as InferenceServices" "Internal RHOAI"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Manages distributed PyTorchJob training workloads" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and version information" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster resource management and secret access" "Platform"
        ociRegistry = softwareSystem "OCI Registry" "Stores output Modelcar container images" "External"
        taxonomyRepo = softwareSystem "Taxonomy Git Repository" "Stores InstructLab taxonomy data for SDG" "External"
        objectStorage = softwareSystem "S3 Object Storage" "Stores model artifacts" "External"

        # User interactions
        dataScientist -> ilabOnOcp "Compiles and submits InstructLab pipeline"

        # Core pipeline flow
        ilabOnOcp -> dspa "Uploads compiled pipeline.yaml for execution"
        ilabOnOcp -> kserve "Calls teacher model for SDG, judge model for evaluation" "HTTPS / Bearer token"
        ilabOnOcp -> trainingOperator "Creates and monitors PyTorchJobs for distributed training" "HTTPS / Bearer token"
        ilabOnOcp -> modelRegistry "Registers fine-tuned model versions" "HTTPS/443 / Bearer token"
        ilabOnOcp -> kubernetesAPI "Reads secrets, manages resources, creates training jobs" "HTTPS/443 / Bearer token"
        ilabOnOcp -> ociRegistry "Pushes output Modelcar images via skopeo" "HTTPS/443 / dockerconfigjson"
        ilabOnOcp -> taxonomyRepo "Clones taxonomy data for synthetic data generation" "HTTPS or SSH / Basic auth or SSH key"

        # Internal container relationships
        pipelineCompiler -> sdgComponents "Includes in pipeline definition"
        pipelineCompiler -> trainingComponents "Includes in pipeline definition"
        pipelineCompiler -> evalComponents "Includes in pipeline definition"
        pipelineCompiler -> utilComponents "Includes in pipeline definition"
        runtimeImage -> sdgComponents "Packages for task execution"
        runtimeImage -> utilComponents "Packages for task execution"
    }

    views {
        systemContext ilabOnOcp "SystemContext" {
            include *
            autoLayout
        }

        container ilabOnOcp "Containers" {
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
            element "Platform" {
                background #4a90e2
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
