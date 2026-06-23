workspace {
    model {
        sre = person "SRE / Platform Admin" "Deploys and monitors the latency prediction system"
        datascientist = person "Data Scientist" "Deploys LLM models served by the inference stack"

        llmDLatencyPredictor = softwareSystem "llm-d Latency Predictor" "Online ML-based latency prediction for LLM inference requests (TTFT/TPOT)" {
            trainingServer = container "Training Server" "Continuously trains ML models (XGBoost/LightGBM/BayesianRidge) from observed latency traces and serves trained model files" "Python FastAPI 8000/TCP"
            predictionServer = container "Prediction Server" "Serves low-latency TTFT/TPOT predictions using synced ML models (10 replicas, 8 workers each)" "Python FastAPI 8001/TCP"
            testRunner = container "Test Runner" "Integration and load test harness (Kubernetes Job, non-production)" "Python pytest/httpx"
        }

        llmDGateway = softwareSystem "llm-d Gateway" "Inference gateway ecosystem for LLM request routing" {
            gatewayComponents = container "Gateway Components" "Submit observed latency traces to training server" "Gateway API Inference Extension"
            gatewayRouter = container "Gateway Router" "Queries latency predictions for routing decisions" "Gateway API Inference Extension"
        }

        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        rhoaiOperator = softwareSystem "RHOAI Operator (rhods-operator)" "Manages RHOAI component deployment and lifecycle" "Internal RHOAI"

        # Relationships
        gatewayComponents -> trainingServer "Submits observed TTFT/TPOT traces" "HTTP/8000 plaintext"
        gatewayRouter -> predictionServer "Queries predicted TTFT/TPOT" "HTTP/8001 plaintext"
        predictionServer -> trainingServer "Downloads trained model files (polling every 10s)" "HTTP/8000 plaintext"
        prometheus -> trainingServer "Scrapes /metrics" "HTTP/8000"
        rhoaiOperator -> llmDLatencyPredictor "Manages deployment lifecycle" "Kubernetes API"

        testRunner -> trainingServer "Submits test training data" "HTTP/8000"
        testRunner -> predictionServer "Validates prediction responses" "HTTP/8001"

        sre -> prometheus "Monitors model training metrics"
        datascientist -> llmDGateway "Deploys LLM models that generate inference traffic"
    }

    views {
        systemContext llmDLatencyPredictor "SystemContext" {
            include *
            autoLayout
        }

        container llmDLatencyPredictor "Containers" {
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
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #357abd
                color #ffffff
            }
        }
    }
}
