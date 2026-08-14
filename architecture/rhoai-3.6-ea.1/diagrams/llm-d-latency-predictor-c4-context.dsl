workspace {
    model {
        llmdGateway = person "llm-d Inference Gateway" "Sends observed TTFT/TPOT latency samples and consumes latency predictions for routing decisions"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "ML-based latency prediction service that trains and serves TTFT/TPOT models using XGBoost, LightGBM, and Bayesian Ridge" {
            trainingServer = container "Training Server" "Ingests latency samples, retrains ML models (XGBoost/LightGBM/BayesianRidge) every 1800s, exports serialized model artifacts" "Python FastAPI (uvicorn :8000), 1 replica" {
                dataAccumulator = component "Data Accumulator" "In-memory sample storage with per-bucket limits (500 samples)" "Python"
                modelTrainer = component "Model Trainer" "Trains XGBoost, LightGBM, BayesianRidge for TTFT and TPOT" "Python (scikit-learn, xgboost, lightgbm)"
                modelExporter = component "Model Exporter" "Serializes trained models via joblib with SHA-256 checksums" "Python (joblib)"
            }

            predictionServer = container "Prediction Server" "Polls training server for updated models, serves low-latency predictions via ensemble/queue-gated selection" "Python FastAPI (uvicorn :8001), 10 replicas" {
                modelSyncer = component "Model Syncer" "Periodically downloads model artifacts from training server (every 10s)" "Python (httpx)"
                predictionEngine = component "Prediction Engine" "Loads deserialized models and runs TTFT/TPOT inference" "Python (joblib, numpy)"
                ensembleSelector = component "Ensemble Selector" "Queue-gated model selection between no-queue and queued sub-models" "Python"
            }
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform providing deployment management, service discovery, and health probes" "External"

        llmdGateway -> latencyPredictor "Sends latency samples and requests predictions" "HTTP"
        latencyPredictor -> kubernetes "Deployed and managed by" "Kubernetes API"

        llmdGateway -> trainingServer "POST /add_training_data_bulk - observed latency samples" "HTTP/8000"
        llmdGateway -> predictionServer "POST /predict, /predict/bulk, /predict/bulk/strict" "HTTP/80→8001"
        predictionServer -> trainingServer "GET /model/export - download trained models (poll every 10s)" "HTTP/8000"
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
                background #50c878
                color #ffffff
            }
            element "Person" {
                background #f5a623
                color #ffffff
                shape Person
            }
        }
    }
}
