workspace "kubeflow-sdk" "C4 context for the Kubeflow SDK (RHOAI 3.7-ea.1)" {
    model {
        user = person "Data Scientist" "Submits training, optimization, Spark and pipeline work from notebooks or scripts"

        sdk = softwareSystem "Kubeflow SDK" "Unified Python client library (pip: kubeflow 0.5.0). Runs in the caller's process; deploys no workload." {
            trainer = container "kubeflow.trainer" "TrainerClient: lists runtimes and manages TrainJob CRs. Backends: Kubernetes, Docker/Podman, local process." "Python"
            rhai = container "kubeflow.trainer.rhai" "Midstream RHAI trainers (Transformers, TrainingHub, SpeculativeDecoding); generate instrumented training scripts" "Python"
            optimizer = container "kubeflow.optimizer" "OptimizerClient: Katib Experiments and Trials" "Python"
            spark = container "kubeflow.spark" "SparkClient: SparkConnect sessions, SparkApplications, Spark Connect gRPC" "Python"
            hub = container "kubeflow.hub" "ModelRegistryClient: register models and upload artifacts" "Python"
            pipelines = container "kubeflow.pipelines" "Re-export of kfp PipelinesClient" "Python"
            common = container "kubeflow.common" "Backend config, namespace discovery, structlog" "Python"
            instrumentation = container "Injected training-pod instrumentation" "Generated code in TrainJob pods: metrics HTTP server :28080, status reporter, checkpoint helpers" "Python (generated)"
        }

        k8s = softwareSystem "Kubernetes API Server" "CR CRUD, logs, events, Secret/ConfigMap reads; enforces caller RBAC" "External"
        trainerCtl = softwareSystem "Kubeflow Trainer" "Reconciles TrainJobs, polls progress metrics, receives status updates" "Internal RHOAI"
        katib = softwareSystem "Katib" "Hyperparameter optimization (not yet shipped in RHOAI)" "Internal RHOAI"
        sparkOp = softwareSystem "Spark Operator" "Reconciles SparkConnect and SparkApplication; runs Spark Connect server" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model and version metadata" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "KFP pipeline execution" "Internal RHOAI"
        trainingImage = softwareSystem "Universal Training Image / Training Hub" "Runtime image that executes generated training scripts" "Internal RHOAI"
        workbench = softwareSystem "Workbenches" "Notebook images where the SDK is installed and run" "Internal RHOAI"
        dashboard = softwareSystem "Dashboard Data Connections" "S3 credential Secrets" "Internal RHOAI"
        s3 = softwareSystem "S3-compatible Storage" "Checkpoints, outputs, model artifacts" "External"
        pypi = softwareSystem "PyPI" "Default runtime pip index (pypi.org/simple)" "External"
        hf = softwareSystem "HuggingFace Hub" "Model and dataset downloads" "External"
        upstream = softwareSystem "kubeflow/sdk (upstream)" "Upstream SDK synced daily into the midstream fork" "External"

        user -> sdk "Calls Python API from" "Python"
        user -> workbench "Works in"
        workbench -> sdk "Packages"

        trainer -> k8s "Creates/watches TrainJobs, lists runtimes" "HTTPS/6443, Bearer"
        rhai -> trainer "Supplies generated scripts to"
        rhai -> k8s "Reads Data Connection Secret keys" "HTTPS/6443"
        optimizer -> k8s "Creates Experiments, lists Trials" "HTTPS/6443"
        spark -> k8s "Creates SparkConnect / SparkApplication; port-forward" "HTTPS/6443"
        spark -> sparkOp "Connects to Spark Connect server" "gRPC/15002 plaintext"
        hub -> modelRegistry "Registers models" "HTTPS/443, Bearer user_token"
        hub -> s3 "Uploads model artifacts" "HTTPS/443, S3 keys"
        pipelines -> dsp "Submits pipelines" "HTTPS, Bearer"
        trainer -> common "Uses"
        optimizer -> common "Uses"
        spark -> common "Uses"

        trainerCtl -> instrumentation "Polls progress metrics" "HTTP/28080, no auth"
        instrumentation -> trainerCtl "Posts TrainJob status" "HTTPS, projected SA token"
        instrumentation -> s3 "Writes checkpoints/outputs" "HTTPS/443, S3 keys"
        instrumentation -> pypi "pip install at runtime" "HTTPS/443"
        instrumentation -> hf "Downloads models/datasets" "HTTPS/443, HF_TOKEN"
        trainingImage -> instrumentation "Executes"

        k8s -> trainerCtl "TrainJob events"
        k8s -> katib "Experiment events"
        k8s -> sparkOp "SparkConnect/SparkApplication events"
        sdk -> dashboard "References Data Connection Secrets"
        upstream -> sdk "Daily merge sync"
    }

    views {
        systemContext sdk "SystemContext" {
            include *
            autoLayout
        }

        container sdk "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
