workspace {
    model {
        user = person "Data Scientist / ML Engineer" "Creates and manages Ray clusters, jobs, and services for distributed ML workloads"
        platformAdmin = person "Platform Admin" "Deploys and manages the RHOAI platform"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, and services on Kubernetes/OpenShift" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs; creates head/worker pods, services, ingress, routes, RBAC" "Go (controller-runtime)"
            rayJobController = container "RayJob Controller" "Manages job submission and lifecycle via Ray Dashboard API with retry/backoff" "Go (controller-runtime)"
            rayServiceController = container "RayService Controller" "Manages Ray Serve deployments with zero-downtime blue-green cluster promotion" "Go (controller-runtime)"
            webhookServer = container "Webhook Server" "Validates RayCluster CRs (name format, worker group uniqueness)" "Go (HTTPS 9443/TCP)"
            metricsEndpoint = container "Metrics Endpoint" "Exposes Prometheus metrics for operator and Ray resources" "HTTP 8080/TCP"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane for resource management" "External"
        certManager = softwareSystem "cert-manager" "TLS certificate management for webhook server" "External"
        redis = softwareSystem "Redis" "External state store for GCS fault tolerance" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and monitoring" "External"

        volcanoScheduler = softwareSystem "Volcano Scheduler" "Batch scheduler for gang scheduling of distributed workloads" "External"
        yunikornScheduler = softwareSystem "YuniKorn Scheduler" "Batch scheduler with task groups for distributed workloads" "External"
        kueue = softwareSystem "Kueue" "Workload queuing for Ray clusters" "External"

        openshiftRouter = softwareSystem "OpenShift Router" "Exposes Ray dashboard via Routes" "External"
        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that deploys KubeRay" "Internal RHOAI"

        rayHead = softwareSystem "Ray Head Node" "Ray cluster head with Dashboard API and Serve Proxy" "Managed Workload"

        user -> kuberay "Creates RayCluster, RayJob, RayService CRs via kubectl" "HTTPS/6443"
        platformAdmin -> rhodsOperator "Configures RHOAI platform"
        rhodsOperator -> kuberay "Deploys via Kustomize overlay (config/openshift)" "Kustomize"

        kuberay -> k8sApi "CRUD on Pods, Services, Ingress, Routes, Jobs, RBAC, CRDs" "HTTPS/6443 TLS"
        kuberay -> rayHead "Job submission, status polling, serve app deployment" "HTTP/8265"
        kuberay -> rayHead "Serve proxy health check" "HTTP/8000"
        kuberay -> redis "GCS fault tolerance state storage (optional)" "TCP/6379"
        kuberay -> certManager "TLS certificate for webhook server" "CRD"
        kuberay -> volcanoScheduler "Gang scheduling via PodGroup CRD (optional)" "CRD"
        kuberay -> yunikornScheduler "Gang scheduling via AppWrapper (optional)" "CRD"
        kuberay -> kueue "Workload queuing via managedBy field (optional)" "CRD"

        openshiftRouter -> rayHead "Routes dashboard traffic" "HTTP/8265"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"

        rayJobController -> rayClusterController "Creates/manages RayCluster for job execution"
        rayServiceController -> rayClusterController "Creates/manages RayCluster for blue-green upgrade"
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

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Managed Workload" {
                background #4a90e2
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
