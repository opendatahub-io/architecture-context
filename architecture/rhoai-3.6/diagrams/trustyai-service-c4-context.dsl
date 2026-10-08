workspace {
    model {
        dataScientist = person "Data Scientist" "Queries model fairness, drift, and explainability metrics"
        platformAdmin = person "Platform Admin" "Manages TrustyAI Service deployments via operator"

        trustyaiService = softwareSystem "TrustyAI Service" "Python REST API for Responsible AI workflows: drift detection, fairness monitoring, and model explainability on live inference streams" {
            mainApp = container "Main Application Server" "FastAPI + Hypercorn serving metric computation, metadata, and data upload APIs" "Python / FastAPI" {
                tags "Internal"
                metricsAPI = component "Metrics API" "Drift, fairness, and explainability endpoints with feature-flag gating" "FastAPI Router"
                infoAPI = component "Info API" "Model metadata, column names, and data tags" "FastAPI Router"
                dataUploadAPI = component "Data Upload API" "Manual inference data upload" "FastAPI Router"
                promEndpoint = component "Prometheus Endpoint" "/q/metrics scrape endpoint" "prometheus-client"
            }
            healthApp = container "Health / Consumer Server" "FastAPI + Hypercorn serving health probes and inference payload ingestion" "Python / FastAPI" {
                tags "Internal"
                healthProbes = component "Health Probes" "Liveness, readiness, and combined health checks" "FastAPI Router"
                kserveConsumer = component "KServe Consumer" "Receives CloudEvents from KServe Inference Logger" "FastAPI Router"
                modelMeshConsumer = component "ModelMesh Consumer" "Receives KServe v2 payloads from ModelMesh Agent" "FastAPI Router"
            }
            scheduler = container "PrometheusScheduler" "Background asyncio task computing registered metrics on configurable interval (default 30s)" "Python / asyncio"
            storageLayer = container "Storage Layer" "Abstract StorageInterface with PVC/HDF5 and MariaDB implementations" "Python"
        }

        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication and authorization sidecar for the main API server" "Sidecar" {
            tags "External"
        }
        kserve = softwareSystem "KServe" "ML model serving platform with inference logging" "Internal RHOAI" {
            tags "Internal RHOAI"
        }
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving with inference payload forwarding" "Internal RHOAI" {
            tags "Internal RHOAI"
        }
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal Platform" {
            tags "External"
        }
        mariadb = softwareSystem "MariaDB" "Relational database for inference data storage" "External" {
            tags "External"
        }
        pvc = softwareSystem "PersistentVolumeClaim" "HDF5 file storage for inference data" "Kubernetes" {
            tags "External"
        }
        operator = softwareSystem "trustyai-service-operator" "Manages TrustyAI Service CRDs and deployment lifecycle" "Internal RHOAI" {
            tags "Internal RHOAI"
        }

        # Relationships
        dataScientist -> trustyaiService "Queries metrics and uploads data via" "HTTPS / OAuth Bearer"
        platformAdmin -> operator "Configures TrustyAI deployments via" "kubectl / CRDs"

        dataScientist -> kubeRbacProxy "Sends authenticated requests to" "HTTPS / OAuth Bearer"
        kubeRbacProxy -> mainApp "Forwards authenticated requests to" "HTTP/8081"

        kserve -> healthApp "Sends inference payloads via" "HTTP/8080 CloudEvents"
        modelMesh -> healthApp "Sends inference payloads via" "HTTP/8080 KServe v2"

        prometheus -> kubeRbacProxy "Scrapes metrics via" "HTTP/8081"
        kubeRbacProxy -> promEndpoint "Forwards scrape to" "HTTP/8081"

        scheduler -> storageLayer "Reads inference data from" "Internal"
        scheduler -> promEndpoint "Publishes computed metrics to" "prometheus-client gauges"

        storageLayer -> pvc "Reads/writes HDF5 files on" "Local filesystem"
        storageLayer -> mariadb "Reads/writes inference data via" "MySQL/3306, TLS optional"

        operator -> trustyaiService "Creates and manages" "Deployment lifecycle"
    }

    views {
        systemContext trustyaiService "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiService "Containers" {
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
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427B
                color #ffffff
            }
        }
    }
}
