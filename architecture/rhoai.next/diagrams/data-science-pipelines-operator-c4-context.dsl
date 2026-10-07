workspace {
    model {
        platformOperator = person "Platform Operator" "Configures and manages DS Pipelines via DSPA CRs"
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines"

        dspo = softwareSystem "Data Science Pipelines Operator" "Kubernetes operator managing lifecycle of Kubeflow Pipelines v2 stacks on OpenShift" {
            dspaController = container "DSPAReconciler" "Reconciles DataSciencePipelinesApplication CRs, deploys per-namespace pipeline stacks" "Go controller-runtime"
            aiPipelinesController = container "AIPipelinesReconciler" "Reconciles cluster-scoped AIPipelines module for platform lifecycle management" "Go controller-runtime"
            aiPipelinesArgoController = container "AIPipelinesArgoReconciler" "Manages Argo Workflows controller assets per AIPipelines CR" "Go controller-runtime"
            securityProfileWatcher = container "SecurityProfileWatcher" "Watches OpenShift TLS profile changes and triggers operator restart" "Go controller-runtime"
            webhookServer = container "Webhook Server" "Validates and mutates PipelineVersion resources" "Go admission webhook, port 9443"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint with RBAC auth" "Go HTTP server, port 8443 HTTPS"
        }

        pipelineStack = softwareSystem "DSPA Pipeline Stack" "Per-namespace Kubeflow Pipelines v2 deployment managed by DSPO" {
            apiServer = container "API Server" "REST/gRPC endpoints for pipeline management" "Go, port 8888/8887"
            persistenceAgent = container "Persistence Agent" "Monitors workflow execution, persists run metadata" "Go"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages cron-triggered pipeline execution" "Go"
            workflowController = container "Argo Workflow Controller" "Orchestrates pipeline steps as Kubernetes pods" "Go"
            mlmd = container "MLMD Server" "Artifact and execution lineage tracking with Envoy proxy" "C++/Go"
            mariadb = container "MariaDB" "Metadata database (optional, default)" "MariaDB"
            minio = container "MinIO" "Object storage for artifacts (optional, default)" "Go"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "OpenShift APIs: Routes, TLS Profile, Image Streams" "External"
        kserve = softwareSystem "KServe" "Model serving via InferenceService CRDs" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed compute via RayCluster/RayJob CRDs" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "Distributed workload scheduling via AppWrappers" "Internal ODH"
        mlflow = softwareSystem "MLflow" "ML experiment tracking (autodetected)" "Internal ODH"
        prometheusOperator = softwareSystem "Prometheus Operator" "Monitoring via ServiceMonitor/PrometheusRule" "External"
        objectStore = softwareSystem "Object Storage" "S3-compatible artifact storage (external)" "External"
        database = softwareSystem "External Database" "MariaDB-compatible metadata storage (external)" "External"
        ociRegistries = softwareSystem "OCI Registries" "Container image and pipeline manifest registries" "External"
        rhoaiOperator = softwareSystem "RHOAI / ODH Operator" "Platform operator managing component lifecycle" "Internal ODH"

        platformOperator -> dspo "Creates DSPA and AIPipelines CRs" "kubectl / RHOAI Dashboard"
        dataScientist -> pipelineStack "Creates and runs ML pipelines" "REST/gRPC API"

        dspo -> kubernetesAPI "Resource lifecycle management" "HTTPS/6443"
        dspo -> openshiftPlatform "Route creation, TLS profile, image streams" "HTTPS/6443"
        dspo -> pipelineStack "Deploys and manages per-namespace" "Kubernetes manifests"
        dspo -> kserve "Creates InferenceService from pipeline tasks" "CRD CRUD"
        dspo -> ray "Creates RayCluster/RayJob from pipeline tasks" "CRD CRUD"
        dspo -> codeflare "Creates AppWrappers for distributed workloads" "CRD CRUD"
        dspo -> mlflow "Autodetects MLflow instances" "CRD Watch"
        dspo -> prometheusOperator "Manages ServiceMonitor/PrometheusRule" "CRD CRUD"
        dspo -> objectStore "Health checks, artifact storage" "HTTPS/443"
        dspo -> database "Health checks, metadata storage" "TCP/3306"
        dspo -> ociRegistries "Fetches managed pipeline manifests" "HTTPS/443"

        rhoaiOperator -> dspo "Manages lifecycle via AIPipelines CR" "Kubernetes API"

        pipelineStack -> objectStore "Stores pipeline artifacts" "HTTPS/443"
        pipelineStack -> database "Stores pipeline metadata" "TCP/3306"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "OperatorContainers" {
            include *
            autoLayout
        }

        container pipelineStack "PipelineStackContainers" {
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
                color #ffffff
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
    }
}
