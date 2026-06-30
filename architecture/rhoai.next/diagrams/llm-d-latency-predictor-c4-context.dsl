workspace {
    model {
        dataScientist = person "Data Scientist" "Deploys LLM models and monitors inference performance"
        sre = person "SRE / Platform Engineer" "Monitors and operates the inference platform"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "ML-based latency prediction service for TTFT/TPOT in LLM inference workloads" {
            trainingServer = container "Training Server" "Collects latency observations, trains quantile/mean regression models (XGBoost/LightGBM/BayesianRidge), serves trained models for download" "Python FastAPI 8000/TCP"
            predictionServer = container "Prediction Server" "Serves low-latency TTFT/TPOT predictions using synced ML models, 10 replicas with 8 workers each" "Python FastAPI 8001/TCP"

            predictionServer -> trainingServer "Downloads trained models" "HTTP/8000 (every 10s)"
        }

        llmdGateway = softwareSystem "llm-d Gateway" "Gateway API inference extension for intelligent LLM request routing" "Internal llm-d"
        llmdMetrics = softwareSystem "llm-d Metrics Pipeline" "Collects and forwards actual latency observations from LLM inference" "Internal llm-d"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        llmdMetrics -> latencyPredictor "Sends latency observations" "HTTP POST /add_training_data_bulk 8000/TCP"
        llmdGateway -> latencyPredictor "Requests TTFT/TPOT predictions for routing" "HTTP POST /predict/bulk/strict 8001/TCP"
        kubernetes -> latencyPredictor "Health and readiness probes" "HTTP GET /healthz, /readyz"
        prometheus -> latencyPredictor "Scrapes metrics" "HTTP GET /metrics 8000/TCP"
        sre -> prometheus "Monitors system health"
    }

    views {
        systemContext latencyPredictor "SystemContext" {
            include *
            autoLayout
        }

        container latencyPredictor "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
        }
    }
}
