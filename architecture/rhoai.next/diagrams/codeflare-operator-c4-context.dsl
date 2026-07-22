workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages distributed Ray workloads and ML training jobs"
        platformAdmin = person "Platform Admin" "Configures RHOAI platform and manages cluster resources"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages RayCluster OAuth/mTLS security, network isolation, and AppWrapper job queuing for distributed workloads" {
            manager = container "Manager Process" "controller-runtime based operator process" "Go"
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs: creates OAuth proxy routes, CA certificates, network policies" "Go Controller"
            rayClusterWebhook = container "RayCluster Webhook" "Injects OAuth proxy sidecar and mTLS init containers into RayCluster pods" "Mutating/Validating Webhook"
            appWrapperController = container "AppWrapper Controller" "Manages AppWrapper CRs for Kueue-integrated job queuing (conditionally enabled)" "Go Controller"
            appWrapperWebhook = container "AppWrapper Webhook" "Validates AppWrapper resources with SubjectAccessReview authorization" "Mutating/Validating Webhook"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Creates and manages RayCluster pods and services" "External"
        opendatahubOperator = softwareSystem "OpenDataHub Operator" "Manages RHOAI platform components and DSCInitialization" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Provides OAuth authentication for cluster users" "External"
        openshiftRouter = softwareSystem "OpenShift Router" "Ingress controller for external traffic routing via Routes" "External"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring stack" "External"
        kueue = softwareSystem "Kueue" "Kubernetes-native job queuing system for quota management" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for resource management" "External"
        trainingOperator = softwareSystem "Training Operator" "Manages PyTorchJob and other training workloads" "External"

        # Relationships - Users
        dataScientist -> codeflareOperator "Creates RayCluster and AppWrapper CRs via kubectl/SDK"
        platformAdmin -> opendatahubOperator "Configures RHOAI platform"

        # Relationships - Operator to external
        codeflareOperator -> kuberayOperator "Discovers namespace, watches RayClusters created by KubeRay"
        codeflareOperator -> opendatahubOperator "Reads DSCInitialization CR for applications namespace" "Kubernetes API"
        codeflareOperator -> openshiftOAuth "Configures OAuth redirect for per-cluster dashboard authentication" "HTTPS/443"
        codeflareOperator -> openshiftRouter "Creates Routes for dashboard (reencrypt) and client (passthrough) access" "HTTPS/443"
        codeflareOperator -> kueue "Integrates AppWrappers with Kueue for quota management" "Kubernetes API"
        codeflareOperator -> kubernetesAPI "CRUD for Secrets, Services, NetworkPolicies, ServiceAccounts, RBAC" "HTTPS/443"
        codeflareOperator -> trainingOperator "Manages PyTorchJob resources wrapped in AppWrappers" "Kubernetes API"

        # Relationships - External to operator
        kubernetesAPI -> codeflareOperator "Calls admission webhooks on RayCluster/AppWrapper create/update" "HTTPS/9443"
        openshiftMonitoring -> codeflareOperator "Scrapes operator metrics via ServiceMonitor" "HTTP/8080"

        # Internal container relationships
        manager -> rayClusterController "Starts and manages"
        manager -> rayClusterWebhook "Registers and serves"
        manager -> appWrapperController "Conditionally starts"
        manager -> appWrapperWebhook "Conditionally registers"
        rayClusterController -> rayClusterWebhook "Controller creates infrastructure, webhook injects sidecars"
    }

    views {
        systemContext codeflareOperator "SystemContext" {
            include *
            autoLayout
        }

        container codeflareOperator "Containers" {
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
                shape person
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
