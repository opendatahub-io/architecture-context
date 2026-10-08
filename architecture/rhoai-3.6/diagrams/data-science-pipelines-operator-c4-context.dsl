workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipelines via DSPA custom resources"
        platformAdmin = person "Platform Admin" "Configures operator and manages AIPipelines module"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines v2 stacks on OpenShift via DSPA custom resources" {
            dspaReconciler = container "DSPAReconciler" "Reconciles DSPA CRs, deploys per-namespace pipeline stacks" "Go controller-runtime"
            aiPipelinesReconciler = container "AIPipelinesReconciler" "Reconciles cluster-scoped AIPipelines resources for platform module coordination" "Go controller-runtime"
            aiPipelinesArgoReconciler = container "AIPipelinesArgoReconciler" "Manages Argo Workflows controller lifecycle under AIPipelines module ownership" "Go controller-runtime"
            webhookServer = container "Webhook Server" "Validates PipelineVersion CRs, enforces OCI registry allowlist" "Go admission webhook" "9443/TCP"
            securityProfileWatcher = container "SecurityProfileWatcher" "Watches OpenShift TLS profiles, triggers graceful restart on changes" "Go watcher"
            templateEngine = container "Template Engine" "Renders Go templates via manifestival for Kubernetes manifests" "manifestival"
        }

        pipelineStack = softwareSystem "Per-Namespace Pipeline Stack" "Complete Kubeflow Pipelines v2 stack deployed per DSPA" {
            apiServer = container "API Server" "Pipeline API endpoint" "Python/Go"
            persistenceAgent = container "Persistence Agent" "Persists pipeline run metadata" "Go"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages recurring pipeline runs" "Go"
            argoController = container "Argo Workflow Controller" "Executes pipeline workflows" "Go"
            mlmdServer = container "MLMD Server" "ML Metadata storage with Envoy proxy" "C++/Go"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster control plane for all resource operations" "External"
        openshiftPlatform = softwareSystem "OpenShift Platform" "Provides Routes, Image Streams, TLS profiles" "External"
        mariadb = softwareSystem "MariaDB" "Pipeline metadata database (per-DSPA namespace)" "External"
        s3Store = softwareSystem "S3-Compatible Object Store" "Pipeline artifact storage (MinIO or external S3)" "External"

        kserve = softwareSystem "KServe" "Serverless ML inference platform" "Internal ODH"
        mlflow = softwareSystem "MLflow" "ML experiment tracking" "Internal ODH"
        prometheus = softwareSystem "Prometheus" "Metrics and monitoring" "Internal ODH"
        codeflare = softwareSystem "CodeFlare" "Distributed compute workload management" "Internal ODH"
        ray = softwareSystem "Ray" "Distributed computing framework" "Internal ODH"

        dataScientist -> dspo "Creates DSPA custom resources" "kubectl / YAML"
        platformAdmin -> dspo "Configures AIPipelines module and operator settings" "kubectl / YAML"

        dspaReconciler -> kubernetesAPI "CRUD on managed resources" "HTTPS/6443"
        dspaReconciler -> mariadb "Database health checks" "MySQL/3306"
        dspaReconciler -> s3Store "Object store health checks" "HTTPS/443"
        dspaReconciler -> templateEngine "Renders deployment manifests" "In-process"
        dspaReconciler -> pipelineStack "Deploys complete pipeline stack" "via Kubernetes API"

        securityProfileWatcher -> openshiftPlatform "Watches TLS profile changes" "HTTPS/6443"

        dspo -> kserve "Creates InferenceService for model serving" "CRD CRUD via HTTPS/6443"
        dspo -> mlflow "Detects MLflow instances for API server plugin" "CRD Watch via HTTPS/6443"
        dspo -> prometheus "Creates ServiceMonitors and PrometheusRules" "CRD CRUD via HTTPS/6443"
        dspo -> codeflare "Creates AppWrapper resources for distributed workloads" "CRD CRUD via HTTPS/6443"
        dspo -> ray "Creates RayClusters, RayJobs, RayServices" "CRD CRUD via HTTPS/6443"
        dspo -> openshiftPlatform "Creates Routes for pipeline API access" "CRD CRUD via HTTPS/6443"
    }

    views {
        systemContext dspo "SystemContext" {
            include *
            autoLayout
        }

        container dspo "Containers" {
            include *
            autoLayout
        }

        container pipelineStack "PipelineStack" {
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
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
