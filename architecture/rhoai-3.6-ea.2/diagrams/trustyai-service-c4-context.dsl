workspace {
    model {
        dataScientist = person "Data Scientist" "Configures fairness metrics and monitors model behavior"
        platformAdmin = person "Platform Admin" "Manages TrustyAI deployments via operator"

        trustyaiService = softwareSystem "TrustyAI Service" "Python-based responsible AI platform service providing fairness monitoring, drift detection, and explainability metrics" {
            mainAPI = container "Main API" "REST API for fairness, drift, explainability, and data management" "Python FastAPI/Hypercorn" "Port 8081 (loopback)"
            healthApp = container "Health App" "Health probes and KServe/ModelMesh inference consumer" "Python FastAPI" "Port 8080 (all interfaces)"
            prometheusScheduler = container "Prometheus Scheduler" "Periodically computes registered metrics and publishes to Prometheus" "Python asyncio"
            storageLayer = container "Storage Layer" "Abstraction over PVC (HDF5) and MariaDB backends" "Python"

            healthApp -> storageLayer "Writes inference data"
            mainAPI -> storageLayer "Reads inference data for metric computation"
            prometheusScheduler -> storageLayer "Reads data for scheduled computations"
            prometheusScheduler -> mainAPI "Updates Prometheus gauges"
        }

        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar enforcing Kubernetes RBAC" "Sidecar"
        trustyaiOperator = softwareSystem "TrustyAI Operator" "Deploys and configures TrustyAI Service instances" "Internal RHOAI"
        kserve = softwareSystem "KServe" "ML inference serving platform with inference logging" "Internal RHOAI"
        modelMesh = softwareSystem "ModelMesh" "Multi-model serving with inference agents" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Metrics collection and alerting" "Internal RHOAI"
        mariaDB = softwareSystem "MariaDB" "Optional persistent database for inference data" "External"
        pvc = softwareSystem "PVC Volume" "Default persistent storage via HDF5 files" "Infrastructure"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects" "Internal RHOAI"

        dataScientist -> kubeRBACProxy "Requests fairness/drift metrics via HTTPS"
        kubeRBACProxy -> trustyaiService "Forwards authenticated requests (HTTP/8081 loopback)"

        kserve -> trustyaiService "Sends inference payloads (CloudEvent POST/8080)"
        modelMesh -> trustyaiService "Sends inference payloads (KServe v2 POST/8080)"
        prometheus -> kubeRBACProxy "Scrapes /q/metrics via proxy"
        odhDashboard -> kubeRBACProxy "Manages TrustyAI via UI"

        trustyaiService -> mariaDB "Stores inference data (MySQL/3306, TLS optional)"
        trustyaiService -> pvc "Stores inference data (HDF5 filesystem)"

        trustyaiOperator -> trustyaiService "Deploys and configures instances" "Kubernetes API"
        platformAdmin -> trustyaiOperator "Configures TrustyAI deployments"
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
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Sidecar" {
                background #d79b00
            }
            element "Infrastructure" {
                background #f5a623
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
        }
    }
}
