workspace {
    model {
        user = person "Data Scientist" "Creates and manages ML model deployments for inference"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe with OpenShift integration, service mesh, authentication, monitoring, and automated resource management" {
            reconcilers = container "Reconcilers" "Manages InferenceService, InferenceGraph, LLMInferenceService, NIM Account, ServingRuntime, ConfigMap, Secret, Pod resources" "Go (Kubebuilder v4)"
            webhooks = container "Admission Webhooks" "Validates and mutates InferenceService, InferenceGraph, NIM Account, Pod, Knative Service resources" "Go (HTTPS/TLS)"
            metrics = container "Metrics Server" "Exposes Prometheus metrics" "HTTP 8080"
            health = container "Health Probes" "Liveness and readiness endpoints" "HTTP 8081"
        }

        kserve = softwareSystem "KServe" "Core model serving platform for serverless and raw deployment modes" "External"
        istio = softwareSystem "Istio/Maistra Service Mesh" "Provides mTLS, traffic routing, and telemetry for inference workloads" "External"
        openshift = softwareSystem "OpenShift" "Provides Route API, Template processing, and platform integration" "External"
        authorino = softwareSystem "Authorino" "Authentication and authorization for inference endpoints" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        keda = softwareSystem "KEDA" "Event-driven autoscaling for inference workloads" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhooks" "External"
        ngc = softwareSystem "NVIDIA NGC" "NVIDIA Inference Microservices (NIM) model catalog and registry" "External Cloud Service"
        modelRegistry = softwareSystem "Model Registry" "Stores and tracks model metadata" "Internal ODH"
        dsc = softwareSystem "DataScienceCluster" "ODH platform configuration and component management" "Internal ODH"
        s3 = softwareSystem "S3 Storage" "Model artifact storage" "External Cloud Service"
        k8s = softwareSystem "Kubernetes API" "Cluster control plane for resource management" "Platform"

        # User interactions
        user -> odhModelController "Creates InferenceService, InferenceGraph, LLMInferenceService, NIM Account via kubectl/UI"
        user -> k8s "Submits CRs and manages resources"

        # ODH Model Controller interactions
        odhModelController -> k8s "Watches/creates Routes, VirtualServices, Gateways, PeerAuthentication, AuthConfigs, ServiceMonitors, NetworkPolicies, RBAC" "HTTPS/6443"
        odhModelController -> kserve "Coordinates InferenceService reconciliation"
        odhModelController -> istio "Creates service mesh configurations" "CRD Management"
        odhModelController -> openshift "Creates Routes for external access" "HTTPS/6443"
        odhModelController -> authorino "Creates AuthConfig resources for endpoint authentication" "CRD Management"
        odhModelController -> prometheus "Exposes controller and inference metrics" "HTTP/8080"
        odhModelController -> keda "Creates TriggerAuthentication for autoscaling" "CRD Management"
        odhModelController -> ngc "Validates NIM accounts, fetches model catalog" "HTTPS/443"
        odhModelController -> modelRegistry "Registers InferenceService metadata (optional)" "HTTPS/443"
        odhModelController -> dsc "Reads platform configuration for component enablement" "Watch CRDs"

        # External system interactions
        kserve -> k8s "Creates Knative Services or K8s Deployments for model serving" "HTTPS/6443"
        istio -> k8s "Manages service mesh data plane" "CRD Watch"
        certManager -> k8s "Provisions TLS certificates" "HTTPS/6443"
        prometheus -> odhModelController "Scrapes metrics" "HTTP/8080"

        # Inference workload interactions
        user -> openshift "Sends inference requests" "HTTPS/443"
        openshift -> istio "Routes traffic to service mesh" "HTTP/8080"
        istio -> authorino "Validates authentication (if enabled)" "gRPC/5001"
        istio -> kserve "Routes to predictor pods" "HTTP/8080"
        kserve -> s3 "Loads model artifacts" "HTTPS/443"
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autoLayout lr
        }

        container odhModelController "Containers" {
            include *
            autoLayout tb
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "External Cloud Service" {
                background #f5a623
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }

        theme default
    }

    configuration {
        scope softwaresystem
    }
}
