workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        mlEngineer = person "ML Engineer" "Manages serving runtimes and model deployments"
        inferenceClient = person "Inference Client" "Sends prediction requests to deployed models"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes operator managing multi-model inference with ModelMesh" {
            controller = container "modelmesh-controller" "Reconciles ServingRuntime, Predictor, and Service resources; manages runtime deployments" "Go Operator (controller-runtime)"
            webhook = container "ServingRuntime Webhook" "Validates ServingRuntime and ClusterServingRuntime specs on CREATE/UPDATE" "Validating Admission Webhook"
            modelMesh = container "ModelMesh (mm)" "Core multi-model serving engine with gRPC inference, distributed model placement and routing" "Java Sidecar"
            restProxy = container "REST Proxy" "REST-to-gRPC adapter exposing HTTP KServe V2 inference API" "Go Sidecar"
            puller = container "Puller" "Model artifact fetcher/cacher downloading from S3, GCS, Azure, PVC, HTTP(S)" "Go Sidecar"
            oauthProxy = container "OAuth Proxy" "OpenShift OAuth proxy for REST inference endpoint authentication" "Sidecar"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for model registry, placement state, and inter-pod coordination" "External"
        kserve = softwareSystem "KServe" "InferenceService CRD definitions and serving runtime API types" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact storage (AWS S3, MinIO, Ceph)" "External"
        gcsStorage = softwareSystem "GCS Storage" "Google Cloud Storage for model artifacts" "External"
        azureStorage = softwareSystem "Azure Blob Storage" "Azure Blob storage for model artifacts" "External"
        openShiftOAuth = softwareSystem "OpenShift OAuth" "OpenShift delegated authentication for REST inference endpoints" "External"
        prometheusOperator = softwareSystem "Prometheus Operator" "Metrics collection via ServiceMonitor CRD" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD watches, resource CRUD, leader election" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects and model serving" "Internal RHOAI"
        odhModelController = softwareSystem "ODH Model Controller" "Webhook interceptor for InferenceService resources" "Internal RHOAI"

        # User interactions
        dataScientist -> modelmeshServing "Creates Predictor/InferenceService via kubectl/API" "HTTPS/443"
        mlEngineer -> modelmeshServing "Manages ServingRuntime and ClusterServingRuntime resources" "HTTPS/443"
        inferenceClient -> modelmeshServing "Sends inference requests" "gRPC/8033, HTTPS/8443"

        # Internal container interactions
        controller -> modelMesh "SetVModel, GetVModelStatus, DeleteVModel" "gRPC/8033"
        controller -> webhook "Registers webhook" "HTTPS/9443"
        restProxy -> modelMesh "Forwards REST requests as gRPC" "gRPC/8033"
        oauthProxy -> restProxy "Proxies authenticated requests" "HTTP/8008"
        modelMesh -> puller "Triggers model fetch" "gRPC/8086"

        # External dependencies
        modelmeshServing -> etcd "Model registry state, placement coordination, event streaming" "gRPC/2379"
        modelmeshServing -> kserve "CRD type definitions (ServingRuntime, Predictor, InferenceService)" "Kubernetes API"
        modelmeshServing -> s3Storage "Downloads model artifacts" "HTTPS/443"
        modelmeshServing -> gcsStorage "Downloads model artifacts" "HTTPS/443"
        modelmeshServing -> azureStorage "Downloads model artifacts" "HTTPS/443"
        modelmeshServing -> openShiftOAuth "Delegates REST endpoint authentication" "HTTPS"
        modelmeshServing -> prometheusOperator "Creates ServiceMonitor for metrics scraping" "Kubernetes API"
        modelmeshServing -> kubernetesAPI "CRD watches, resource CRUD, leader election" "HTTPS/443"

        # Integration points
        odhDashboard -> modelmeshServing "UI management of model serving" "Kubernetes API"
        odhModelController -> modelmeshServing "Webhook interception on InferenceService resources" "Kubernetes API"
        etcd -> modelmeshServing "Model state change events (Watch stream)" "gRPC/2379"
    }

    views {
        systemContext modelmeshServing "SystemContext" {
            include *
            autoLayout
        }

        container modelmeshServing "Containers" {
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
