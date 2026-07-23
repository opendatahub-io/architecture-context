workspace {
    model {
        llmdRouter = person "llm-d Inference Router" "Routes LLM inference requests based on predicted latency"
        llmdPods = person "llm-d Inference Pods" "Generate request traces during inference serving"
        sre = person "SRE / Platform Operator" "Monitors and operates the latency prediction service"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "ML-based TTFT/TPOT latency prediction service for intelligent LLM inference routing" {
            predictionServer = container "Prediction Server" "Serves low-latency TTFT/TPOT predictions via REST API. Horizontally scaled (10 replicas, 8 workers each). Gated ensemble routing (noqueue vs queued sub-models)." "Python FastAPI / uvicorn" "Service"
            trainingServer = container "Training Server" "Singleton service that ingests request traces, trains online ML models (XGBoost/LightGBM/Bayesian Ridge), and serves trained model artifacts." "Python FastAPI / uvicorn" "Service"
            modelStorage = container "Model Storage" "Persistent volume for serialized ML model files (joblib format)" "PVC (hyperdisk-balanced)" "Storage"
        }

        gatewayAPIExt = softwareSystem "Gateway API Inference Extension" "Kubernetes Gateway API extension for intelligent inference routing" "Internal llm-d"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "Platform"
        kubernetes = softwareSystem "Kubernetes API" "Container orchestration platform" "Platform"

        # Relationships
        llmdRouter -> latencyPredictor "Requests TTFT/TPOT predictions" "HTTP/80 POST /predict, /predict/bulk/strict"
        llmdPods -> latencyPredictor "Submits request trace data" "HTTP/8000 POST /add_training_data_bulk"
        sre -> latencyPredictor "Monitors via /metrics and /status"

        # Internal relationships
        predictionServer -> trainingServer "Syncs trained models every 10s" "HTTP/8000 GET /model/.../download"
        trainingServer -> modelStorage "Persists trained model files" "File I/O (joblib)"
        predictionServer -> predictionServer "Gated ensemble prediction" "In-process"

        # External relationships
        latencyPredictor -> gatewayAPIExt "Feeds predictions into routing decisions"
        prometheus -> latencyPredictor "Scrapes metrics" "HTTP/8000 GET /metrics"
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
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Storage" {
                background #f5a623
                color #000000
                shape Cylinder
            }
            element "Service" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Platform" {
                background #999999
                color #ffffff
            }
        }
    }
}
