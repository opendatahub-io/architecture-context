workspace {
    model {
        user = person "Data Scientist" "Creates and manages Ray distributed computing workloads on Kubernetes/OpenShift"

        kuberay = softwareSystem "KubeRay Operator" "Manages lifecycle of Ray clusters, jobs, services, and cron jobs on Kubernetes/OpenShift via CRDs" {
            rayClusterController = container "RayCluster Controller" "Reconciles RayCluster CRs into head/worker Pods, Services, Ingresses/Routes" "Go (controller-runtime)"
            rayJobController = container "RayJob Controller" "Manages Ray job submission lifecycle, creates RayClusters and submitter Jobs" "Go (controller-runtime)"
            rayServiceController = container "RayService Controller" "Manages Ray Serve deployments with blue-green and incremental upgrade strategies" "Go (controller-runtime)"
            rayCronJobController = container "RayCronJob Controller" "Schedules periodic RayJob creation based on cron expressions" "Go (controller-runtime)"
            authController = container "Authentication Controller" "Injects kube-rbac-proxy sidecars and creates Gateway API HTTPRoutes for authenticated access" "Go (controller-runtime)" "RHOAI Security"
            netpolController = container "NetworkPolicy Controller" "Creates head and worker NetworkPolicies for secure pod isolation" "Go (controller-runtime)" "RHOAI Security"
            mtlsController = container "mTLS Controller" "Manages cert-manager Issuers and Certificates for inter-node mTLS" "Go (controller-runtime)" "RHOAI Security"
            webhookServer = container "Webhook Server" "Mutates and validates RayCluster, RayJob, RayService resources" "Go Admission Webhook" "RHOAI Security"
            batchSchedulerMgr = container "Batch Scheduler Manager" "Integrates with Volcano, Yunikorn, Kai-scheduler for gang scheduling" "Go Plugin System"
            dashboardCache = container "Dashboard Cache Client" "LRU cache (10K entries, 10m TTL) with 8-worker goroutine pool querying at 3s intervals" "Go"
        }

        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRD reconciliation, pod/service CRUD, RBAC" "External"
        certManager = softwareSystem "cert-manager" "Certificate lifecycle management for mTLS between Ray nodes" "External"
        gatewayAPI = softwareSystem "Gateway API" "HTTPRoute and Gateway support for authenticated ingress and RayService upgrades" "External"
        openshiftAPI = softwareSystem "OpenShift API" "Route, APIServer TLS profile, OAuth/Authentication CRD access" "External"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "Sidecar for authenticated dashboard access via TokenReview/SubjectAccessReview" "External"
        prometheus = softwareSystem "Prometheus" "Metrics scraping for operator control plane metrics" "External"
        rhodsOperator = softwareSystem "rhods-operator / odh-operator" "Deploys KubeRay via kustomize overlay" "Internal RHOAI"
        codeflareOperator = softwareSystem "CodeFlare Operator" "Provides external admission webhooks for RayCluster resources" "Internal RHOAI"
        platformGateway = softwareSystem "Platform Gateway" "RHOAI platform Gateway for HTTPRoute-based authenticated access" "Internal RHOAI"

        rayCluster = softwareSystem "Ray Cluster" "Distributed Ray head and worker pods running user workloads" "Runtime"
        rayDashboard = softwareSystem "Ray Dashboard" "Ray web UI and REST API for job submission and monitoring" "Runtime"

        volcano = softwareSystem "Volcano" "Gang scheduling via PodGroup CRD" "External Optional"
        yunikorn = softwareSystem "Yunikorn" "Task group scheduling via annotations" "External Optional"
        kaiScheduler = softwareSystem "Kai-scheduler" "GPU-aware scheduling" "External Optional"
        kueue = softwareSystem "Kueue" "Workload queuing via MultiKueue integration" "External Optional"

        # User interactions
        user -> kuberay "Creates RayCluster/RayJob/RayService/RayCronJob CRs via kubectl"
        user -> platformGateway "Accesses Ray Dashboard via authenticated HTTPRoute" "HTTPS/443"
        user -> rayCluster "Sends inference requests via RayService Gateway" "HTTP/80"

        # Operator → External
        kuberay -> k8sAPI "CRD reconciliation, pod/service CRUD, RBAC checks" "HTTPS/443"
        kuberay -> certManager "Creates Issuers and Certificates for inter-node mTLS" "CRD"
        kuberay -> gatewayAPI "Creates HTTPRoutes for authenticated dashboard and RayService traffic" "CRD"
        kuberay -> openshiftAPI "Reads cluster TLS security profile and auth mode" "HTTPS"
        kuberay -> rayDashboard "Submits jobs, deploys serve apps, queries status" "HTTP/8265"

        # External → Operator
        rhodsOperator -> kuberay "Deploys operator via kustomize overlay config/openshift" "Kustomize"
        codeflareOperator -> kuberay "Intercepts RayCluster CRs via external webhooks" "Admission Webhook"
        prometheus -> kuberay "Scrapes operator metrics" "HTTP/8080"
        k8sAPI -> kuberay "Sends admission webhook requests" "HTTPS/9443"

        # Runtime
        kuberay -> rayCluster "Creates and manages head/worker pods" "Kubernetes API"
        platformGateway -> kubeRBACProxy "Routes dashboard traffic via HTTPRoute" "HTTPS/8443"
        kubeRBACProxy -> k8sAPI "TokenReview + SubjectAccessReview" "HTTPS/443"
        kubeRBACProxy -> rayDashboard "Proxies authenticated requests" "HTTP/8265"

        # Optional schedulers
        kuberay -> volcano "Gang scheduling for Ray workloads" "CRD (PodGroup)"
        kuberay -> yunikorn "Task group scheduling for Ray workloads" "Annotations"
        kuberay -> kaiScheduler "GPU-aware scheduling for Ray workloads" "CRD"
        kuberay -> kueue "Workload queuing" "managedBy field"

        # Internal container relationships
        rayClusterController -> dashboardCache "Reads cached job status"
        rayJobController -> dashboardCache "Submits jobs and reads status"
        rayServiceController -> dashboardCache "Deploys serve apps"
        rayCronJobController -> rayJobController "Creates RayJob CRs"
        authController -> rayClusterController "Coordinates via annotations"
        netpolController -> rayClusterController "Coordinates via annotations"
        mtlsController -> rayClusterController "Coordinates via annotations"
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
            element "External Optional" {
                background #bbbbbb
                color #ffffff
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Runtime" {
                background #4a90e2
                color #ffffff
            }
            element "RHOAI Security" {
                background #66bb6a
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
