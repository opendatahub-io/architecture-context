workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages ML models, deploys inference endpoints"
        mlEngineer = person "ML Engineer" "Deploys and monitors model serving infrastructure"

        modelRegistry = softwareSystem "Model Registry (Kubeflow Hub)" "Central metadata registry for ML models with federated catalog, UI, and Kubernetes integration" {
            server = container "model-registry (server)" "REST API proxy for model metadata CRUD (v1alpha3) backed by GORM" "Go Service, :8080/TCP"
            controller = container "InferenceService Controller" "Watches KServe InferenceService CRs to sync labels/finalizers with registry" "Go Controller (controller-runtime), :8081/TCP"
            bff = container "BFF (Backend-For-Frontend)" "Bridges React UI to registry API and Kubernetes API with auth delegation" "Go Service, :8080/TCP"
            ui = container "model-registry-ui" "Web UI for browsing and managing registered models" "TypeScript/React"
            catalog = container "Federated Catalog" "Aggregates models from HuggingFace, MCP servers, serving runtimes, skill catalogs" "Go Service (catalog subcommand), :8080/TCP"
            csi = container "mr-storage-initializer" "KServe storage initializer for model-registry:// URI scheme" "Go CLI (init container)"
            asyncJob = container "async-upload Job" "Async model upload between storage backends with Sigstore signing" "Python Job (AIPCC base)"
        }

        istio = softwareSystem "Istio" "Service mesh providing mTLS, AuthorizationPolicy, and ingress gateway" "External"
        kserve = softwareSystem "KServe" "Serverless ML inference platform managing InferenceService CRs" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for RBAC, resource management, leader election" "External"
        mysql = softwareSystem "MySQL" "Relational database for model metadata storage" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for catalog and alternative registry storage" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for model artifacts" "External"
        hfHub = softwareSystem "HuggingFace Hub" "External model repository for federated catalog" "External"
        ociRegistry = softwareSystem "OCI Registry" "Container/artifact registry for model packages" "External"
        sigstore = softwareSystem "Sigstore" "Model signature verification and transparency log" "External"

        # User interactions
        dataScientist -> ui "Browses/registers models via web UI"
        mlEngineer -> server "Manages models via REST API (kubectl, CLI)"

        # Internal flows
        ui -> bff "API requests"
        bff -> server "Model metadata CRUD" "HTTP/8080, Istio mTLS"
        bff -> k8sAPI "RBAC checks, namespace listing" "HTTPS/6443"

        # Controller flows
        controller -> k8sAPI "Watch InferenceServices, leader election" "HTTPS/6443"
        controller -> server "Sync model metadata" "HTTP/8080, TLS configurable"

        # CSI flows
        csi -> server "Resolve model-registry:// URIs" "HTTP/8080"
        csi -> s3 "Download model artifacts" "HTTPS/443"

        # Async job flows
        asyncJob -> server "Register uploaded models" "HTTP/8080"
        asyncJob -> s3 "Upload/download model artifacts" "HTTPS/443"
        asyncJob -> hfHub "Download models from HuggingFace" "HTTPS/443"
        asyncJob -> ociRegistry "Push/pull OCI artifacts" "HTTPS/443"
        asyncJob -> sigstore "Verify model signatures" "HTTPS/443"

        # Catalog flows
        catalog -> hfHub "Query external model sources" "HTTPS/443"
        catalog -> postgresql "Store catalog metadata" "TCP/5432"

        # Storage
        server -> mysql "Persist model metadata" "TCP/3306"
        server -> postgresql "Persist model metadata (alternative)" "TCP/5432"

        # External integrations
        istio -> server "Route traffic via VirtualService" "HTTP/8080, mTLS"
        istio -> bff "Route traffic via VirtualService" "HTTP/8080, mTLS"
        istio -> catalog "Route traffic via VirtualService" "HTTP/8080, mTLS"
        kserve -> csi "Invoke storage initializer for model-registry:// URIs"
    }

    views {
        systemContext modelRegistry "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistry "Containers" {
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
            element "Person" {
                shape Person
                background #4a90e2
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
