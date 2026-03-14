workspace {
    model {
        user = person "Data Scientist" "Creates features and trains ML models"
        mlApp = person "ML Application" "Consumes features for real-time inference"

        feast = softwareSystem "Feast Feature Store" "Manages, serves, and tracks features for machine learning with point-in-time correctness" {
            operator = container "Feast Operator" "Manages FeatureStore lifecycle and deploys feature servers" "Go Operator" {
                tags "Operator"
            }

            online = container "Online Feature Server" "Serves features for real-time inference with low latency" "Python FastAPI/gRPC" {
                tags "FeatureServer"
            }

            offline = container "Offline Feature Server" "Serves historical features for model training and batch scoring" "Python FastAPI" {
                tags "FeatureServer"
            }

            registry = container "Registry Server" "Manages feature metadata (entities, feature views, data sources)" "Python gRPC/REST" {
                tags "Registry"
            }

            ui = container "UI Server" "Web interface for feature discovery and exploration" "React/TypeScript" {
                tags "UI"
            }

            cronJob = container "Materialization CronJob" "Executes scheduled feature materialization from offline to online store" "Kubernetes CronJob" {
                tags "Job"
            }
        }

        # External dependencies
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            tags "External"
        }

        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with Routes and enhanced RBAC" "External" {
            tags "External"
        }

        # Storage systems
        postgresql = softwareSystem "PostgreSQL" "Persistent relational database for registry and online features" "External" {
            tags "External" "Database"
        }

        redis = softwareSystem "Redis" "High-performance in-memory data store for online features" "External" {
            tags "External" "Database"
        }

        s3 = softwareSystem "S3 / Object Storage" "Stores offline feature data and registry metadata" "External" {
            tags "External" "Storage"
        }

        # RHOAI/ODH dependencies
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive development environments for data scientists" "Internal RHOAI" {
            tags "Internal"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring platform" "Internal RHOAI" {
            tags "Internal"
        }

        oidc = softwareSystem "OIDC Provider" "Authentication and identity provider (e.g., OpenShift OAuth)" "Internal RHOAI" {
            tags "Internal"
        }

        certManager = softwareSystem "cert-manager" "Automated TLS certificate provisioning and management" "Internal RHOAI" {
            tags "Internal"
        }

        git = softwareSystem "Git Repository" "Version control for feature definitions and configurations" "External" {
            tags "External"
        }

        # User interactions
        user -> feast "Creates FeatureStore, defines features, trains models using feast SDK/CLI"
        user -> ui "Browses and explores feature catalog"
        mlApp -> online "Requests features for real-time predictions" "gRPC/HTTP"

        # Feast internal interactions
        operator -> kubernetes "Manages FeatureStore resources, creates deployments and services" "Kubernetes API"
        operator -> openshift "Creates Routes for external access" "OpenShift Route API"
        operator -> online "Deploys and manages" "Kubernetes API"
        operator -> offline "Deploys and manages" "Kubernetes API"
        operator -> registry "Deploys and manages" "Kubernetes API"
        operator -> ui "Deploys and manages" "Kubernetes API"
        operator -> cronJob "Creates and schedules" "Kubernetes API"

        online -> registry "Fetches feature metadata" "gRPC/6570"
        offline -> registry "Fetches feature metadata" "gRPC/6570"
        cronJob -> online "Triggers materialization" "HTTP/6566"
        online -> offline "Fetches offline features for materialization" "HTTP/8815"

        # Storage interactions
        online -> postgresql "Reads/writes online features (optional)" "PostgreSQL/5432"
        online -> redis "Reads/writes online features (optional)" "Redis/6379"
        registry -> postgresql "Persists feature metadata (optional)" "PostgreSQL/5432"
        registry -> s3 "Persists registry metadata (optional)" "HTTPS/443"
        offline -> s3 "Reads historical feature data" "HTTPS/443"

        # RHOAI integrations
        operator -> kubeflowNotebooks "Injects feast client configuration into notebooks" "ConfigMap injection"
        online -> prometheus "Exposes feature server metrics" "HTTP/8000"
        offline -> prometheus "Exposes feature server metrics" "HTTP/8000"
        operator -> prometheus "Exposes operator metrics" "HTTPS/8443"
        online -> oidc "Validates JWT tokens for authentication" "HTTPS/443"
        offline -> oidc "Validates JWT tokens for authentication" "HTTPS/443"
        registry -> oidc "Validates JWT tokens for authentication" "HTTPS/443"
        operator -> certManager "Requests TLS certificates for services (optional)" "cert-manager API"
        registry -> git "Synchronizes feature definitions from Git (optional)" "HTTPS/443"
    }

    views {
        systemContext feast "FeastSystemContext" {
            include *
            autoLayout
            title "[System Context] Feast Feature Store"
            description "Shows how Feast integrates with RHOAI/ODH ecosystem and external services"
        }

        container feast "FeastContainers" {
            include *
            autoLayout
            title "[Container] Feast Feature Store Components"
            description "Internal architecture of Feast feature store platform"
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal" {
                background #7ed321
                color #ffffff
            }
            element "Database" {
                shape cylinder
            }
            element "Storage" {
                shape folder
            }
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "FeatureServer" {
                background #7ed321
                color #ffffff
            }
            element "Registry" {
                background #f5a623
                color #ffffff
            }
            element "UI" {
                background #bd10e0
                color #ffffff
            }
            element "Job" {
                background #b8e986
                color #333333
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
