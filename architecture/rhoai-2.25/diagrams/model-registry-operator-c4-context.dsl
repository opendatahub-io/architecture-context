workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages ML model registries, registers models and artifacts"
        platformadmin = person "Platform Admin" "Deploys and configures Model Registry instances via CRDs"

        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages lifecycle of Model Registry instances on OpenShift, deploying REST/gRPC services backed by PostgreSQL/MySQL with optional OAuth proxy authentication" {
            controller = container "ModelRegistry Controller" "Watches ModelRegistry CRs and reconciles Deployments, Services, Routes, RBAC, NetworkPolicies per instance" "Go (controller-runtime)"
            catalogController = container "ModelCatalog Controller" "Deploys singleton model catalog service with curated model metadata; optional, gated by ENABLE_MODEL_CATALOG" "Go (controller-runtime)"
            migrationManager = container "Storage Migration Manager" "Background goroutine that migrates CRD storage from v1alpha1 to v1beta1 via SVM API or manual re-read/re-write" "Go (background service)"
            webhooks = container "Admission Webhooks" "Mutating (defaults images/ports/OAuth), Validating (DB config, namespace), Conversion (v1alpha1 <-> v1beta1)" "Go (controller-runtime webhook)"
        }

        managedRegistry = softwareSystem "Model Registry Instance" "Per-instance deployment of REST proxy + gRPC MLMD server with optional OAuth proxy sidecar" {
            oauthProxy = container "OAuth Proxy Sidecar" "OpenShift OAuth2 proxy for authentication; port 8443/TCP HTTPS" "ose-oauth-proxy"
            restService = container "REST Service" "REST API proxy for ML Metadata operations" "model-registry (Go)"
            grpcService = container "gRPC MLMD Server" "ML Metadata gRPC service for artifact and model storage" "mlmd-grpc-server (C++)"
        }

        modelCatalog = softwareSystem "Model Catalog" "Singleton browsable index of ML models loaded from curated data image" {
            catalogOAuth = container "Catalog OAuth Proxy" "OpenShift OAuth2 proxy for catalog authentication" "ose-oauth-proxy"
            catalogService = container "Catalog REST Service" "Serves model catalog data" "Go"
            catalogInit = container "Data Init Container" "Loads model metadata YAML from curated image" "odh-model-metadata-collection"
        }

        # External Systems
        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management, CRD watches, RBAC" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller providing Route-based external access with TLS termination" "External"
        openshiftApis = softwareSystem "OpenShift Platform APIs" "Route API, User API, Config API, Serving Cert Controller" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for MLMD metadata storage (option 1)" "External"
        mysql = softwareSystem "MySQL" "Relational database for MLMD metadata storage (option 2)" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring via ServiceMonitor" "External"
        containerRegistry = softwareSystem "Container Registry" "Hosts container images for model-registry, mlmd-grpc-server, oauth-proxy, catalog data" "External"
        platformCR = softwareSystem "ODH Platform Component" "components.platform.opendatahub.io ModelRegistries CR for platform-level ownership" "Internal ODH"

        # Relationships - Platform Admin
        platformadmin -> modelRegistryOperator "Creates/manages ModelRegistry CRs via kubectl"

        # Relationships - Data Scientist
        datascientist -> managedRegistry "Registers models and artifacts via REST API"
        datascientist -> modelCatalog "Browses available ML models"

        # Relationships - Operator internals
        controller -> k8sApi "Watches CRDs, creates/updates managed resources" "HTTPS/443"
        controller -> openshiftApis "Manages Routes, Groups, reads ingress domain" "HTTPS/443"
        catalogController -> k8sApi "Manages catalog Deployment, Service, Route" "HTTPS/443"
        catalogController -> platformCR "Watches platform-level ModelRegistry component CR" "HTTPS/443"
        migrationManager -> k8sApi "Creates StorageVersionMigration CRs, re-reads/re-writes ModelRegistries" "HTTPS/443"
        webhooks -> k8sApi "Queries existing ModelRegistries for name uniqueness" "HTTPS/443"
        k8sApi -> webhooks "Calls mutating/validating/conversion webhooks" "HTTPS/9443"

        # Relationships - Managed Registry
        oauthProxy -> restService "Forwards authenticated requests" "HTTP/localhost"
        restService -> grpcService "Queries ML Metadata" "gRPC/localhost"
        grpcService -> postgresql "Stores/retrieves metadata" "PostgreSQL/{port} (optional TLS)"
        grpcService -> mysql "Stores/retrieves metadata" "MySQL/{port} (optional TLS)"
        openshiftRouter -> oauthProxy "Routes external HTTPS traffic" "HTTPS/8443 (TLS reencrypt)"

        # Relationships - Catalog
        catalogOAuth -> catalogService "Forwards authenticated requests" "HTTP/localhost"
        openshiftRouter -> catalogOAuth "Routes external HTTPS traffic" "HTTPS/8443 (TLS reencrypt)"

        # Relationships - Infrastructure
        prometheus -> modelRegistryOperator "Scrapes operator metrics" "HTTPS/8443"
        modelRegistryOperator -> containerRegistry "Pulls container images for managed Deployments" "HTTPS/443"
        openshiftApis -> managedRegistry "Auto-provisions TLS certificates via serving cert controller" "Annotation-driven"
    }

    views {
        systemContext modelRegistryOperator "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistryOperator "OperatorContainers" {
            include *
            autoLayout
        }

        container managedRegistry "ManagedRegistryContainers" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
