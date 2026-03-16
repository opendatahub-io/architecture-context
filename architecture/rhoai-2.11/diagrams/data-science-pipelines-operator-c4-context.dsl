workspace {
    model {
        user = person "Data Scientist" "Creates and executes ML workflows for data preparation, model training, and experimentation"

        dspo = softwareSystem "Data Science Pipelines Operator (DSPO)" "Kubernetes operator that deploys and manages namespace-scoped Data Science Pipeline stacks for ML workflow orchestration" {
            controller = container "DSPO Controller Manager" "Reconciles DataSciencePipelinesApplication CRs and deploys DSP stack components" "Go Operator" {
                tags "Operator"
            }
            apiserver = container "KFP API Server" "REST/gRPC API for pipeline and run management" "Go Service" {
                tags "Core Service"
            }
            persistenceagent = container "Persistence Agent" "Syncs workflow state to database for persistence" "Go Service" {
                tags "Core Service"
            }
            scheduledworkflow = container "Scheduled Workflow Controller" "Manages scheduled and recurring pipeline executions" "Go Service" {
                tags "Core Service"
            }
            workflowcontroller = container "Workflow Controller" "Argo Workflows controller for DSP v2 pipeline execution" "Go Service" {
                tags "Core Service"
            }
            ui = container "ML Pipelines UI" "Web interface for pipeline visualization and management" "React Application" {
                tags "Optional Component"
            }
            mlmd = container "ML Metadata (MLMD)" "ML artifact lineage and metadata tracking service" "Python gRPC Service + Envoy" {
                tags "Optional Component"
            }
            mariadb = container "MariaDB" "MySQL-compatible database for pipeline metadata" "MariaDB 10.3" {
                tags "Optional Component"
            }
            minio = container "Minio" "S3-compatible object storage for pipeline artifacts" "Minio Service" {
                tags "Optional Component"
            }
        }

        # External systems
        openshift = softwareSystem "OpenShift" "Kubernetes platform with Routes, ServiceMonitors, and OAuth" "External Platform"
        argoworkflows = softwareSystem "Argo Workflows" "Workflow execution engine for v2 pipelines" "External Dependency"
        tekton = softwareSystem "OpenShift Pipelines (Tekton)" "Workflow execution engine for v1 pipelines" "External Dependency"
        externalS3 = softwareSystem "External S3 Storage" "AWS S3 or S3-compatible object storage for pipeline artifacts" "External Service"
        externalDB = softwareSystem "External MySQL/MariaDB" "External database for pipeline metadata storage" "External Service"
        containerRegistry = softwareSystem "Container Registries" "Container image storage for pipeline components" "External Service"

        # Internal ODH systems
        odhOperator = softwareSystem "OpenDataHub Operator" "Deploys and manages ODH components via DataScienceCluster CR" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for ODH component management and project integration" "Internal ODH"

        # Monitoring
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External Platform"

        # Relationships - User interactions
        user -> apiserver "Submits pipelines and queries runs via KFP SDK" "HTTPS/8888, OAuth"
        user -> ui "Visualizes pipelines and experiments" "HTTPS/8443, OAuth"
        user -> dspo "Creates DataSciencePipelinesApplication CR via kubectl" "HTTPS/6443"

        # Relationships - Controller operations
        controller -> openshift "Watches DSPA CRs and creates Deployments, Services, Routes" "HTTPS/6443, SA Token"
        controller -> apiserver "Deploys and configures" "Kubernetes API"
        controller -> persistenceagent "Deploys and configures" "Kubernetes API"
        controller -> scheduledworkflow "Deploys and configures" "Kubernetes API"
        controller -> workflowcontroller "Deploys and configures" "Kubernetes API"
        controller -> ui "Optionally deploys" "Kubernetes API"
        controller -> mlmd "Optionally deploys" "Kubernetes API"
        controller -> mariadb "Optionally provisions" "Kubernetes API"
        controller -> minio "Optionally provisions" "Kubernetes API"

        # Relationships - Service interactions
        apiserver -> mariadb "Stores pipeline metadata" "MySQL/3306, Password"
        apiserver -> minio "Stores pipeline artifacts" "HTTP/9000, Access Key"
        apiserver -> externalS3 "Stores pipeline artifacts (alternative)" "HTTPS/443, AWS IAM"
        apiserver -> externalDB "Stores pipeline metadata (alternative)" "MySQL/3306, Password"
        apiserver -> workflowcontroller "Creates Workflow CRs for execution" "gRPC/8887, mTLS"

        persistenceagent -> mariadb "Syncs workflow state" "MySQL/3306, Password"
        persistenceagent -> externalDB "Syncs workflow state (alternative)" "MySQL/3306, Password"

        workflowcontroller -> openshift "Creates and manages pipeline pods" "HTTPS/6443, SA Token"
        workflowcontroller -> argoworkflows "Uses for DSP v2 workflow execution" "Embedded"

        scheduledworkflow -> workflowcontroller "Triggers scheduled workflows" "Kubernetes API"

        mlmd -> mariadb "Stores artifact metadata and lineage" "MySQL/3306, Password"
        mlmd -> externalDB "Stores artifact metadata (alternative)" "MySQL/3306, Password"

        ui -> apiserver "Queries pipelines and runs" "HTTP/8888"
        ui -> mlmd "Queries artifact metadata" "gRPC/9090"

        # Pipeline pods
        openshift -> minio "Pipeline pods access artifacts" "HTTP/9000, Access Key"
        openshift -> externalS3 "Pipeline pods access artifacts (alternative)" "HTTPS/443, AWS IAM"
        openshift -> mlmd "Pipeline pods track metadata" "gRPC/9090, mTLS"
        openshift -> containerRegistry "Pipeline pods pull images" "HTTPS/443, Pull Secret"

        # ODH integration
        odhOperator -> controller "Deploys via DataScienceCluster CR" "Kubernetes API"
        odhDashboard -> ui "Integrates pipeline UI access" "HTTPS/443"

        # Alternative execution for v1
        apiserver -> tekton "Creates Tekton PipelineRun CRs for DSP v1" "Kubernetes API"
        tekton -> openshift "Executes v1 pipelines" "Embedded"

        # Monitoring
        controller -> prometheus "Exposes operator metrics" "HTTP/8080"
        workflowcontroller -> prometheus "Exposes workflow metrics" "HTTP/9090"
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

        styles {
            element "External Platform" {
                background #999999
                color #ffffff
            }
            element "External Dependency" {
                background #cccccc
                color #000000
            }
            element "External Service" {
                background #f8cecc
                stroke #b85450
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Core Service" {
                background #50b5e9
                color #ffffff
            }
            element "Optional Component" {
                background #b3d9ff
                color #000000
            }
        }
    }
}
