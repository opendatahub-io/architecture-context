workspace {
    model {
        telemetrySource = person "Telemetry Source" "Sends request telemetry data for model training"
        inferenceGateway = person "llm-d Inference Gateway" "Consumes latency predictions for routing decisions"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "Latency prediction and training service providing TTFT and TPOT estimates via ML models" {
            trainingServer = container "Training Server" "Ingests telemetry data, trains XGBoost and LightGBM models, serves model artifacts" "Python FastAPI :8000" {
                trainingAPI = component "Training API" "FastAPI endpoints for data ingestion, model management, and metrics" "FastAPI/Uvicorn"
                modelTrainer = component "Model Trainer" "Trains XGBoost and LightGBM models for TTFT/TPOT prediction" "XGBoost, LightGBM"
                modelStorage = component "Model Storage" "Persists trained model artifacts to PVC" "joblib serialization"
            }
            predictionServer = container "Prediction Server" "Loads trained models and serves latency predictions" "Python FastAPI :8001" {
                predictionAPI = component "Prediction API" "FastAPI endpoints for single and bulk predictions" "FastAPI/Uvicorn"
                modelSyncer = component "ModelSyncer" "Background thread polling training server for model updates every 10s" "Python threading"
                ensembleEngine = component "Ensemble Engine" "Combines queue-gated sub-models for prediction accuracy" "XGBoost, LightGBM, BayesianRidge"
            }
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        telemetrySource -> latencyPredictor "Sends training data via POST /add_training_data_bulk" "HTTP/8000"
        inferenceGateway -> latencyPredictor "Requests latency predictions via POST /predict" "HTTP/80"
        latencyPredictor -> kubernetes "Health probes /healthz and /readyz" "HTTP"

        predictionServer -> trainingServer "Syncs trained models via HTTP GET /model/{name}/download" "HTTP/8000"
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
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
