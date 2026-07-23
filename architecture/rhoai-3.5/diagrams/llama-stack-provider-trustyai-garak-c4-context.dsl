workspace {
    model {
        mlEngineer = person "ML Engineer / Red Teamer" "Configures and launches LLM vulnerability scans via eval-hub"

        garakProvider = softwareSystem "Garak Provider" "Eval-hub adapter that orchestrates NVIDIA Garak red-teaming scans against LLM endpoints, supporting simple, KFP, and intents execution modes" {
            garakAdapter = container "GarakAdapter" "Orchestrates Garak scans in simple (subprocess) mode with result parsing, OCI persistence, and MLflow logging" "Python eval-hub FrameworkAdapter"
            garakKFPAdapter = container "GarakKFPAdapter" "Subclass that forces KFP execution mode, submitting scans to Kubeflow Pipelines" "Python eval-hub FrameworkAdapter"
            corePackage = container "Core Package" "Framework-agnostic pipeline logic: config resolution, command building, subprocess management, pipeline steps" "Python Module"
            resultUtils = container "Result Utils" "Parses Garak JSONL/AVID reports, calculates TBSA/ASR aggregates, generates ART HTML reports" "Python Module"
            sdgModule = container "SDG Module" "Wraps sdg_hub library for synthetic adversarial prompt generation from harm taxonomies" "Python Module"
            intentsModule = container "Intents Module" "Loads/validates policy taxonomies and pre-generated prompt datasets, generates Garak intent stub files" "Python Module"
        }

        evalHub = softwareSystem "eval-hub Service" "Job lifecycle management, status reporting, result submission" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration platform for ML workflows" "Internal RHOAI"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for scan artifacts and KFP data transfer" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for persisting scan results" "External"
        mlflow = softwareSystem "MLflow Tracking" "Experiment tracking, metric logging, artifact storage" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API for reading Secrets, ConfigMaps" "Infrastructure"

        targetModel = softwareSystem "Target Model Endpoint" "LLM under test (OpenAI-compatible)" "External Model"
        judgeModel = softwareSystem "Judge Model Endpoint" "MulticlassJudge for response evaluation (intents mode)" "External Model"
        attackerModel = softwareSystem "Attacker Model Endpoint" "TAP probe adversarial prompt generation" "External Model"
        evaluatorModel = softwareSystem "Evaluator Model Endpoint" "TAP probe attack success evaluation" "External Model"
        sdgModelEndpoint = softwareSystem "SDG Model Endpoint" "Synthetic data generation for adversarial prompts" "External Model"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and tokenizer downloads" "External"

        # Relationships
        mlEngineer -> evalHub "Launches scans via eval-hub UI/API"
        evalHub -> garakProvider "Creates K8s Job with JobSpec ConfigMap"

        garakAdapter -> corePackage "Delegates pipeline logic"
        garakAdapter -> resultUtils "Parses scan results"
        garakKFPAdapter -> garakAdapter "Extends (subclass)"
        corePackage -> sdgModule "SDG generation"
        corePackage -> intentsModule "Taxonomy handling"

        garakProvider -> targetModel "Garak probes (HTTPS/443, Bearer Token)"
        garakProvider -> judgeModel "Response evaluation (HTTPS/443, Bearer Token)"
        garakProvider -> attackerModel "Adversarial generation (HTTPS/443, Bearer Token)"
        garakProvider -> evaluatorModel "Attack evaluation (HTTPS/443, Bearer Token)"
        garakProvider -> sdgModelEndpoint "Synthetic prompt generation (HTTPS/443, Bearer Token)"
        garakProvider -> evalHub "Status callbacks (localhost HTTP)"
        garakProvider -> kfp "Pipeline submission and polling (HTTPS/8080)"
        garakProvider -> s3 "Artifact upload/download (HTTPS/443, AWS IAM)"
        garakProvider -> ociRegistry "Artifact persistence (HTTPS/443)"
        garakProvider -> mlflow "Metric logging (HTTPS/443, Bearer Token)"
        garakProvider -> k8sAPI "Read Secrets, ConfigMaps (HTTPS/443, mTLS)"
        garakProvider -> huggingFace "Model downloads (HTTPS/443)"
    }

    views {
        systemContext garakProvider "SystemContext" {
            include *
            autoLayout
        }

        container garakProvider "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Model" {
                background #f5a623
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
