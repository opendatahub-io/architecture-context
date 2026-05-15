workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines via Data Science Pipelines"
        platformadmin = person "Platform Admin" "Manages RHOAI deployment and configuration"

        argoWorkflows = softwareSystem "Argo Workflows" "Container-native workflow engine for orchestrating parallel jobs on Kubernetes; execution backend for Data Science Pipelines in RHOAI" {
            workflowController = container "workflow-controller" "Reconciles Workflow CRs, creates/manages Pods for workflow steps, handles cron scheduling, TTL-based GC, artifact GC, and workflow archiving" "Go Operator" {
                tags "FIPS"
            }
            argoexec = container "argoexec" "Executor sidecar injected into workflow step pods; manages artifact download/upload, progress monitoring, container lifecycle, and result reporting" "Go Sidecar Binary" {
                tags "DualBinary"
            }
        }

        dspOperator = softwareSystem "Data Science Pipelines Operator" "Deploys and manages DSP components including workflow-controller" "Internal RHOAI"
        dspAPIServer = softwareSystem "Data Science Pipelines API Server" "Compiles pipelines into Workflow CRs, provides user-facing API" "Internal RHOAI"

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing API server, scheduling, RBAC" "External" {
            tags "External"
        }
        objectStorage = softwareSystem "S3-compatible Storage" "MinIO or AWS S3 for pipeline artifact persistence" "External" {
            tags "External"
        }
        database = softwareSystem "PostgreSQL / MariaDB" "Optional workflow archiving and node status offloading" "External" {
            tags "External"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection from workflow-controller" "External" {
            tags "External"
        }

        # Relationships - User level
        datascientist -> dspAPIServer "Submits pipeline runs via"
        platformadmin -> dspOperator "Configures DSP deployment via"

        # Relationships - System level
        dspOperator -> argoWorkflows "Deploys workflow-controller, configures argoexec image"
        dspAPIServer -> argoWorkflows "Creates Workflow CRs" "HTTPS/443"
        argoWorkflows -> kubernetes "Manages CRs, creates Pods, leader election" "HTTPS (HTTP/2)/443"
        argoWorkflows -> objectStorage "Downloads/uploads pipeline artifacts" "HTTPS/443"
        argoWorkflows -> database "Archives completed workflows" "TCP/5432 or 3306"
        prometheus -> argoWorkflows "Scrapes metrics" "HTTP(S)/9090"

        # Container-level relationships
        dspAPIServer -> workflowController "Workflow CRs created in K8s API" "HTTPS/443"
        workflowController -> kubernetes "Watch CRs, Create Pods, Leases, Events" "HTTPS (HTTP/2)/443"
        workflowController -> database "Archive workflow data" "TCP/5432 or 3306"
        workflowController -> argoexec "Injects as sidecar in step pods"
        argoexec -> kubernetes "Patch annotations, Create WorkflowTaskResult" "HTTPS/443"
        argoexec -> objectStorage "Download/upload artifacts" "HTTPS/443"
        prometheus -> workflowController "Scrape metrics" "HTTP(S)/9090"
    }

    views {
        systemContext argoWorkflows "SystemContext" {
            include *
            autoLayout
            description "System context diagram showing Argo Workflows in the RHOAI ecosystem"
        }

        container argoWorkflows "Containers" {
            include *
            autoLayout
            description "Container diagram showing workflow-controller and argoexec components"
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
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "FIPS" {
                background #4a90e2
                color #ffffff
            }
            element "DualBinary" {
                background #f5a623
                color #ffffff
            }
        }
    }
}
