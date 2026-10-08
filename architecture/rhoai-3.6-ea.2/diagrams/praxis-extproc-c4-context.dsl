workspace {
    model {
        client = person "API Consumer" "Sends inference requests to MaaS gateway"

        praxisExtproc = softwareSystem "praxis-extproc" "Envoy ExtProc server running Praxis filter pipelines for HTTP request/response inspection, mutation, and rejection" {
            preProcessing = container "payload-pre-processing" "Pre-auth ExtProc instance; BBR pipeline extracts model names and resolves providers" "Rust gRPC Service"
            postProcessing = container "payload-processing" "Post-auth ExtProc instance; IPP pipeline for full request/response processing" "Rust gRPC Service"
            configMap = container "payload-processing-plugins" "Filter chain YAML configurations for BBR and IPP pipelines" "Kubernetes ConfigMap"
        }

        envoyGateway = softwareSystem "MaaS Envoy Gateway" "Istio-based gateway handling inference traffic routing, TLS termination, and filter chain execution" "External"
        kuadrant = softwareSystem "Kuadrant / RHCL" "Authentication and authorization for gateway traffic" "External"
        kubeAPI = softwareSystem "Kubernetes API" "Cluster API for reading CRDs, ConfigMaps, and Secrets" "External"
        prometheus = softwareSystem "OpenShift Monitoring" "Prometheus-based monitoring and alerting" "External"
        kserve = softwareSystem "KServe / Model Upstream" "Inference model serving endpoints" "Internal RHOAI"
        inferenceCRDs = softwareSystem "inference.opendatahub.io CRDs" "ExternalProviders and ExternalModels custom resources" "Internal RHOAI"

        client -> envoyGateway "Sends inference requests" "HTTPS/443"
        envoyGateway -> preProcessing "Pre-auth ExtProc stream" "gRPC H2/9004, TLS (self-signed)"
        preProcessing -> envoyGateway "Returns header mutations (model name, provider)" "gRPC response"
        envoyGateway -> kuadrant "Authentication check" "In-process Envoy filter"
        envoyGateway -> postProcessing "Post-auth ExtProc stream" "gRPC H2/9004, TLS (self-signed)"
        postProcessing -> envoyGateway "Returns header/body mutations" "gRPC response"
        envoyGateway -> kserve "Forwards to model service" "HTTP/gRPC"

        postProcessing -> kubeAPI "Reads ExternalProviders, ExternalModels, ConfigMaps, Secrets" "HTTPS/6443, SA token"
        preProcessing -> kubeAPI "Reads ExternalProviders, ExternalModels" "HTTPS/6443, SA token"
        postProcessing -> inferenceCRDs "Watches model/provider definitions" "Kubernetes API"
        preProcessing -> inferenceCRDs "Watches model/provider definitions" "Kubernetes API"
        prometheus -> preProcessing "Scrapes metrics" "HTTP/9090"
        prometheus -> postProcessing "Scrapes metrics" "HTTP/9090"
        configMap -> preProcessing "Supplies pre-extproc.yaml" "Volume mount"
        configMap -> postProcessing "Supplies extproc.yaml" "Volume mount"
    }

    views {
        systemContext praxisExtproc "SystemContext" {
            include *
            autoLayout
        }

        container praxisExtproc "Containers" {
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
