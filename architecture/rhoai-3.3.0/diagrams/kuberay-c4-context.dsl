workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for distributed ML/data processing workloads"
        mlEngineer = person "ML Engineer" "Deploys Ray-based model serving and batch jobs"

        kuberay = softwareSystem "KubeRay Operator" "Kubernetes operator managing Ray cluster lifecycle, autoscaling, and fault tolerance" {
            operator = container "kuberay-operator" "Manages Ray CRDs and reconciles cluster state" "Go Operator" {
                rayClusterController = component "RayCluster Controller" "Manages RayCluster lifecycle and autoscaling" "Go Controller"
                rayJobController = component "RayJob Controller" "Manages batch job execution" "Go Controller"
                rayServiceController = component "RayService Controller" "Manages Ray Serve with HA and zero-downtime upgrades" "Go Controller"
                networkPolicyController = component "NetworkPolicy Controller" "Manages network policies for isolation" "Go Controller"
                authController = component "Authentication Controller" "Manages mTLS and OAuth integration" "Go Controller"
                webhookServer = component "Webhook Server" "Validates and mutates RayCluster resources" "Go Admission Webhook"
            }

            rayCluster = container "Ray Cluster (Managed)" "Distributed computing cluster with head and worker nodes" "Ray Framework" {
                headPod = component "Ray Head Pod" "GCS, Dashboard, Client Server" "Ray Head"
                workerPods = component "Ray Worker Pods" "Autoscaling computation nodes" "Ray Workers"
            }
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External" {
            k8sAPI = container "Kubernetes API" "Resource management and reconciliation" "Kubernetes"
        }

        certManager = softwareSystem "cert-manager" "TLS certificate management for mTLS" "External"
        gatewayAPI = softwareSystem "Gateway API" "Advanced ingress and routing with authentication" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"
        redis = softwareSystem "External Redis" "GCS fault tolerance external storage" "External"

        odhDashboard = softwareSystem "ODH Dashboard" "Displays Ray cluster resources and status" "Internal ODH"
        modelRegistry = softwareSystem "Model Registry" "Uses Ray for distributed model training" "Internal ODH"
        dsPipelines = softwareSystem "Data Science Pipelines" "Executes Ray jobs in pipeline steps" "Internal ODH"

        s3Storage = softwareSystem "S3 Storage" "Object storage for Ray working directory and model artifacts" "External"
        containerRegistry = softwareSystem "Container Registry" "Ray container images" "External"

        %% User interactions
        dataScientist -> kuberay "Creates RayCluster CR via kubectl"
        mlEngineer -> kuberay "Deploys RayJob/RayService via kubectl"

        %% Operator interactions
        operator -> k8sAPI "Manages Ray resources, watches CRDs" "HTTPS/443 TLS1.2+, Bearer Token"
        operator -> certManager "Requests TLS certificates for mTLS" "HTTPS/443 TLS1.2+, Bearer Token"
        operator -> prometheus "Exposes metrics" "HTTP/8080"
        k8sAPI -> webhookServer "Admission requests for RayCluster validation" "HTTPS/9443 TLS1.2+"

        %% Ray cluster interactions
        rayCluster -> redis "GCS fault tolerance storage" "Redis/6379, Optional TLS, Password"
        rayCluster -> s3Storage "Loads data and artifacts" "HTTPS/443 TLS1.2+, Cloud credentials"
        operator -> containerRegistry "Pulls Ray images" "HTTPS/443 TLS1.2+, Pull secrets"

        %% ODH integrations
        odhDashboard -> kuberay "Displays cluster status" "Kubernetes API"
        modelRegistry -> kuberay "Submits training jobs" "RayJob CR"
        dsPipelines -> kuberay "Executes distributed pipeline steps" "RayJob CR"

        %% External access
        mlEngineer -> gatewayAPI "Accesses Ray Serve endpoints" "HTTPS/443 TLS1.3, Optional Bearer"
        gatewayAPI -> rayCluster "Routes to Ray Serve" "HTTP/8000, Optional TLS"

        %% Controller relationships
        rayClusterController -> k8sAPI "Creates head/worker pods"
        rayJobController -> k8sAPI "Creates batch jobs"
        rayServiceController -> k8sAPI "Creates serving deployments"
        networkPolicyController -> k8sAPI "Creates network policies"
        authController -> certManager "Requests certificates"

        %% Managed cluster relationships
        headPod -> workerPods "Distributes computation" "Ray Protocol, Optional mTLS"
    }

    views {
        systemContext kuberay "SystemContext" {
            include *
            autoLayout
        }

        container kuberay "Containers" {
            include *
            autoLayout
        }

        component operator "OperatorComponents" {
            include *
            autoLayout
        }

        component rayCluster "RayClusterComponents" {
            include *
            autoLayout
        }

        styles {
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
        }
    }
}
