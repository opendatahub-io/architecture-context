workspace "kubeflow (RHOAI 3.7-ea.1)" "Notebook controllers for RHOAI workbenches" {
    model {
        user = person "Data Scientist" "Creates and uses Jupyter/IDE workbenches"
        admin = person "Platform Admin" "Configures cluster TLS profile and RHOAI"

        kubeflow = softwareSystem "kubeflow (Workbench Controllers)" "Reconciles kubeflow.org Notebook CRs into running workbenches with Gateway API ingress, kube-rbac-proxy auth and pipeline/MLflow/Feast integration" {
            kfController = container "odh-kf-notebook-controller" "Upstream Kubeflow controller: Notebook -> StatefulSet + Service (80->8888); optional idle culling; metrics 8443 HTTPS" "Go, controller-runtime"
            odhController = container "odh-notebook-controller" "Creates HTTPRoute, ReferenceGrant, NetworkPolicies, kube-rbac-proxy resources, CA bundle, DSPA/MLflow RBAC and secrets; metrics 8080 HTTPS" "Go, controller-runtime"
            odhWebhook = container "ODH admission webhooks" "Mutating /mutate-notebook-v1 and validating /validate-notebook-v1 on 8443 HTTPS, failurePolicy Fail" "Go, controller-runtime webhook"
            kubeRbacProxy = container "kube-rbac-proxy sidecar" "Injected per notebook; TLS 8443; TokenReview + SAR get notebooks/<name>; proxies to 127.0.0.1:8888" "Go sidecar"
            notebook = container "Notebook workload" "User Jupyter/IDE StatefulSet pod on 8888/TCP HTTP" "Workbench image"
        }

        k8sApi = softwareSystem "Kubernetes API Server" "Cluster control plane (6443/TCP)" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues serving certs and injects CA bundles" "External"
        osConfig = softwareSystem "OpenShift config API" "APIServer TLS profile, cluster Proxy" "External"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus scraping via ServiceMonitor" "External"

        rhods = softwareSystem "rhods-operator" "Deploys both controllers via the rhoai overlay (Workbenches component)" "Internal ODH"
        dashboard = softwareSystem "ODH Dashboard" "Workbench lifecycle UI; creates Notebook CRs" "Internal ODH"
        gateway = softwareSystem "data-science-gateway" "Platform Gateway API Gateway in openshift-ingress" "Internal ODH"
        dspo = softwareSystem "Data Science Pipelines Operator" "DSPA CR and ds-pipeline-user-access-dspa Role" "Internal ODH"
        mlflow = softwareSystem "MLflow Operator" "mlflow-operator-mlflow-integration ClusterRole and tracking server" "Internal ODH"
        feast = softwareSystem "Feast Operator" "Provides <nb>-feast-config ConfigMap" "Internal ODH"
        images = softwareSystem "Workbench Images" "ImageStreams for notebook images and pipeline runtimes" "Internal ODH"

        user -> dashboard "Creates workbench" "HTTPS"
        user -> gateway "Opens /notebook/<ns>/<name>" "HTTPS/443"
        admin -> osConfig "Sets tlsSecurityProfile"
        dashboard -> k8sApi "Creates Notebook CR" "HTTPS/6443"
        rhods -> kubeflow "Deploys and configures"

        k8sApi -> odhWebhook "Admission review" "HTTPS/443->8443"
        odhController -> k8sApi "Reconciles resources" "HTTPS/6443, SA token"
        kfController -> k8sApi "Reconciles StatefulSet/Service" "HTTPS/6443, SA token"
        kfController -> notebook "Culler polls /api/kernels" "HTTP/80 plaintext"
        gateway -> kubeRbacProxy "HTTPRoute backend" "HTTPS/8443"
        kubeRbacProxy -> k8sApi "TokenReview + SubjectAccessReview" "HTTPS/6443"
        kubeRbacProxy -> notebook "Proxies authorized requests" "HTTP 127.0.0.1:8888"
        gateway -> notebook "HTTPRoute backend when inject-auth absent" "HTTP/8888"

        odhController -> gateway "Creates HTTPRoutes; reads Gateway" "Kubernetes API"
        odhController -> dspo "Reads DSPA, binds pipeline Role" "Kubernetes API"
        odhController -> mlflow "Binds MLflow ClusterRole, sets tracking URI" "Kubernetes API"
        odhWebhook -> feast "Mounts Feast config" "ConfigMap"
        odhWebhook -> images "Resolves workbench image digests" "Kubernetes API"
        kfController -> osConfig "Watches APIServer TLS profile" "HTTPS/6443"
        odhController -> osConfig "Watches TLS profile, adherence, Proxy" "HTTPS/6443"
        serviceCa -> kubeflow "Serving certs for webhook, metrics, kube-rbac-proxy"
        monitoring -> kfController "Scrapes /metrics" "HTTPS/8443, bearer"
        monitoring -> odhController "Scrapes /metrics" "HTTPS/8443->8080, bearer"
    }

    views {
        systemContext kubeflow "SystemContext" {
            include *
            autoLayout
        }

        container kubeflow "Containers" {
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
                background #438dd5
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
