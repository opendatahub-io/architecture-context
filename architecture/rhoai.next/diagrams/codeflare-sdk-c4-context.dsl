workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray clusters from Jupyter notebooks for distributed ML workloads"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library for creating, managing, and submitting jobs to Ray clusters on Kubernetes/OpenShift" {
            clusterModule = container "ray.cluster" "Core Cluster lifecycle management - create, submit, monitor, delete RayCluster/AppWrapper resources" "Python Module"
            configModule = container "ClusterConfiguration" "Dataclass defining resource requirements (CPU, memory, GPU, extended resources)" "Python Dataclass"
            generateYaml = container "generate_yaml" "Renders RayCluster specs from YAML templates and wraps in AppWrappers" "Python Module"
            rayJobClient = container "RayJobClient" "Wrapper around Ray JobSubmissionClient for job CRUD operations" "Python Module"
            authModule = container "auth" "Kubernetes authentication - TokenAuth, KubeConfigFileAuth, in-cluster SA" "Python Module"
            kueueModule = container "kueue" "LocalQueue discovery, validation, and label attachment for workload queuing" "Python Module"
            generateCert = container "generate_cert" "TLS certificate generation (CA + client certs) for mTLS Ray client connections" "Python Module"
            widgets = container "widgets" "Jupyter notebook UI widgets (ipywidgets) for interactive cluster management" "Python Module"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Reconciles RayCluster CRs into Ray head and worker pods" "Internal Platform"
        appWrapperController = softwareSystem "AppWrapper Controller" "Multi-resource scheduling and fault tolerance via AppWrapper CRs" "Internal Platform"
        kueue = softwareSystem "Kueue" "Workload queuing and fair scheduling via LocalQueue CRs" "Internal Platform"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Exposes Ray dashboard and client endpoints externally" "Internal Platform"
        rayDashboard = softwareSystem "Ray Dashboard" "Ray head node dashboard for job submission, status, and logs" "Ray Runtime"
        rayClientServer = softwareSystem "Ray Client Server" "Ray head node for direct ray:// protocol client access" "Ray Runtime"
        k8sApi = softwareSystem "Kubernetes API Server" "Kubernetes control plane API" "Infrastructure"
        odhCaBundle = softwareSystem "ODH Trusted CA Bundle" "Custom CA trust ConfigMap mounted into Ray pods" "Internal Platform"

        # User interactions
        user -> codeflareSdk "Creates clusters and submits jobs from Jupyter notebooks"
        user -> widgets "Interacts with cluster management UI"

        # SDK to K8s API
        codeflareSdk -> k8sApi "CRUD on CRDs, Secrets, Routes, Ingresses" "HTTPS/6443 TLS 1.2+ Bearer Token"

        # SDK to Ray
        codeflareSdk -> rayDashboard "Job submission, status, logs" "HTTP(S)/8265 or HTTPS/443 via Route"
        codeflareSdk -> rayClientServer "Direct Ray client connection" "TCP/10001 mTLS"

        # K8s API to operators
        k8sApi -> kuberayOperator "Watch events for RayCluster CRs"
        k8sApi -> appWrapperController "Watch events for AppWrapper CRs"
        k8sApi -> kueue "Watch events for LocalQueue CRs"

        # Operators create resources
        kuberayOperator -> k8sApi "Creates Ray head + worker Pods"

        # Internal container relationships
        clusterModule -> configModule "Uses configuration"
        clusterModule -> generateYaml "Generates YAML manifests"
        clusterModule -> authModule "Authenticates to K8s"
        clusterModule -> kueueModule "Discovers LocalQueues"
        rayJobClient -> authModule "Authenticates to K8s"
        generateCert -> authModule "Retrieves CA secrets"
        widgets -> clusterModule "Manages cluster lifecycle"
    }

    views {
        systemContext codeflareSdk "SystemContext" {
            include *
            autoLayout
        }

        container codeflareSdk "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Internal Platform" {
                background #7ed321
                color #ffffff
            }
            element "Ray Runtime" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #999999
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
