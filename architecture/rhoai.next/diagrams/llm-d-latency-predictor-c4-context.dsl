workspace {
    model {
        routingLayer = person "llm-d Routing Layer" "Intelligent LLM request routing component that schedules inference requests across pods based on latency predictions"

        latencyPredictor = softwareSystem "llm-d Latency Predictor" "Online ML service that predicts LLM inference latencies (TTFT and TPOT) for routing decisions" {
            predictionServer = container "Prediction Server" "Serves real-time TTFT/TPOT latency predictions via REST API. Scales horizontally (10 replicas). Each worker syncs models independently." "Python FastAPI/Uvicorn, 8001/TCP"
            trainingServer = container "Training Server" "Ingests telemetry, continuously retrains regression models (XGBoost/LightGBM/BayesianRidge). Single replica with persistent storage." "Python FastAPI/Uvicorn, 8000/TCP"
            commonLib = container "Common Library" "Shared types (ModelType, ObjectiveType), data structures (QueueGatedModel, RandomDropDeque)" "Python Library"
            modelStorage = container "Model Storage" "Persistent volume for trained model artifacts (joblib files)" "PVC /models/"
        }

        prometheus = softwareSystem "Prometheus" "Monitoring system that scrapes metrics" "External"

        # Relationships - external
        routingLayer -> predictionServer "Requests latency predictions" "HTTP POST /predict/bulk/strict, 80/TCP"
        routingLayer -> trainingServer "Pushes request telemetry samples" "HTTP POST /add_training_data_bulk, 8000/TCP"
        prometheus -> trainingServer "Scrapes metrics" "HTTP GET /metrics, 8000/TCP"

        # Relationships - internal
        predictionServer -> trainingServer "Downloads trained model files" "HTTP GET /model/{name}/download, 8000/TCP"
        trainingServer -> modelStorage "Saves trained models" "Filesystem (joblib)"
        predictionServer -> commonLib "Uses shared types and enums"
        trainingServer -> commonLib "Uses shared types and enums"
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
                background #4a90e2
                color #ffffff
                shape RoundedBox
            }
            element "Container" {
                background #357abd
                color #ffffff
            }
            element "Person" {
                background #7ed321
                color #ffffff
                shape Person
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }
}
