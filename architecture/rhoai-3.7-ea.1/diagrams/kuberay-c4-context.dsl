workspace "KubeRay (RHOAI 3.7-ea.1)" "C4 context and container view of the KubeRay operator" {
    model {
        dataScientist = person "Data Scientist" "Creates RayClusters / RayJobs / RayServices via CodeFlare SDK, workbench or kubectl; views Ray dashboard"
        platformAdmin = person "Platform Admin" "Enables the Ray component in the DataScienceCluster"

        kuberay = softwareSystem "KubeRay Operator" "Manages Ray clusters, jobs, Serve services and scheduled jobs on OpenShift with RHOAI security defaults" {
            manager = container "kuberay-operator manager" "controller-runtime manager hosting all controllers; 1 replica" "Go 1.26 Operator"
            rayClusterCtl = container "RayCluster Controller" "Head/worker pods, Services, autoscaler RBAC, auth token Secret" "Go Controller"
            rayJobCtl = container "RayJob Controller" "Creates RayCluster + submitter Job; polls dashboard API" "Go Controller"
            rayServiceCtl = container "RayService Controller" "Ray Serve deployments, zero-downtime upgrades" "Go Controller"
            authCtl = container "AuthenticationController" "Injects kube-rbac-proxy; creates HTTPRoute + ReferenceGrant" "Go Controller (downstream)"
            mtlsCtl = container "RayClusterMTLSController" "Per-cluster cert-manager PKI for Ray mTLS" "Go Controller"
            npCtl = container "NetworkPolicyController" "Per-cluster head/worker NetworkPolicies" "Go Controller"
            legacyCtl = container "LegacySecurityController" "Migrates legacy annotation to native tlsOptions/networkPolicy" "Go Controller (downstream)"
            webhooks = container "Admission Webhooks" "mraycluster.kb.io / vraycluster.kb.io, 9443/TCP, failurePolicy Fail" "Go Webhook Server"
            metrics = container "Metrics Server" "/metrics HTTPS 8443 (Service), TokenReview/SAR" "controller-runtime"
            tlsWatcher = container "TLS Profile Watcher" "Applies cluster TLS profile; restarts on change" "Go"
        }

        rayCluster = softwareSystem "Ray Cluster (operand)" "Ray head + workers in user namespace; dashboard 8265, GCS 6379, client 10001, kube-rbac-proxy 8443" "Operand"

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster API, 6443/TCP HTTPS" "External"
        certManager = softwareSystem "cert-manager" "Webhook cert and per-RayCluster PKI" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Metrics serving cert" "External"
        ocpConfig = softwareSystem "OpenShift Cluster Config" "APIServer TLS profile, KubeAPIServer auth mode" "External"
        batchSchedulers = softwareSystem "Volcano / scheduler-plugins" "Optional gang scheduling" "External"

        rhodsOperator = softwareSystem "rhods-operator" "Deploys kuberay-operator manifests (config/openshift)" "Internal RHOAI"
        gateway = softwareSystem "data-science-gateway" "Gateway API ingress in openshift-ingress; platform Gateway auth" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Quota and admission for Ray workloads" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare SDK / Workbenches" "Authors Ray CRs; reaches head on 8265/10001" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Scrapes operator and Ray metrics" "Internal RHOAI"

        dataScientist -> codeflare "Uses"
        codeflare -> k8sApi "Creates RayCluster/RayJob/RayService" "HTTPS/6443"
        dataScientist -> gateway "Opens Ray dashboard /ray/<ns>/<cluster>" "HTTPS/443"
        platformAdmin -> rhodsOperator "Enables Ray component"
        rhodsOperator -> kuberay "Deploys and configures (params.env)"

        k8sApi -> webhooks "Admission requests" "HTTPS/443->9443"
        manager -> k8sApi "Watch/CRUD Ray CRs and owned resources" "HTTPS/6443, SA token"
        kuberay -> k8sApi "Reconciles resources" "HTTPS/6443"
        kuberay -> certManager "Creates Issuers/Certificates (via API)"
        kuberay -> serviceCa "Uses metrics serving cert"
        kuberay -> ocpConfig "Reads/watches TLS profile"
        kuberay -> batchSchedulers "Creates PodGroups (optional)"
        kuberay -> gateway "Creates HTTPRoute with parentRef"
        kuberay -> rayCluster "Creates; submits jobs / reads Serve status" "HTTP/8265 (plaintext)"
        kueue -> kuberay "Suspends/admits RayJobs via spec.suspend/managedBy"
        gateway -> rayCluster "Routes dashboard traffic" "HTTP/8265 (plaintext, no per-cluster SAR)"
        prometheus -> kuberay "Scrapes /metrics" "HTTPS/8443, Bearer"
        prometheus -> rayCluster "Scrapes Ray metrics" "HTTP/8080"
        codeflare -> rayCluster "Ray client / dashboard" "gRPC/10001, HTTP/8265"

        rayClusterCtl -> rayCluster "Creates head/worker pods and Services"
        rayJobCtl -> rayCluster "Submits jobs, polls status" "HTTP/8265"
        rayServiceCtl -> rayCluster "Serve config and health" "HTTP/8265, HTTP/8000"
        authCtl -> gateway "Creates HTTPRoute + ReferenceGrant"
        authCtl -> rayCluster "Injects kube-rbac-proxy sidecar"
        mtlsCtl -> certManager "Creates CA + leaf Certificates"
        npCtl -> rayCluster "Creates NetworkPolicies"
        legacyCtl -> k8sApi "Patches legacy RayClusters" "HTTPS/6443"
        webhooks -> k8sApi "Returns mutation/validation"
        tlsWatcher -> ocpConfig "Watches APIServer/cluster"
        manager -> rayClusterCtl "Hosts"
        manager -> rayJobCtl "Hosts"
        manager -> rayServiceCtl "Hosts"
        manager -> authCtl "Hosts"
        manager -> mtlsCtl "Hosts"
        manager -> npCtl "Hosts"
        manager -> legacyCtl "Hosts"
        manager -> webhooks "Serves"
        manager -> metrics "Serves"
        manager -> tlsWatcher "Runs"
        prometheus -> metrics "Scrapes" "HTTPS/8443"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6aa9f0
                color #ffffff
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
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Operand" {
                background #f5a623
                color #000000
            }
        }
    }
}
