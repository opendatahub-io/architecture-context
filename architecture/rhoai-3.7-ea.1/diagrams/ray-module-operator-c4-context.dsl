workspace "ray-module-operator" "RHOAI 3.7-ea.1 Ray module operator" {
    model {
        admin = person "Platform Administrator" "Enables the Ray component through the platform DataScienceCluster"
        dataScientist = person "Data Scientist" "Submits RayClusters/RayJobs from workbenches or kubectl"

        rayModule = softwareSystem "ray-module-operator" "Module operator that reconciles the Ray module CR and installs, upgrades, reports on, and removes the KubeRay operator" {
            manager = container "Manager" "controller-runtime entrypoint: TLS profile, metrics 8443/TCP HTTPS, probes 8081/TCP, leader election" "Go"
            reconciler = container "Ray Reconciler" "odh-platform-utilities action pipeline: render, SSA deploy, status, GC, finalizer" "Go controller"
            tlsWatcher = container "TLS SecurityProfileWatcher" "Watches config.openshift.io APIServer; restarts manager on TLS profile change" "Go controller"
            manifests = container "Vendored KubeRay Manifests" "Kustomize snapshot baked into image at /opt/manifests/kuberay (rhoai)" "Kustomize"
        }

        platformOp = softwareSystem "Platform Operator" "rhods-operator / opendatahub-operator: deploys module, creates Ray CR, manages odh-ray-config, injects RELATED_IMAGE_*" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Operand v1.7.1: reconciles RayCluster, RayJob, RayService, RayCronJob; serves RayCluster admission webhooks" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches" "Binds ClusterRole ray to Notebook ServiceAccounts" "Internal RHOAI"
        utilities = softwareSystem "odh-platform-utilities" "Reconciler framework, kustomize engine, TLS helpers (Go library v0.5.0 / framework v0.3.1)" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "odh-kube-rbac-proxy" "Image passed to KubeRay for Ray dashboard authentication" "Internal RHOAI"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API, RBAC, TokenReview/SAR" "External"
        certManager = softwareSystem "cert-manager" "Issues KubeRay webhook serving certificate (hard prerequisite)" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues KubeRay metrics TLS cert" "External"
        openshiftConfig = softwareSystem "OpenShift config API" "APIServer TLS security profile" "External"
        monitoring = softwareSystem "Prometheus / OpenShift Monitoring" "Scrapes module and KubeRay metrics" "External"

        admin -> platformOp "Enables Ray component"
        dataScientist -> kuberay "Creates Ray workloads via ray.io CRs"
        platformOp -> rayModule "Deploys; creates Ray/default-ray; manages odh-ray-config" "HTTPS/6443 via API"
        platformOp -> k8sApi "Creates Deployment, Ray CR, ConfigMap" "HTTPS/6443"

        manager -> reconciler "Registers and runs"
        manager -> tlsWatcher "Starts"
        reconciler -> manifests "Reads and renders"
        reconciler -> k8sApi "Watches Ray/ConfigMap; SSA applies operand; updates status" "HTTPS/6443 TLS 1.2+"
        tlsWatcher -> openshiftConfig "Watches APIServer TLS profile" "HTTPS/6443"
        manager -> k8sApi "TokenReview + SubjectAccessReview for metrics" "HTTPS/6443"

        rayModule -> kuberay "Installs/upgrades/removes (Deployment, CRDs, RBAC, webhooks, Services, SCC, NetworkPolicy)" "SSA via API"
        rayModule -> certManager "Checks CRDs; applies Issuer/Certificate" "via API"
        rayModule -> workbenches "Provides ClusterRole ray (stable name)"
        rayModule -> utilities "Built on" "Go library"
        rayModule -> kubeRbacProxy "Passes image reference to KubeRay" "RELATED_IMAGE env"
        certManager -> kuberay "Issues kuberay-webhook-server-cert"
        serviceCa -> kuberay "Issues kuberay-operator-metrics-tls"
        monitoring -> rayModule "Scrapes /metrics" "HTTPS/8443 Bearer token"
        monitoring -> kuberay "Scrapes metrics" "HTTPS/8443"
        k8sApi -> kuberay "RayCluster admission webhooks" "HTTPS/443 to 9443"
    }

    views {
        systemContext rayModule "SystemContext" {
            include *
            autoLayout
        }

        container rayModule "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6fa8dc
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
