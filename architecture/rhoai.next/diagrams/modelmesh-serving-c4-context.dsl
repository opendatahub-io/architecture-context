workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and deploys ML models for inference"
        platformAdmin = person "Platform Admin" "Manages serving runtimes and cluster configuration"

        modelmeshServing = softwareSystem "ModelMesh Serving" "Kubernetes controller managing ModelMesh model serving deployments, routing, and lifecycle" {
            controller = container "modelmesh-serving-controller" "Manages ModelMesh serving deployments, services, and model lifecycle via gRPC to ModelMesh" "Go Operator (controller-runtime)"
            webhook = container "ServingRuntime Webhook" "Validates ServingRuntime and ClusterServingRuntime specs for autoscaler configuration" "Validating Admission Webhook"
            modelmeshSidecar = container "ModelMesh Sidecar" "Model orchestration, routing, placement, and inference serving" "gRPC Service (injected sidecar)"
            restProxy = container "REST Proxy" "REST-to-gRPC translation for KServe V2 REST Predict Protocol" "HTTP Reverse Proxy (injected sidecar)"
            oauthProxy = container "oauth-proxy" "OpenShift OAuth proxy for RBAC-based inference authentication" "HTTPS Sidecar"
            pullerSidecar = container "Puller Sidecar" "Downloads model artifacts from storage backends" "modelmesh-runtime-adapter"
        }

        etcd = softwareSystem "etcd" "Distributed key-value store for ModelMesh inter-pod coordination and model placement" "External"
        k8s = softwareSystem "Kubernetes API Server" "Cluster API for managing resources" "External"
        objectStorage = softwareSystem "Object Storage (S3/GCS)" "Model artifact storage" "External"
        prometheusOp = softwareSystem "Prometheus Operator" "Monitoring and metrics collection" "External"
        openshiftServiceCA = softwareSystem "OpenShift service-ca" "Automatic TLS certificate provisioning" "Internal Platform"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "OAuth identity provider for SAR-based auth" "Internal Platform"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook" "External"

        # User interactions
        dataScientist -> modelmeshServing "Creates Predictor/InferenceService CRs via kubectl" "HTTPS"
        platformAdmin -> modelmeshServing "Creates ServingRuntime/ClusterServingRuntime CRs" "HTTPS"

        # Internal container relationships
        controller -> modelmeshSidecar "Registers/updates/deletes virtual models" "gRPC/8033 Optional TLS"
        controller -> webhook "Webhook validation" "HTTPS/9443"
        oauthProxy -> restProxy "Proxies authenticated requests" "HTTP/8008 localhost"
        restProxy -> modelmeshSidecar "Translates REST to gRPC" "gRPC/8033"
        modelmeshSidecar -> pullerSidecar "Requests model downloads" "gRPC/8086 pod-local"

        # External dependencies
        controller -> k8s "Watches CRDs, manages Deployments, Services, Secrets" "HTTPS/443 Bearer Token"
        controller -> etcd "Model placement coordination (via ModelMesh)" "gRPC/2379 TLS"
        modelmeshSidecar -> etcd "Distributed coordination and event streaming" "gRPC/2379 TLS Client Cert"
        pullerSidecar -> objectStorage "Downloads model artifacts" "HTTPS/443 Storage Credentials"
        oauthProxy -> openshiftOAuth "Validates SAR tokens" "HTTPS"
        openshiftServiceCA -> oauthProxy "Provisions TLS serving cert" "Annotation-triggered"
        certManager -> webhook "Provisions webhook TLS cert" "Certificate CR"
        prometheusOp -> modelmeshSidecar "Scrapes metrics via ServiceMonitor" "HTTP/2112"
        k8s -> webhook "Sends admission reviews" "HTTPS/9443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
        }
    }
}
