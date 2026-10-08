workspace {
    model {
        dataScientist = person "Data Scientist" "Creates FeatureStore CRs, uses features in ML workloads"
        mlApp = person "ML Application" "Consumes online features for inference"

        feast = softwareSystem "Feast" "Feature store operator and serving platform for ML feature management on Kubernetes" {
            operator = container "Feast Operator" "Reconciles FeatureStore CRs, manages lifecycle of feature store deployments, RBAC, TLS, scaling" "Go Operator (controller-runtime)"
            featureServerPython = container "Feature Server (Python)" "Serves online features via REST/gRPC, manages registry, monitoring, lineage" "Python (FastAPI/uvicorn/gunicorn)"
            featureServerGo = container "Feature Server (Go)" "Lightweight online feature serving via HTTP and gRPC" "Go Service"
            notebookReconciler = container "NotebookConfigMap Reconciler" "Injects feature store client config into Kubeflow notebooks" "Go Controller"
            feastUI = container "Feast UI" "Web interface for feature store exploration" "React"
            materializationCronJob = container "Materialization CronJob" "Scheduled feature materialization from offline to online store" "CronJob (ose-cli)"
        }

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        redis = softwareSystem "Redis / Valkey" "In-memory data store for online feature serving" "External"
        postgresql = softwareSystem "PostgreSQL" "Relational database for online/offline feature storage" "External"
        s3 = softwareSystem "S3-compatible Storage" "Object storage for registry and offline feature data" "External"
        gcs = softwareSystem "Google Cloud Storage" "Object storage for registry and offline feature data" "External"
        kubeflowNotebooks = softwareSystem "Kubeflow Notebooks" "Interactive notebook workbenches for data scientists" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model registry" "Internal RHOAI"
        prometheusOperator = softwareSystem "prometheus-operator" "Manages Prometheus monitoring and ServiceMonitors" "Internal RHOAI"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external access via Routes" "External"
        sparkOperator = softwareSystem "Spark Operator" "Manages SparkApplications for distributed processing" "External"
        openshiftApiserver = softwareSystem "OpenShift APIServer Config" "Cluster TLS profile and security policy configuration" "External"

        dataScientist -> feast "Creates FeatureStore CRs via kubectl/UI"
        mlApp -> feast "Retrieves online features" "HTTP/HTTPS/gRPC on port 6566"
        feast -> k8sApi "Manages resources (deployments, services, RBAC)" "HTTPS/6443"
        feast -> redis "Reads/writes online features" "TCP (configurable)"
        feast -> postgresql "Reads/writes online/offline features" "TCP (configurable)"
        feast -> s3 "Stores/retrieves registry and offline data" "HTTPS/443"
        feast -> gcs "Stores/retrieves registry and offline data" "HTTPS/443"
        feast -> kubeflowNotebooks "Watches Notebook CRs, injects client config" "Kubernetes API"
        feast -> mlflow "Watches MLflow CRs for experiment tracking" "Kubernetes API"
        feast -> prometheusOperator "Creates ServiceMonitor resources" "Kubernetes API"
        feast -> openshiftRouter "Creates Routes for external access" "Kubernetes API"
        feast -> sparkOperator "Creates SparkApplications for materialization" "Kubernetes API"
        feast -> openshiftApiserver "Reads TLS profile for cipher configuration" "HTTPS/6443"
    }

    views {
        systemContext feast "SystemContext" {
            include *
            autoLayout
        }

        container feast "Containers" {
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
