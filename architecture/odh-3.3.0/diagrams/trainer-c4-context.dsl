workspace {
    model {
        user = person "Data Scientist" "Creates and manages distributed training jobs for LLM fine-tuning"

        trainer = softwareSystem "Kubeflow Trainer v2" "Next-generation Kubernetes-native framework for LLM fine-tuning and distributed training" {
            controller = container "Trainer Controller" "Reconciles TrainJob CRs and manages training workloads" "Go Operator"
            trainjobCtrl = container "TrainJob Controller" "Creates and manages JobSets for distributed training" "Go Reconciler"
            runtimeCtrl = container "TrainingRuntime Controller" "Manages namespace-scoped training runtime templates" "Go Reconciler"
            clusterRuntimeCtrl = container "ClusterTrainingRuntime Controller" "Manages cluster-wide training runtime templates" "Go Reconciler"
            webhook = container "Webhook Server" "Validates and mutates TrainJob resources" "Go Service, HTTPS/9443"
            sdk = container "Kubeflow SDK" "Provides Pythonic interface for job creation and management" "Python Client Library"
        }

        # External Dependencies
        jobset = softwareSystem "JobSet" "Kubernetes JobSet for managing distributed worker pods" "External K8s Operator"
        pytorch = softwareSystem "PyTorch" "PyTorch runtime for distributed training" "External Framework"
        jax = softwareSystem "JAX" "JAX runtime for high-performance training" "External Framework"
        tensorflow = softwareSystem "TensorFlow" "TensorFlow runtime for distributed training" "External Framework"
        huggingface = softwareSystem "HuggingFace Transformers" "LLM fine-tuning library" "External Library"
        deepspeed = softwareSystem "DeepSpeed" "Microsoft DeepSpeed for memory-efficient training" "External Library"
        megatron = softwareSystem "Megatron-LM" "NVIDIA Megatron for large-scale LLM training" "External Library"
        volcano = softwareSystem "Volcano" "Gang scheduling for synchronous distributed training" "External K8s Scheduler"
        kueue = softwareSystem "Kueue" "Job queuing and resource quota management" "External K8s Operator"

        # External Services
        s3 = softwareSystem "S3 Storage" "Object storage for training datasets and model checkpoints" "External Storage"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Repository of pre-trained models" "External Service"
        containerRegistry = softwareSystem "Container Registry" "Container image repository" "External Service"
        pypi = softwareSystem "PyPI" "Python package index" "External Service"

        # Internal ODH Components
        notebooks = softwareSystem "Notebooks" "ODH workbench environments" "Internal ODH"
        pipelines = softwareSystem "Data Science Pipelines" "ML pipeline orchestration" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal ODH"
        k8sAPI = softwareSystem "Kubernetes API" "Kubernetes control plane API" "Infrastructure"

        # User interactions
        user -> trainer "Creates TrainJob via kubectl or SDK"
        user -> sdk "Submits training jobs programmatically"
        user -> notebooks "Develops and tests training jobs"

        # SDK interactions
        sdk -> k8sAPI "Creates TrainJob CRs" "HTTPS/6443, TLS 1.2+, Bearer Token"

        # Controller interactions
        controller -> k8sAPI "Manages TrainJobs, JobSets, PodGroups" "HTTPS/6443, TLS 1.2+, ServiceAccount"
        k8sAPI -> webhook "Validates/mutates TrainJobs" "HTTPS/9443, TLS 1.2+, Webhook cert"

        # External dependencies
        trainer -> jobset "Creates JobSets for distributed workers" "K8s CRD"
        trainer -> volcano "Uses for gang scheduling" "K8s CRD"
        trainer -> kueue "Uses for job queuing" "K8s CRD"

        # Training runtime frameworks
        trainer -> pytorch "Runs PyTorch training jobs" "Runtime"
        trainer -> jax "Runs JAX training jobs" "Runtime"
        trainer -> tensorflow "Runs TensorFlow training jobs" "Runtime"
        trainer -> huggingface "Uses for LLM fine-tuning" "Library"
        trainer -> deepspeed "Uses for memory-efficient training" "Library"
        trainer -> megatron "Uses for large-scale LLM training" "Library"

        # External services
        trainer -> s3 "Reads training data, writes checkpoints" "HTTPS/443, TLS 1.2+, AWS creds"
        trainer -> huggingfaceHub "Downloads pre-trained models" "HTTPS/443, TLS 1.2+, Token"
        trainer -> containerRegistry "Pulls training runtime images" "HTTPS/443, TLS 1.2+, Token"
        trainer -> pypi "Installs Python dependencies" "HTTPS/443, TLS 1.2+"

        # Internal ODH integrations
        notebooks -> trainer "Submits training jobs via SDK" "Python SDK"
        pipelines -> trainer "Executes training jobs as pipeline steps" "K8s CRD"
        trainer -> modelRegistry "Registers fine-tuned models" "HTTP/8080, Bearer Token"
        trainer -> ray "Hybrid workloads combining Ray and Trainer" "Integration"
    }

    views {
        systemContext trainer "SystemContext" {
            include *
            autoLayout
        }

        container trainer "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External K8s Operator" {
                background #999999
                color #ffffff
            }
            element "External Framework" {
                background #cccccc
            }
            element "External Library" {
                background #e8e8e8
            }
            element "External K8s Scheduler" {
                background #999999
                color #ffffff
            }
            element "External Storage" {
                background #f5a623
            }
            element "External Service" {
                background #f5a623
            }
            element "Internal ODH" {
                background #7ed321
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
