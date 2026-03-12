workspace {
    model {
        datascientist = person "Data Scientist" "Creates feature definitions and trains ML models"
        mlapp = person "ML Application" "Consumes features for real-time inference"

        feast = softwareSystem "Feast Feature Store" "Manages features consistently for training and serving with point-in-time correctness" {
            operator = container "Feast Operator" "Manages FeatureStore CR lifecycle and deploys Feast components" "Go Kubernetes Operator" {
                tags "Operator"
            }

            onlineServer = container "Feature Server (Online)" "Serves pre-computed features for real-time inference" "Python FastAPI/Uvicorn" {
                tags "FeatureServer"
            }

            offlineServer = container "Feature Server (Offline)" "Serves historical features for batch scoring and training" "Python FastAPI/Uvicorn" {
                tags "FeatureServer"
            }

            registry = container "Registry Service" "Stores and serves feature definitions, metadata, and schemas" "Python gRPC/HTTP" {
                tags "Registry"
            }

            transform = container "Transformation Service" "Executes on-demand feature transformations" "Python gRPC" {
                tags "Transform"
            }

            ui = container "UI Service" "Web interface for exploring and managing features" "TypeScript React" {
                tags "UI"
            }
        }

        k8s = softwareSystem "Kubernetes API" "Container orchestration and resource management" {
            tags "Infrastructure"
        }

        istio = softwareSystem "Istio Service Mesh" "Provides mTLS, traffic management, and authorization" {
            tags "ServiceMesh"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" {
            tags "Observability"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate provisioning and rotation" {
            tags "Security"
        }

        redisDB = softwareSystem "Redis" "Low-latency online store for features" {
            tags "Storage"
        }

        postgresDB = softwareSystem "PostgreSQL" "Relational database for online store and registry" {
            tags "Storage"
        }

        bigquery = softwareSystem "Google BigQuery" "Cloud data warehouse for offline historical features" {
            tags "CloudStorage"
        }

        snowflake = softwareSystem "Snowflake" "Cloud data platform for offline features" {
            tags "CloudStorage"
        }

        s3 = softwareSystem "AWS S3" "Object storage for registry file backend" {
            tags "CloudStorage"
        }

        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry file backend" {
            tags "CloudStorage"
        }

        kserve = softwareSystem "KServe" "Model serving platform that integrates with Feast for feature retrieval" {
            tags "ODHIntegration"
        }

        seldon = softwareSystem "Seldon Core" "Model serving platform that integrates with Feast" {
            tags "ODHIntegration"
        }

        mlflow = softwareSystem "MLflow" "ML lifecycle platform with Feast integration for feature selection" {
            tags "ODHIntegration"
        }

        kubeflow = softwareSystem "Kubeflow Pipelines" "ML workflow orchestration with Feast feature serving" {
            tags "ODHIntegration"
        }

        kafka = softwareSystem "Apache Kafka" "Streaming platform for feature ingestion" {
            tags "DataPipeline"
        }

        spark = softwareSystem "Apache Spark" "Distributed processing for batch feature engineering" {
            tags "DataPipeline"
        }

        # User interactions
        datascientist -> feast "Creates FeatureStore CR, defines features, trains models"
        mlapp -> onlineServer "Requests features for real-time inference" "HTTP/gRPC 80/6566"

        # Feast internal relationships
        operator -> k8s "Watches CRs, manages deployments" "HTTPS 6443"
        operator -> onlineServer "Deploys and manages"
        operator -> offlineServer "Deploys and manages"
        operator -> registry "Deploys and manages"
        operator -> transform "Deploys and manages"
        operator -> ui "Deploys and manages"

        onlineServer -> registry "Fetches feature metadata" "gRPC 6570"
        offlineServer -> registry "Fetches feature metadata" "gRPC 6570"
        onlineServer -> transform "Requests feature transformations" "gRPC 6569"
        ui -> registry "Browses features" "HTTP/gRPC 6572/6570"

        # Storage interactions
        onlineServer -> redisDB "Reads/writes online features" "Redis 6379, TLS Optional"
        onlineServer -> postgresDB "Reads/writes online features" "PostgreSQL 5432, TLS"
        offlineServer -> bigquery "Queries historical features" "HTTPS 443, TLS 1.2+"
        offlineServer -> snowflake "Queries historical features" "HTTPS 443, TLS 1.2+"
        registry -> postgresDB "Stores registry metadata" "PostgreSQL 5432, TLS"
        registry -> s3 "Stores registry file backend" "HTTPS 443, TLS 1.2+"
        registry -> gcs "Stores registry file backend" "HTTPS 443, TLS 1.2+"

        # Materialization flow
        onlineServer -> offlineStore "Materializes features from offline to online" "HTTPS 443"

        # Infrastructure dependencies
        feast -> istio "Uses for mTLS and traffic management" "Optional"
        feast -> prometheus "Exports metrics" "HTTP 8000"
        feast -> certManager "Provisions TLS certificates" "Optional"

        # ODH/RHOAI integrations
        kserve -> onlineServer "Fetches features during inference" "gRPC/HTTP 6566/80"
        seldon -> onlineServer "Fetches features during inference" "gRPC/HTTP 6566/80"
        mlflow -> feast "Feature selection for model training" "Python SDK"
        kubeflow -> feast "Feature serving in ML pipelines" "Python SDK"

        # Data pipeline integrations
        kafka -> onlineServer "Pushes streaming features" "HTTP 80 /push"
        spark -> offlineServer "Batch feature engineering" "Python SDK"

        datascientist -> ui "Explores and manages features" "HTTPS 443"
    }

    views {
        systemContext feast "FeastSystemContext" {
            include *
            autolayout lr
            description "System context diagram for Feast Feature Store showing external actors and systems"
        }

        container feast "FeastContainers" {
            include *
            autolayout lr
            description "Container diagram showing Feast internal components and their relationships"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "FeatureServer" {
                background #4a90e2
                color #ffffff
            }
            element "Registry" {
                background #4a90e2
                color #ffffff
            }
            element "Transform" {
                background #4a90e2
                color #ffffff
            }
            element "UI" {
                background #4a90e2
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "ServiceMesh" {
                background #999999
                color #ffffff
            }
            element "Observability" {
                background #7ed321
                color #000000
            }
            element "Security" {
                background #f5a623
                color #000000
            }
            element "Storage" {
                background #bd3786
                color #ffffff
            }
            element "CloudStorage" {
                background #ff6b6b
                color #ffffff
            }
            element "ODHIntegration" {
                background #7ed321
                color #000000
            }
            element "DataPipeline" {
                background #50e3c2
                color #000000
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
