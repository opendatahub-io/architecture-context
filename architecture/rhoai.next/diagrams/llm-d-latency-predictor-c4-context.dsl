workspace {
    model {
        llmdEngine = person "llm-d Inference Engine" "Generates actual TTFT/TPOT latency observations from inference requests"
        llmdRouter = person "llm-d Routing Layer" "Routes inference requests using predicted latencies"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "Dual-server ML system that trains and serves online regression models predicting TTFT and TPOT for LLM inference requests" {
            trainingServer = container "Training Server" "Collects training data, trains XGBoost/LightGBM/BayesianRidge regression models, serves model files for download" "Python FastAPI 8000/TCP" {
                dataIngestion = component "Data Ingestion" "Receives and buckets training samples (400 buckets, RandomDropDeque)" "FastAPI endpoint"
                retrainLoop = component "Retrain Loop" "Periodically retrains models (30min interval, min 1000 samples)" "Background thread"
                ensembleTrainer = component "Ensemble Trainer" "Trains separate noqueue/queued sub-models via QueueGatedModel" "ML pipeline"
                modelFileServer = component "Model File Server" "Serves trained joblib files for download with metadata" "FastAPI endpoints"
                metricsExporter = component "Metrics Exporter" "Exposes Prometheus-style metrics on model coefficients and training state" "FastAPI endpoint"
            }
            predictionServer = container "Prediction Server" "Serves low-latency TTFT/TPOT predictions using periodically synced ML models; supports single and bulk (10k) predictions" "Python FastAPI 8001/TCP" {
                predictionAPI = component "Prediction API" "Handles /predict and /predict/bulk endpoints with numpy fast path" "FastAPI endpoints"
                modelSyncThread = component "Model Sync Thread" "Downloads models from training server every 10s with checksum-based cache invalidation" "Background thread"
                ensembleGate = component "Ensemble Gate" "Routes predictions to noqueue or queued sub-model based on queue depth" "ML routing"
            }
            commonTypes = container "common/types" "Shared data types: ModelType, ObjectiveType, QueueGatedModel, RandomDropDeque" "Python library"
            modelStorage = container "Model Storage" "Persistent storage for trained model files (*.joblib)" "PersistentVolumeClaim"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        llmdEngine -> latencyPredictor "Sends TTFT/TPOT observations" "HTTP/8000, No Auth"
        llmdRouter -> latencyPredictor "Requests TTFT/TPOT predictions" "HTTP/80, No Auth"

        latencyPredictor -> kubernetes "Deployed on" "Deployment, Service, PVC"

        # Internal flows
        llmdEngine -> trainingServer "POST /add_training_data_bulk" "HTTP/8000"
        llmdRouter -> predictionServer "POST /predict, /predict/bulk/strict" "HTTP/80 -> 8001"
        predictionServer -> trainingServer "GET /model/{name}/info, /download" "HTTP/8000"
        trainingServer -> modelStorage "Write trained models" "filesystem (joblib)"
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
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
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
        }
    }
}
