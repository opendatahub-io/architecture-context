workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and manages Ray clusters for distributed ML workloads via Python API or Jupyter Notebook"

        codeflareSDK = softwareSystem "CodeFlare SDK" "Python client library for Ray cluster lifecycle management on Kubernetes/OpenShift" {
            rayCluster = container "ray.cluster" "Core Cluster class for creating, scaling, monitoring, and deleting Ray clusters" "Python Module"
            clusterConfig = container "ray.cluster.config" "ClusterConfiguration dataclass defining resource requests and cluster parameters" "Python Dataclass"
            generateYaml = container "ray.cluster.generate_yaml" "YAML generation engine that creates RayCluster and AppWrapper manifests from configuration" "Python Module"
            appWrapper = container "ray.appwrapper" "AWManager for submitting/removing pre-existing AppWrapper YAML files" "Python Module"
            rayClient = container "ray.client" "RayJobClient wrapper around Ray Job Submission Client for job management" "Python Module"
            auth = container "common.kubernetes_cluster.auth" "Kubernetes authentication (token-based, kubeconfig file, in-cluster)" "Python Module"
            kueue = container "common.kueue" "Kueue LocalQueue integration for batch workload scheduling" "Python Module"
            generateCert = container "common.utils.generate_cert" "TLS certificate generation for secure Ray cluster communication" "Python Module"
            widgets = container "common.widgets" "Jupyter ipywidgets UI for interactive cluster management in notebooks" "Python Module"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRDs, creates Ray head/worker pods and services" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "AppWrapper controller for multi-resource workload wrapping with Kueue integration" "Internal RHOAI"
        kueueSystem = softwareSystem "Kueue" "Kubernetes-native batch workload scheduling and resource management" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Central control plane API for all cluster management operations" "Infrastructure"
        openshiftRouter = softwareSystem "OpenShift Router" "Provides external Route-based access to Ray dashboard with OAuth" "Infrastructure"
        rayDashboard = softwareSystem "Ray Dashboard" "Web UI and REST API for Ray cluster monitoring and job submission" "Workload"
        odhCABundle = softwareSystem "ODH Trusted CA Bundle" "Custom CA certificates for RHOAI environments (ConfigMap)" "Internal RHOAI"

        # User interactions
        dataScientist -> codeflareSDK "Creates clusters, submits jobs via Python API"

        # SDK internal flows
        rayCluster -> clusterConfig "Reads configuration"
        rayCluster -> generateYaml "Generates YAML manifests"
        rayCluster -> appWrapper "Wraps resources in AppWrapper"
        rayCluster -> rayClient "Submits Ray jobs"
        rayCluster -> auth "Authenticates to Kubernetes"
        rayCluster -> kueue "Assigns workloads to queues"
        rayCluster -> generateCert "Generates TLS certificates"
        rayCluster -> widgets "Renders notebook UI widgets"

        # External interactions
        codeflareSDK -> kubernetesAPI "CRUD operations on RayCluster, AppWrapper, LocalQueue CRDs" "HTTPS/6443, Bearer Token"
        codeflareSDK -> rayDashboard "Dashboard readiness checks and job submission" "HTTPS/443 or HTTP/8265"
        kubernetesAPI -> kuberayOperator "Reconciles RayCluster CRs"
        kubernetesAPI -> codeflareOperator "Reconciles AppWrapper CRs"
        kubernetesAPI -> kueueSystem "Workload admission and scheduling"
        kuberayOperator -> rayDashboard "Creates Ray head/worker pods"
        openshiftRouter -> rayDashboard "Routes external traffic to Ray dashboard"
        codeflareSDK -> openshiftRouter "Discovers dashboard URL via Route API" "HTTPS/6443"
    }

    views {
        systemContext codeflareSDK "SystemContext" {
            include *
            autoLayout
            description "CodeFlare SDK system context showing the client library within the RHOAI ecosystem"
        }

        container codeflareSDK "Containers" {
            include *
            autoLayout
            description "CodeFlare SDK internal module structure"
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
                color #ffffff
            }
            element "Workload" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
