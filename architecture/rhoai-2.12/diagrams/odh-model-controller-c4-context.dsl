workspace {
    model {
        datascientist = person "Data Scientist" "Creates and deploys ML inference services using KServe"

        odhModelController = softwareSystem "ODH Model Controller" "Extends KServe InferenceService with OpenShift and service mesh integration" {
            mainReconciler = container "InferenceService Reconciler" "Main controller reconciling InferenceServices" "Go Operator" {
                modelmeshReconciler = component "ModelMesh Reconciler" "Handles multi-model serving mode"
                serverlessReconciler = component "Serverless Reconciler" "Handles Knative-based serverless mode"
                rawReconciler = component "Raw Reconciler" "Handles direct Kubernetes deployment mode"
            }

            resourceReconcilers = container "Resource Reconcilers" "Manages supporting resources" "Go Controllers" {
                storageReconciler = component "Storage Secret Reconciler" "Manages storage configuration secrets"
                caReconciler = component "CA Cert Reconciler" "Manages custom CA certificates"
                monitoringReconciler = component "Monitoring Reconciler" "Creates ServiceMonitors and PodMonitors"
            }

            meshReconcilers = container "Service Mesh Reconcilers" "Manages Istio/Maistra integration" "Go Sub-reconcilers" {
                routeReconciler = component "Route Reconciler" "Creates OpenShift Routes"
                vsReconciler = component "VirtualService Reconciler" "Manages Istio VirtualServices"
                gatewayReconciler = component "Gateway Reconciler" "Configures Istio Gateways"
                authReconciler = component "AuthConfig Reconciler" "Manages Authorino authentication"
                peerAuthReconciler = component "PeerAuth Reconciler" "Configures mTLS policies"
                telemetryReconciler = component "Telemetry Reconciler" "Configures telemetry collection"
            }

            webhook = container "Knative Service Validator" "Validates Knative Services for mesh compatibility" "Webhook Server"
        }

        kserve = softwareSystem "KServe" "Serverless ML inference platform" "External"
        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        openshift = softwareSystem "OpenShift" "Enterprise Kubernetes with Routes API" "External"
        istio = softwareSystem "Istio / Maistra" "Service mesh for traffic management and mTLS" "External"
        knative = softwareSystem "Knative Serving" "Serverless autoscaling and revision management" "External"
        authorino = softwareSystem "Authorino" "Kubernetes-native authorization service" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        modelRegistry = softwareSystem "Model Registry" "ML model metadata and versioning" "Internal ODH"
        odhOperator = softwareSystem "ODH Operator" "Platform-wide configuration and component management" "Internal ODH"
        certManager = softwareSystem "cert-manager / service-ca" "Certificate management for webhooks" "External"

        # User interactions
        datascientist -> odhModelController "Creates InferenceService CRs via kubectl/oc"
        datascientist -> kserve "Creates InferenceService CRs"

        # Controller interactions with external dependencies
        odhModelController -> kubernetes "Watches and manages CRDs (InferenceServices, Secrets, ConfigMaps)" "HTTPS/6443, ServiceAccount Token"
        odhModelController -> openshift "Creates and manages Routes for external access" "HTTPS/6443, ServiceAccount Token"
        odhModelController -> istio "Manages VirtualServices, Gateways, PeerAuthentication, Telemetry" "gRPC/15012 mTLS, HTTPS/6443"
        odhModelController -> authorino "Creates and manages AuthConfigs for authentication" "HTTPS/6443, ServiceAccount Token"
        odhModelController -> prometheus "Exposes metrics, creates ServiceMonitors" "HTTP/8080, Bearer Token"
        odhModelController -> modelRegistry "Optional model metadata integration" "HTTP/8080, ServiceAccount Token"
        odhModelController -> odhOperator "Reads DataScienceCluster and DSCInitialization config" "HTTPS/6443, ServiceAccount Token"
        odhModelController -> certManager "Uses TLS certificates for webhook server" "service-ca-operator"

        # Controller works alongside KServe
        odhModelController -> kserve "Watches same InferenceService resources, extends behavior" "Event Stream"
        kserve -> kubernetes "Creates Knative Services, Deployments for inference"

        # Knative validation
        kubernetes -> webhook "Validates Knative Service resources when created" "HTTPS/443 (webhook), TLS"

        # Service mesh and autoscaling
        istio -> kubernetes "Configures Envoy sidecars, enforces mTLS policies"
        knative -> kubernetes "Manages serverless autoscaling and revisions"

        # Prometheus monitoring
        prometheus -> odhModelController "Scrapes controller metrics" "HTTPS/8080, Bearer Token"
        prometheus -> kubernetes "Discovers ServiceMonitor targets"
    }

    views {
        systemContext odhModelController "SystemContext" {
            include *
            autoLayout
        }

        container odhModelController "Containers" {
            include *
            autoLayout
        }

        component mainReconciler "MainReconcilerComponents" {
            include *
            autoLayout
        }

        component meshReconcilers "MeshReconcilerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #5da5e8
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }

        theme default
    }
}
