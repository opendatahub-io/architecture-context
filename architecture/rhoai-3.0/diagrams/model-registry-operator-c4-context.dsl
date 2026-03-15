workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages model registry instances to track ML model metadata and artifacts"
        admin = person "Platform Administrator" "Deploys and configures the Model Registry Operator"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Kubernetes operator for deploying and managing Model Registry instances" {
            controller = container "Controller Manager" "Reconciles ModelRegistry CRs and manages lifecycle" "Go Operator" {
                tags "Operator"
            }
            webhook = container "Webhook Server" "Validates and mutates ModelRegistry CR changes" "Go Service" {
                tags "Operator"
            }
        }

        modelRegistryInstance = softwareSystem "Model Registry Instance" "REST and gRPC API for model metadata management" {
            restServer = container "REST Server" "Provides REST API for model registry operations" "Go Service" {
                tags "Application"
            }
            grpcServer = container "gRPC Server" "ML Metadata gRPC API for artifact management" "Go Service" {
                tags "Application"
            }
            rbacProxy = container "kube-rbac-proxy" "Authentication proxy with bearer token validation" "Go Proxy" {
                tags "Security"
            }
        }

        kubernetes = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" {
            tags "External"
        }

        postgresql = softwareSystem "PostgreSQL" "Model metadata persistence backend" {
            tags "Database"
        }

        mysql = softwareSystem "MySQL" "Alternative model metadata persistence backend" {
            tags "Database"
        }

        openshiftRouter = softwareSystem "OpenShift Router" "External ingress for HTTPS traffic" {
            tags "External"
        }

        istio = softwareSystem "Istio Service Mesh" "Optional service mesh for advanced networking and mTLS" {
            tags "External" "Optional"
        }

        serviceCA = softwareSystem "OpenShift Service CA" "Auto-generates TLS certificates for services" {
            tags "External" "Optional"
        }

        odhOperator = softwareSystem "OpenDataHub Operator" "Platform operator that manages ODH/RHOAI components" {
            tags "Internal ODH"
        }

        kserve = softwareSystem "KServe" "ML inference platform that integrates with model registry" {
            tags "Internal ODH" "Optional"
        }

        dashboard = softwareSystem "ODH/RHOAI Dashboard" "Web UI for managing platform components" {
            tags "Internal ODH" "Optional"
        }

        pipelines = softwareSystem "Data Science Pipelines" "ML workflow orchestration with model tracking" {
            tags "Internal ODH" "Optional"
        }

        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" {
            tags "External"
        }

        %% User interactions
        user -> modelRegistryInstance "Queries and manages model metadata via REST/gRPC APIs"
        admin -> modelRegistryOperator "Deploys and configures via ModelRegistry CRs"

        %% Operator interactions
        controller -> kubernetes "Watches ModelRegistry CRs, creates/updates resources (Deployments, Services, Routes)" "HTTPS/6443 - ServiceAccount Token"
        kubernetes -> webhook "Validates/mutates ModelRegistry CR changes" "HTTPS/9443 - TLS Client Cert"
        controller -> modelRegistryInstance "Deploys and manages registry instances"

        %% Model Registry Instance interactions
        user -> openshiftRouter "Access registry API" "HTTPS/443"
        openshiftRouter -> rbacProxy "Forwards authenticated requests" "HTTPS/8443 - TLS re-encrypted"
        rbacProxy -> restServer "Proxies to REST server after bearer token validation" "HTTP/8080"
        restServer -> postgresql "Stores/retrieves model metadata" "PostgreSQL/5432 - TLS optional"
        restServer -> mysql "Alternative metadata storage" "MySQL/3306 - TLS optional"
        grpcServer -> postgresql "ML Metadata gRPC operations" "PostgreSQL/5432 - TLS optional"
        grpcServer -> mysql "Alternative gRPC storage" "MySQL/3306 - TLS optional"

        %% External dependencies
        controller -> serviceCA "Requests TLS certificates for services" "N/A"
        controller -> istio "Optional Istio Gateway integration for external access" "N/A"
        controller -> odhOperator "Reads service-mesh-refs ConfigMap for Istio configuration" "N/A"

        %% Integration points
        kserve -> modelRegistryInstance "Fetches model metadata for inference serving" "gRPC/9090"
        dashboard -> modelRegistryOperator "UI-based management of registry instances" "K8s API"
        pipelines -> modelRegistryInstance "Tracks model versions in ML pipelines" "REST API"

        %% Monitoring
        prometheus -> controller "Scrapes operator metrics" "HTTPS/8443"
        prometheus -> modelRegistryInstance "Scrapes registry metrics" "HTTPS/8443"
    }

    views {
        systemContext modelRegistryOperator "ModelRegistryOperatorContext" {
            include *
            autoLayout
        }

        systemContext modelRegistryInstance "ModelRegistryInstanceContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "ModelRegistryOperatorContainers" {
            include *
            autoLayout
        }

        container modelRegistryInstance "ModelRegistryInstanceContainers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Database" {
                background #d79b00
                color #ffffff
                shape Cylinder
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Application" {
                background #50e3c2
                color #000000
            }
            element "Security" {
                background #f5a623
                color #000000
            }
            element "Optional" {
                opacity 50
            }
        }
    }
}
