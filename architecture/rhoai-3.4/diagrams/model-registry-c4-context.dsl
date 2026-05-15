workspace {
    model {
        dataScientist = person "Data Scientist" "Creates, versions, and deploys ML models"
        mlEngineer = person "ML Engineer" "Manages model serving infrastructure and pipelines"

        modelRegistry = softwareSystem "Model Registry" "Central metadata repository for ML model lifecycle — stores models, versions, artifacts, serving environments, and experiments" {
            apiServer = container "REST API Server" "OpenAPI v1alpha3 REST interface for model metadata CRUD operations. Backed by embedmd datastore (GORM ORM)" "Go Service, 8080/TCP HTTP" {
                tags "Primary"
            }
            controller = container "InferenceService Controller" "Watches KServe InferenceService CRs and synchronizes lifecycle metadata with Model Registry API" "Go Operator (controller-runtime)" {
                tags "Controller"
            }
            csiInitializer = container "mr-storage-initializer" "KServe init container that resolves model-registry:// URIs to actual storage URIs for model loading" "Go CLI" {
                tags "Utility"
            }
            asyncUploadJob = container "async-upload Job" "Kubernetes Job that copies models between storage backends (S3/OCI/HuggingFace) and registers them in Model Registry" "Python 3.12 Job" {
                tags "Job"
            }
            database = container "Metadata Database" "Stores MLMD schema: types, properties, contexts, artifacts, executions across 13 MLMD type definitions" "MySQL 8.3+ / PostgreSQL 16+" {
                tags "Database"
            }
        }

        # Internal RHOAI Dependencies
        kserve = softwareSystem "KServe" "Serverless ML inference platform providing InferenceService CRD" {
            tags "Internal RHOAI"
        }
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for model browsing and management" {
            tags "Internal RHOAI"
        }
        rhodsOperator = softwareSystem "RHODS Operator" "Platform operator that deploys Model Registry instances" {
            tags "Internal RHOAI"
        }
        istio = softwareSystem "Istio Service Mesh" "Service mesh for traffic routing, mTLS, and authorization" {
            tags "Infrastructure"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "Infrastructure"
        }

        # External Services
        s3 = softwareSystem "S3 Storage" "Model artifact storage (AWS S3 / MinIO)" {
            tags "External"
        }
        ociRegistry = softwareSystem "OCI Registry" "Container/model image registry (Quay / DockerHub)" {
            tags "External"
        }
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Public ML model repository" {
            tags "External"
        }
        sigstore = softwareSystem "Sigstore" "Model and image signing/verification (Fulcio, Rekor, TUF)" {
            tags "External"
        }
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server" {
            tags "Infrastructure"
        }

        # Person interactions
        dataScientist -> modelRegistry "Registers models, creates versions, queries metadata via REST API or Python SDK"
        mlEngineer -> modelRegistry "Manages serving environments, inference services, and model deployments"

        # Container-level relationships
        apiServer -> database "Reads/writes model metadata" "MySQL 3306/TCP or PostgreSQL 5432/TCP, Optional TLS 1.2+"
        controller -> apiServer "Syncs InferenceService lifecycle metadata" "HTTP/8080 (InsecureSkipVerify)"
        controller -> kubernetesAPI "Watches InferenceService CRs, manages finalizers" "HTTPS/443, ServiceAccount token"
        csiInitializer -> apiServer "Resolves model-registry:// URIs" "HTTP/8080"
        csiInitializer -> s3 "Downloads model artifacts" "HTTPS/443, Storage credentials"
        asyncUploadJob -> apiServer "Registers/updates model artifacts" "HTTPS/443, Bearer token"
        asyncUploadJob -> s3 "Downloads/uploads model files" "HTTPS/443, AWS IAM"
        asyncUploadJob -> ociRegistry "Pushes/pulls model images via skopeo" "HTTPS/443, Docker auth"
        asyncUploadJob -> huggingfaceHub "Downloads model snapshots" "HTTPS/443, HF API key"
        asyncUploadJob -> sigstore "Signs and verifies models/images" "HTTPS/443, OIDC identity"

        # System-level relationships
        kserve -> modelRegistry "InferenceService CRD watched by controller; CSI resolves model-registry:// URIs"
        dashboard -> modelRegistry "Queries REST API for model browsing and management" "HTTP/8080"
        rhodsOperator -> modelRegistry "Deploys Model Registry instances via kustomize manifests"
        modelRegistry -> istio "Traffic routing via VirtualService, mTLS via DestinationRule" "ISTIO_MUTUAL"
        modelRegistry -> prometheus "Exposes controller metrics via ServiceMonitor" "HTTPS/8443"
    }

    views {
        systemContext modelRegistry "SystemContext" {
            include *
            autoLayout
            description "Model Registry in the context of the RHOAI platform and external services"
        }

        container modelRegistry "Containers" {
            include *
            autoLayout
            description "Internal structure of the Model Registry component"
        }

        styles {
            element "Software System" {
                background #438dd5
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
            element "Database" {
                shape cylinder
                background #f5a623
                color #000000
            }
            element "Primary" {
                background #1168bd
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Utility" {
                background #6cb4ee
                color #000000
            }
            element "Job" {
                background #9b59b6
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "External" {
                background #e8e8e8
                color #000000
            }
        }
    }
}
