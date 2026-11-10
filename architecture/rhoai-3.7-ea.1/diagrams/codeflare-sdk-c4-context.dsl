workspace "codeflare-sdk" "C4 context for the CodeFlare SDK (RHOAI 3.7-ea.1, v0.40.1)" {
    model {
        user = person "Data Scientist" "Creates Ray clusters and submits jobs from notebooks or scripts"

        codeflareSdk = softwareSystem "CodeFlare SDK" "Python client library that builds and submits KubeRay RayCluster/RayJob resources using the user's own credentials. No in-cluster workload." {
            facade = container "Codeflare facade" "SDKConfig/AuthConfig entrypoint; exposes cf.clusters and cf.jobs with namespace resolution" "Python"
            clusterMod = container "ray.cluster" "Builds RayCluster specs, server-side apply, status, dashboard URL discovery" "Python"
            rayJobs = container "ray.rayjobs" "Builds RayJob CRs; ships local files via owned Secrets" "Python"
            jobClient = container "RayJobClient" "Wraps Ray JobSubmissionClient for dashboard REST" "Python"
            kueueMod = container "common.kueue" "LocalQueue discovery, priority labels, RHBOK/DSC checks" "Python"
            authMod = container "common.kubernetes_cluster" "kube-authkit integration, CA bundle, deprecated auth" "Python"
            certGen = container "generate_cert" "Mints Ray mTLS client certs signed by cluster CA" "Python / cryptography"
            widgets = container "common.widgets" "ipywidgets notebook UI" "Python"
            vendored = container "vendored python_client" "Copy of upstream KubeRay Python client" "Python"
            migration = container "ray_cluster_migration.py" "RHOAI 2.x to 3.x RayCluster migration CLI" "Python script"
        }

        k8sApi = softwareSystem "Kubernetes / OpenShift API" "API server; enforces user RBAC" "External"
        kubeRay = softwareSystem "KubeRay Operator" "Reconciles RayCluster/RayJob; creates CA secret and dashboard exposure" "Internal RHOAI"
        kueue = softwareSystem "Kueue / Red Hat Build of Kueue" "Queue admission for Ray workloads" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "DataScienceCluster and GatewayConfig CRs" "Internal RHOAI"
        gateway = softwareSystem "Data-science Gateway" "Gateway API front door; kube-auth-proxy authentication" "Internal RHOAI"
        rayCluster = softwareSystem "Ray Cluster" "Ray head (dashboard 8265, client 10001) and workers" "Internal RHOAI"
        workbench = softwareSystem "ODH Workbenches" "Notebook images that install the SDK" "Internal RHOAI"
        olm = softwareSystem "OLM" "OperatorCondition for kueue-operator version" "External"
        pypi = softwareSystem "PyPI" "Package distribution" "External"

        user -> codeflareSdk "Uses Python API / notebook widgets"
        user -> facade "Calls"
        user -> widgets "Uses"
        facade -> authMod "Authenticates"
        facade -> clusterMod "Manages clusters"
        facade -> rayJobs "Manages jobs"
        clusterMod -> kueueMod "Queue labels"
        rayJobs -> kueueMod "Queue labels"
        clusterMod -> certGen "Generates TLS"
        clusterMod -> jobClient "Dashboard jobs"
        clusterMod -> vendored "Uses"
        rayJobs -> vendored "Uses"
        widgets -> clusterMod "Uses"

        codeflareSdk -> k8sApi "CR and Secret CRUD, discovery" "HTTPS/6443, TLS, user bearer token"
        authMod -> k8sApi "Authenticates" "HTTPS/6443"
        clusterMod -> k8sApi "Server-side apply RayCluster; list HTTPRoute/Gateway/Route" "HTTPS/6443"
        rayJobs -> k8sApi "Create RayJob and file Secret" "HTTPS/6443"
        certGen -> k8sApi "Read cluster CA secret (incl. private key)" "HTTPS/6443"
        migration -> k8sApi "Backup/migrate RayClusters" "HTTPS/6443"
        codeflareSdk -> kubeRay "Submits RayCluster/RayJob CRs (via API server)"
        codeflareSdk -> kueue "Reads LocalQueue/Workload/WorkloadPriorityClass; labels workloads"
        codeflareSdk -> rhoaiOperator "Reads DataScienceCluster, GatewayConfig"
        codeflareSdk -> olm "Reads OperatorCondition"
        codeflareSdk -> gateway "Ray Jobs REST API" "HTTPS/443, Bearer token"
        jobClient -> gateway "Ray Jobs REST API" "HTTPS/443, Bearer token"
        codeflareSdk -> rayCluster "Interactive Ray client" "gRPC/10001, mTLS"
        certGen -> rayCluster "mTLS client cert" "gRPC/10001"
        gateway -> rayCluster "Forwards to dashboard" "8265/TCP"
        kubeRay -> rayCluster "Reconciles"
        workbench -> codeflareSdk "Hosts (pip-installed)"
        pypi -> workbench "Provides package"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6aa6e8
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
