workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and submits distributed training workloads"
        mlEngineer = person "ML Engineer" "Builds and maintains training pipelines"

        distributedWorkloads = softwareSystem "Distributed Workloads" "Pre-built container images, example workloads, and benchmarks for distributed ML training on RHOAI" {
            runtimeImages = container "Runtime Container Images" "CUDA 13.0, ROCm 6.4, CPU universal images with PyTorch, DeepSpeed, Transformers" "Container Images"
            trainingBenchmarks = container "Training Benchmarks" "MPI+DDP supervised fine-tuning via Kubeflow TrainJob" "Python"
            hpoExamples = container "HPO Examples" "Hyperparameter optimization using RayTune" "Python"
            goTestHarness = container "Go Test Harness" "Integration tests for distributed training infrastructure" "Go 1.25"
        }

        minio = softwareSystem "MinIO" "S3-compatible object storage for training data and model artifacts" {
            minioServer = container "MinIO Server" "Object storage with S3 API" "MinIO"
        }

        nfsServer = softwareSystem "NFS Server" "Shared filesystem for training data" "Supporting"

        kubeflowTrainer = softwareSystem "Kubeflow Trainer v2" "Manages distributed training jobs via TrainJob CRD" "Platform"
        trainingOperator = softwareSystem "Kubeflow Training Operator" "Legacy training operator (v1)" "Platform"
        kuberay = softwareSystem "KubeRay" "Manages Ray clusters for distributed computing" "Platform"
        kueue = softwareSystem "Kueue" "Job queueing and resource quota management" "Platform"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model management" "Platform"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata and artifacts" "Platform"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Pre-trained model repository" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "OpenShift/Kubernetes control plane" "External"

        dataScientist -> distributedWorkloads "Submits training jobs using"
        mlEngineer -> distributedWorkloads "Builds runtime images and pipelines"

        distributedWorkloads -> kubeflowTrainer "Submits TrainJob CRs" "kubectl/API"
        distributedWorkloads -> kuberay "Creates RayCluster CRs" "kubectl/API"
        distributedWorkloads -> kueue "Queues workloads for admission" "kubectl/API"
        distributedWorkloads -> minio "Stores/retrieves training data and models" "S3 API/9000"
        distributedWorkloads -> nfsServer "Shares training data" "NFS/2049"
        distributedWorkloads -> mlflow "Logs experiments and metrics"
        distributedWorkloads -> modelRegistry "Registers trained models"
        distributedWorkloads -> huggingfaceHub "Downloads pre-trained models" "HTTPS/443"
        distributedWorkloads -> kubernetesAPI "Manages resources" "HTTPS/6443"

        goTestHarness -> kubeflowTrainer "Tests TrainJob workflows"
        goTestHarness -> trainingOperator "Tests legacy training workflows"
        goTestHarness -> kuberay "Tests RayCluster workflows"
        goTestHarness -> kueue "Tests job queueing"
        goTestHarness -> kubernetesAPI "Creates and monitors test resources" "HTTPS/6443"
    }

    views {
        systemContext distributedWorkloads "SystemContext" {
            include *
            autoLayout
        }

        container distributedWorkloads "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Platform" {
                background #7ed321
                color #ffffff
            }
            element "Supporting" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5b9bd5
                color #ffffff
            }
        }
    }
}
