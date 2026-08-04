workspace {
    model {
        llmdGateway = person "llm-d Gateway / Scheduler" "Sends telemetry data and consumes latency predictions for routing decisions"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "Online ML-based TTFT and TPOT latency prediction system for llm-d inference gateway" {
            trainingServer = container "Training Server" "Ingests live telemetry data and continuously retrains regression models (XGBoost, LightGBM, Bayesian Ridge)" "Python/FastAPI, uvicorn :8000" {
                dataIngestion = component "Data Ingestion" "POST /add_training_data_bulk - accumulates telemetry samples" "FastAPI Route"
                modelTrainer = component "Model Trainer" "Background thread that periodically retrains ensemble models" "Python Thread"
                modelExportAPI = component "Model Export API" "GET /model/{name}/info, /model/{name}/download - serves model artifacts" "FastAPI Route"
                metricsEndpoint = component "Metrics" "GET /metrics - Prometheus metrics" "FastAPI Route"
            }

            predictionServer = container "Prediction Server" "Serves sub-millisecond latency predictions using locally cached models" "Python/FastAPI, uvicorn :8001, multi-worker" {
                modelSyncer = component "ModelSyncer" "Background thread polling training server every 10s for model updates" "Python Thread"
                predictAPI = component "Predict API" "POST /predict, /predict/bulk, /predict/bulk/strict" "FastAPI Route"
                localModelCache = component "Local Model Cache" "Model files at /local_models/ with atomic-rename writes" "Filesystem"
            }
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        llmdGateway -> latencyPredictor "Sends telemetry, requests predictions" "HTTP/8000, HTTP/8001"
        llmdGateway -> trainingServer "POST /add_training_data_bulk" "HTTP/8000, no auth"
        llmdGateway -> predictionServer "POST /predict, /predict/bulk" "HTTP/8001, no auth"

        predictionServer -> trainingServer "Downloads trained models" "HTTP/8000, polling every 10s, no auth"
        modelSyncer -> modelExportAPI "GET /model/{name}/info, /download" "HTTP/8000, retry on 502/503/504"
        dataIngestion -> modelTrainer "Accumulated samples trigger retrain"
        modelSyncer -> localModelCache "Writes model files (atomic rename)"
        localModelCache -> predictAPI "Loads models for prediction"

        kubernetes -> trainingServer "Health probes" "HTTP GET /healthz /readyz :8000"
        kubernetes -> predictionServer "Health probes" "HTTP GET /healthz /readyz :8001"
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

        component trainingServer "TrainingServerComponents" {
            include *
            autoLayout
        }

        component predictionServer "PredictionServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #7ed321
                color #ffffff
            }
            element "Component" {
                background #f5a623
                color #333333
            }
        }
    }
}
