workspace {
    model {
        dataScientist = person "Data Scientist" "Uses notebooks and scripts to analyze ML model fairness and explainability"

        trustyaiPython = softwareSystem "trustyai-explainability-python" "Python client library providing explainability (LIME, SHAP, PDP, Counterfactual), fairness metrics, and model-trust tooling via JPype JVM bridge" {
            trustyaiPackage = container "trustyai Package" "Python bindings to TrustyAI explainability library" "Python 3.8+ / pip"
            jpypeBridge = container "JPype JVM Bridge" "Embeds Java Virtual Machine to access TrustyAI Java explainability engine" "JPype1 1.5.0"
            metricsServiceClient = container "TrustyAIMetricsService" "HTTP client for TrustyAI Service and Thanos Querier interactions" "Python requests"
            trustyaiApi = container "TrustyAIApi" "OpenShift Route discovery via Kubernetes Python dynamic client" "kubernetes Python SDK"
            explainers = container "Explainers" "LIME, SHAP, PDP, Counterfactual explainability algorithms" "Python + Java"
            metricsModule = container "Metrics" "Fairness and distance metrics computation" "Python + Java"
            localModule = container "Local Module" "Language toxicity detection, HuggingFace/local model loading" "Python"
        }

        trustyaiService = softwareSystem "TrustyAI Service" "Server-side fairness metrics scheduling, data management, and model info" "Internal RHOAI"
        thanosQuerier = softwareSystem "Thanos Querier" "Prometheus-compatible metrics query endpoint for time-series data" "Internal OpenShift"
        modelEndpoints = softwareSystem "Model Inference Endpoints" "Deployed ML model serving endpoints (KServe / ModelMesh)" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for resource discovery and management" "Internal OpenShift"
        jupyterNotebook = softwareSystem "JupyterLab Notebook" "Interactive development environment where library is consumed" "Internal RHOAI"

        dataScientist -> jupyterNotebook "Writes and runs analysis code"
        jupyterNotebook -> trustyaiPython "import trustyai (pip install)"
        dataScientist -> trustyaiPython "Calls explainability and fairness APIs"

        trustyaiPackage -> jpypeBridge "Initializes JVM, loads explainability JAR"
        jpypeBridge -> explainers "Provides Java class access"
        jpypeBridge -> metricsModule "Provides Java class access"
        metricsServiceClient -> trustyaiApi "Discovers OpenShift Routes"

        trustyaiPython -> trustyaiService "POST /data/upload, GET /info, POST /metrics/{metric}" "HTTPS/443, Bearer Token"
        trustyaiPython -> thanosQuerier "GET /api/v1/query (PromQL)" "HTTPS/443, Bearer Token"
        trustyaiPython -> modelEndpoints "POST /infer" "HTTPS/443, Bearer Token"
        trustyaiPython -> kubernetesAPI "Route discovery (v1/Route)" "HTTPS/443, SA Token"
    }

    views {
        systemContext trustyaiPython "SystemContext" {
            include *
            autoLayout
        }

        container trustyaiPython "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Internal OpenShift" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
