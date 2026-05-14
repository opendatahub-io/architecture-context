workspace {
    model {
        datascientist = person "Data Scientist" "Creates and manages RayCluster resources for distributed computing workloads"
        admin = person "Platform Admin" "Configures and manages the RHOAI platform and operator settings"

        codeflareOperator = softwareSystem "CodeFlare Operator" "Manages lifecycle and security configuration of RayCluster and AppWrapper resources with OAuth proxy injection, mTLS certificate management, network isolation, and batch workload queuing" {
            manager = container "Operator Manager" "Reconciles RayCluster resources, injects OAuth proxy sidecars, manages mTLS certificates, creates Routes/Ingresses, NetworkPolicies, and RBAC resources" "Go (controller-runtime)"
            rayclusterWebhook = container "RayCluster Webhook" "Mutates RayCluster pods to inject OAuth proxy sidecar and mTLS init containers; validates immutability of injected resources" "Mutating/Validating Webhook"
            appwrapperController = container "AppWrapper Controller" "Manages AppWrapper CRDs for batch workload queuing with Kueue integration (optional, embedded)" "Go Controller"
            appwrapperWebhook = container "AppWrapper Webhook" "Validates and defaults AppWrapper resources; performs SubjectAccessReview for authorization" "Mutating/Validating Webhook"
        }

        kuberayOperator = softwareSystem "KubeRay Operator" "Creates and manages RayCluster custom resources" "External"
        odhOperator = softwareSystem "ODH/RHOAI Operator" "Platform operator providing DSCInitialization CR for namespace discovery" "Internal RHOAI"
        openshiftOAuth = softwareSystem "OpenShift OAuth Server" "Provides OAuth authentication for Ray Dashboard access" "External - OpenShift"
        openshiftRouter = softwareSystem "OpenShift Router" "Serves Routes created for Ray Dashboard (reencrypt) and RayClient (passthrough)" "External - OpenShift"
        openshiftMonitoring = softwareSystem "OpenShift Monitoring" "Prometheus scrapes operator metrics via ServiceMonitor" "External - OpenShift"
        certController = softwareSystem "cert-controller (OPA)" "Manages webhook certificate rotation" "External"
        kueue = softwareSystem "Kueue" "Provides quota management for AppWrapper workloads" "External - Optional"
        kubeflowTraining = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob resources that AppWrappers can wrap" "External - Optional"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet resources that AppWrappers can wrap" "External - Optional"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API for CRUD operations and webhook calls" "External - Infrastructure"
        openshiftServingCert = softwareSystem "OpenShift Serving Cert Signer" "Generates TLS certificates for OAuth service via annotation" "External - OpenShift"

        # Relationships
        datascientist -> codeflareOperator "Creates RayCluster and AppWrapper resources via kubectl/API"
        admin -> codeflareOperator "Configures operator settings via ConfigMap"

        kuberayOperator -> codeflareOperator "Creates RayCluster CRs watched by operator" "CRD Watch"
        codeflareOperator -> odhOperator "Reads DSCInitialization CR for namespace discovery" "CRD Watch"
        codeflareOperator -> openshiftOAuth "OAuth proxy sidecar authenticates users" "HTTPS/443"
        codeflareOperator -> openshiftRouter "Creates Routes for Dashboard (reencrypt) and Client (passthrough)" "Route creation"
        openshiftMonitoring -> codeflareOperator "Scrapes operator metrics" "HTTP/8080"
        certController -> codeflareOperator "Manages webhook TLS certificates" "Certificate rotation"
        codeflareOperator -> kueue "AppWrapper controller integrates for quota management" "CRD Integration"
        codeflareOperator -> kubernetesAPI "CRUD on Secrets, Services, Routes, NetworkPolicies, ClusterRoleBindings" "HTTPS/443"
        kubernetesAPI -> codeflareOperator "Calls mutating/validating webhooks" "HTTPS/9443"
        openshiftServingCert -> codeflareOperator "Generates TLS certs for OAuth service" "Annotation-triggered"

        # Container-level relationships
        manager -> rayclusterWebhook "Registers webhook handlers"
        manager -> appwrapperController "Optionally enables AppWrapper controller"
        appwrapperController -> appwrapperWebhook "Registers AppWrapper webhook handlers"
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
            element "Software System" {
                background #438DD5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "External - OpenShift" {
                background #CC0000
                color #ffffff
            }
            element "External - Optional" {
                background #BBBBBB
                color #ffffff
            }
            element "External - Infrastructure" {
                background #666666
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427B
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
        }
    }
}
