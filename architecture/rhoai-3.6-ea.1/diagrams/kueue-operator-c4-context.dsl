workspace {
    model {
        admin = person "Cluster Admin" "Configures Kueue queuing system and resource quotas"
        dataScientist = person "Data Scientist" "Submits ML training workloads with queue labels"

        kueueOperator = softwareSystem "Kueue Operator" "OpenShift operator managing the Kueue job-queuing system for workload admission control and resource quota enforcement" {
            operator = container "openshift-kueue-operator" "library-go static resource controller that reconciles the Kueue CR and manages operand lifecycle" "Go Operator" "Operator"
            controllerManager = container "kueue-controller-manager" "Upstream Kueue controller providing workload admission via ClusterQueues/LocalQueues with 35 admission webhooks" "Go Controller" "Controller"
            webhookServer = container "Webhook Server" "Serves 17 mutating and 18 validating admission webhooks on port 9443/TCP with TLS" "Go Service" "Webhook"
            visibilityAPI = container "Visibility API Server" "Exposes pending workload status as Kubernetes API aggregation endpoint on port 8082/TCP" "Go Service" "API"
            mustGather = container "must-gather" "Diagnostic data collection container" "Bash Script" "Diagnostics"
        }

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource CRUD operations" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate lifecycle management for webhook serving certificates" "External"
        prometheusOperator = softwareSystem "prometheus-operator" "Monitoring stack providing ServiceMonitor CRD for metrics collection" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        kubeflowTraining = softwareSystem "Kubeflow Training Operators" "ML training job operators (PyTorchJob, TFJob, MPIJob, PaddleJob, XGBoostJob)" "Internal RHOAI"
        rayOperator = softwareSystem "Ray Operator" "Manages RayCluster and RayJob resources" "Internal RHOAI"
        codeFlare = softwareSystem "CodeFlare" "AppWrapper workload management" "Internal RHOAI"

        # Relationships
        admin -> kueueOperator "Creates Kueue CR, ClusterQueues, ResourceFlavors via kubectl"
        dataScientist -> kubernetesAPI "Submits Jobs/PyTorchJobs/RayClusters with queue labels"

        operator -> kubernetesAPI "Watches Kueue CR, applies Deployments, RBAC, CRDs, Webhooks" "HTTPS/6443"
        operator -> certManager "Creates Certificate and Issuer CRs for webhook TLS" "Kubernetes API"
        operator -> prometheusOperator "Creates ServiceMonitors for metrics" "Kubernetes API"

        controllerManager -> kubernetesAPI "Watches/manages Workloads, ClusterQueues, LocalQueues, Jobs" "HTTPS+WSS/6443"
        controllerManager -> webhookServer "Embedded webhook serving"
        controllerManager -> visibilityAPI "Embedded visibility API"

        kubernetesAPI -> webhookServer "Routes admission requests for workload creation/updates" "HTTPS/443->9443"
        kubernetesAPI -> visibilityAPI "API aggregation for pending workload queries" "HTTPS/443->8082"

        prometheus -> controllerManager "Scrapes /metrics endpoint" "HTTPS/8443"

        controllerManager -> kubeflowTraining "Intercepts via webhooks, manages finalizers" "Admission Webhooks"
        controllerManager -> rayOperator "Intercepts via webhooks, manages finalizers" "Admission Webhooks"
        controllerManager -> codeFlare "Intercepts via webhooks, manages finalizers" "Admission Webhooks"

        operator -> controllerManager "Reconciles Deployment and configuration"
    }

    views {
        systemContext kueueOperator "SystemContext" {
            include *
            autoLayout
        }

        container kueueOperator "Containers" {
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
            element "Operator" {
                background #4a90e2
                color #ffffff
            }
            element "Controller" {
                background #4a90e2
                color #ffffff
            }
            element "Webhook" {
                background #e8744f
                color #ffffff
            }
            element "API" {
                background #e8744f
                color #ffffff
            }
            element "Diagnostics" {
                background #b8b8b8
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
