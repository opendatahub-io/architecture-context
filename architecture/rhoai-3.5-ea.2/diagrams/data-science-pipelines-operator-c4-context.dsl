workspace {
    model {
        datascientist = person "Data Scientist" "Creates and runs ML pipelines via DSPA CRs or Dashboard UI"
        platformadmin = person "Platform Admin" "Deploys and configures DSPA instances via rhods-operator"

        dspo = softwareSystem "Data Science Pipelines Operator" "Manages lifecycle of Kubeflow Pipelines v2 stacks on OpenShift AI" {
            controller = container "DSPO Controller" "Reconciles DSPA CRs; deploys managed sub-components via manifestival templates" "Go Operator (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates and mutates PipelineVersion resources" "Go Service, 8443/TCP HTTPS"
            apiServer = container "DS Pipeline API Server" "Kubeflow Pipelines v2 REST (8888/TCP) and gRPC (8887/TCP) API" "Go Service"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS termination and SubjectAccessReview authorization sidecar" "Go Proxy, 8443/TCP"
            persistenceAgent = container "Persistence Agent" "Syncs Argo Workflow status to Pipelines API server" "Go Service"
            scheduledWorkflow = container "Scheduled Workflow Controller" "Manages cron-based pipeline scheduling via ScheduledWorkflow CRDs" "Go Service"
            workflowController = container "Argo Workflow Controller" "Executes pipeline steps as Kubernetes pods" "Go Controller"
            metadataGrpc = container "ML Metadata gRPC" "Artifact and execution lineage tracking" "gRPC Service, 8080/TCP"
            metadataEnvoy = container "Metadata Envoy" "gRPC-Web translation proxy with kube-rbac-proxy auth" "Envoy, 9090/TCP"
            mariadb = container "MariaDB" "MySQL-compatible database for pipeline metadata (optional managed)" "MariaDB, 3306/TCP"
            minio = container "MinIO" "S3-compatible object storage for pipeline artifacts (optional managed)" "MinIO, 9000/TCP"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that creates DSPA CRs" "Internal Platform"
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API for CRD operations, pod management, RBAC" "Platform"
        openshiftApi = softwareSystem "OpenShift API Server" "Route management, image stream tag resolution" "Platform"
        serviceCA = softwareSystem "OpenShift Service CA Operator" "Auto-provisions and rotates TLS certificates for services" "Platform"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection via ServiceMonitor" "Platform"
        externalDB = softwareSystem "External Database" "External MariaDB/MySQL for pipeline metadata (alternative to managed)" "External"
        externalS3 = softwareSystem "External S3 Storage" "External S3-compatible storage for pipeline artifacts (AWS S3, Ceph, etc.)" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Container image registry for managed pipeline definitions" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform; pipeline steps can create InferenceService resources" "Internal Platform"
        ray = softwareSystem "Ray" "Distributed compute; pipeline steps can create RayCluster/RayJob resources" "Internal Platform"
        codeflare = softwareSystem "CodeFlare" "Workload orchestration; pipeline steps can create AppWrapper resources" "Internal Platform"

        # User interactions
        datascientist -> dspo "Creates/manages pipelines via Dashboard or kubectl"
        platformadmin -> rhodsOperator "Configures DSPA instances"
        rhodsOperator -> dspo "Creates DSPA CRs in user namespaces"

        # Internal container relationships
        controller -> apiServer "Deploys via manifestival templates"
        controller -> workflowController "Deploys via manifestival templates"
        controller -> persistenceAgent "Deploys via manifestival templates"
        controller -> scheduledWorkflow "Deploys via manifestival templates"
        controller -> metadataGrpc "Deploys via manifestival templates"
        controller -> metadataEnvoy "Deploys via manifestival templates"
        controller -> mariadb "Deploys via manifestival templates (optional)"
        controller -> minio "Deploys via manifestival templates (optional)"
        kubeRbacProxy -> apiServer "Proxies authenticated requests" "HTTP/8888"
        apiServer -> mariadb "Stores pipeline metadata" "MySQL/3306 TLS conditional"
        apiServer -> minio "Stores pipeline artifacts" "HTTP/9000"
        persistenceAgent -> apiServer "Syncs workflow status" "HTTP/8888 SA token"
        metadataEnvoy -> metadataGrpc "gRPC-Web to gRPC translation" "gRPC/8080"
        metadataGrpc -> mariadb "Stores lineage data" "MySQL/3306 TLS conditional"
        workflowController -> k8sApi "Creates pipeline pods" "HTTPS/443"

        # External dependencies
        dspo -> k8sApi "CRD operations, pod management, webhook registration" "HTTPS/443 TLS"
        dspo -> openshiftApi "Route creation, image stream tags" "HTTPS/443 TLS"
        dspo -> externalDB "Pipeline metadata (if external DB configured)" "MySQL/3306 TLS 1.2+"
        dspo -> externalS3 "Pipeline artifacts (if external storage configured)" "HTTPS/443 TLS 1.2+"
        dspo -> ociRegistry "Managed pipeline image fetch and validation" "HTTPS/443 TLS"
        serviceCA -> dspo "Provisions TLS certificates via annotation" "Auto-rotation"
        prometheus -> dspo "Scrapes metrics" "HTTP/8080, 8888, 9090"

        # Integration points
        dspo -> kserve "Pipeline steps create InferenceService resources" "CRD Create"
        dspo -> ray "Pipeline steps create RayCluster/RayJob resources" "CRD Create"
        dspo -> codeflare "Pipeline steps create AppWrapper resources" "CRD Create"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
