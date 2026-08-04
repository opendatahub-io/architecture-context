workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines using KFP components"
        mlEngineer = person "ML Engineer" "Builds and maintains pipeline definitions"

        pipelinesComponents = softwareSystem "Pipelines Components" "Reusable KFP pipeline components and managed pipeline init container" {
            initContainer = container "Init Container" "Copies pre-compiled managed pipeline YAMLs to shared volume at pod startup" "Python (UBI9/python-312)" "Init Container"
            componentLibrary = container "KFP Component Library" "Collection of @dsl.component decorated Python functions for pipeline steps" "Python"

            dataProcessing = component "Data Processing Components" "parse_and_chunk, tabular_data_loader, synthetic_data_generation" "Python @dsl.component"
            training = component "Training Components" "AutoML (AutoGluon), AutoRAG template optimization" "Python @dsl.component"
            evaluation = component "Evaluation Components" "lm-eval for model evaluation" "Python @dsl.component"
            deployment = component "Deployment Components" "Model deployment to serving infrastructure" "Python @dsl.component"
            datasetDownload = component "Dataset Download" "Downloads datasets from HuggingFace Hub" "Python @dsl.component"
        }

        kfpServer = softwareSystem "Kubeflow Pipelines Server" "Orchestrates pipeline execution and manages pipeline definitions" "Internal RHOAI"
        k8sApi = softwareSystem "Kubernetes API" "Cluster resource management" "Platform"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for datasets and model artifacts" "External"
        rayCluster = softwareSystem "Ray Cluster" "Distributed compute via CodeFlare SDK" "Internal RHOAI"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public model and dataset repository" "External"

        # Relationships
        dataScientist -> kfpServer "Submits pipeline runs"
        mlEngineer -> pipelinesComponents "Defines pipelines using component library"

        initContainer -> kfpServer "Provides managed pipeline YAMLs via shared volume"
        kfpServer -> componentLibrary "Orchestrates component pod execution"

        dataProcessing -> s3Storage "Downloads/uploads data" "HTTPS/443, boto3, AWS credentials"
        dataProcessing -> rayCluster "Submits distributed parse/chunk jobs" "CodeFlare SDK"
        training -> rayCluster "Submits distributed training jobs" "CodeFlare SDK"
        training -> s3Storage "Uploads trained models" "HTTPS/443, boto3"
        evaluation -> rayCluster "Submits evaluation jobs" "CodeFlare SDK"
        deployment -> k8sApi "Creates/updates serving resources" "HTTPS/443, ServiceAccount"
        datasetDownload -> huggingfaceHub "Downloads datasets" "HTTPS/443, HF_TOKEN"
    }

    views {
        systemContext pipelinesComponents "SystemContext" {
            include *
            autoLayout
        }

        container pipelinesComponents "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
            element "Init Container" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Component" {
                background #85BBF0
                color #000000
            }
        }
    }
}
