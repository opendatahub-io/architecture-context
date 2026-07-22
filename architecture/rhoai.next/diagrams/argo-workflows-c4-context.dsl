workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML pipeline workflows"
        dspOperator = person "DSP Operator" "Deploys and configures Argo Workflows components"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow engine for orchestrating parallel jobs on Kubernetes" {
            workflowController = container "workflow-controller" "Watches Workflow CRDs, creates execution pods, manages workflow lifecycle, handles artifact GC and archiving" "Go Controller (client-go informer pattern)" {
                informers = component "SharedIndexInformers" "Watches 8 resource types with 20-minute resync" "client-go"
                workers = component "Worker Pools" "32 workflow, 4 TTL, 4 cleanup, 8 cron, 8 archiving workers" "Go goroutines"
                leaderElection = component "Leader Election" "Lease-based single-leader coordination" "coordination.k8s.io/leases"
            }
            argoExec = container "argoexec" "Emissary executor injected into workflow pods — wraps user containers, captures output, collects artifacts, reports results" "Go CLI (init + main container)"
        }

        argoServer = softwareSystem "Argo Server" "REST/gRPC API and web UI for Argo Workflows (NOT shipped in RHOAI)" "Not Deployed" {
            tags "Not Deployed"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform, CRD hosting, pod execution" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Artifact storage (MinIO, AWS S3, GCS, Azure Blob)" "External"
        postgresql = softwareSystem "PostgreSQL" "Workflow archiving and node status offloading (optional)" "External"
        mysql = softwareSystem "MySQL" "Workflow archiving and node status offloading (optional)" "External"

        dspOperatorSystem = softwareSystem "Data Science Pipelines Operator" "Deploys and configures workflow-controller and argoexec images" "Internal RHOAI"
        kfpApiServer = softwareSystem "Kubeflow Pipeline API Server" "Creates Workflow CRDs that the controller processes" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection for workflow and controller telemetry" "Internal Platform"

        # Relationships
        dataScientist -> kfpApiServer "Submits ML pipelines"
        kfpApiServer -> argoWorkflows "Creates Workflow CRDs" "HTTPS/443"
        dspOperator -> argoWorkflows "Deploys and configures"
        dspOperatorSystem -> argoWorkflows "Manages deployment lifecycle"

        workflowController -> kubernetes "CRD watches, pod CRUD, configmap/secret reads, event creation, leader election" "HTTPS/443 SA Token"
        workflowController -> postgresql "Archives workflow data" "TCP/5432 SSL"
        workflowController -> mysql "Archives workflow data" "TCP/3306"

        argoExec -> kubernetes "Status updates, TaskResult CRs" "HTTPS/443 SA Token"
        argoExec -> s3Storage "Upload/download artifacts" "HTTPS/443 SecretKeySelector"

        prometheus -> argoWorkflows "Scrapes metrics" "HTTP/9090"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
        }

        container argoWorkflows "Containers" {
            include *
            autoLayout
        }

        component workflowController "ControllerComponents" {
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Not Deployed" {
                background #cccccc
                color #666666
                border dashed
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
        }
    }
}
