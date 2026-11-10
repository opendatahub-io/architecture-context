workspace "notebooks (RHOAI 3.7-ea.1)" "Workbench and pipeline-runtime images for Red Hat OpenShift AI" {
    model {
        user = person "Data Scientist" "Opens workbenches and builds pipelines from notebooks"
        admin = person "Platform Admin" "Manages workbench image catalogue"

        notebooks = softwareSystem "notebooks" "RHOAI workbench (JupyterLab, code-server) and Elyra/DSP pipeline-runtime images, plus ImageStream manifests" {
            jupyter = container "Jupyter workbench images" "minimal (CPU/CUDA/ROCm), datascience, pytorch, pytorch-llmcompressor, tensorflow. JupyterLab 4.5 on 8888/TCP HTTP, no in-pod auth" "Python 3.12 container image"
            universal = container "jupyter-universal" "Dual-mode image: JupyterLab workbench or Elyra bootstrapper runtime. Backs jupyter-universal-notebook and runtime-universal" "Python 3.12 container image"
            codeserver = container "code-server workbench images" "datascience and minimal. nginx :8888 to code-server :8787 (--auth none) and httpd CGI :8080 for culler" "Node.js / Python 3.12 container image"
            runtimes = container "Pipeline runtime images" "runtime-minimal/datascience/pytorch/pytorch-llmcompressor/tensorflow. Headless Elyra bootstrapper.py" "Python 3.12 container image"
            manifests = container "ImageStream manifests" "manifests/rhoai: 24 ImageStreams (N...N-5), ConfigMaps notebook-image-params and notebook-image-commithash" "Kustomize"
            mongocli = container "mongocli" "MongoDB CLI built with strictfipsruntime, copied into datascience-derived images" "Go binary"
        }

        operator = softwareSystem "rhods-operator" "Deploys manifests, patches params-latest.env from RELATED_IMAGE_*" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Creates Notebook StatefulSets, kube-rbac-proxy sidecar, HTTPRoute, NetworkPolicy, culling" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "Workbench image picker, deprecation badges" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "KFP API server and Argo execution" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare / KubeRay" "Ray cluster management" "Internal RHOAI"
        trainer = softwareSystem "Kubeflow Trainer" "Reuses universal dual-mode image pattern" "Internal RHOAI"
        platformClients = softwareSystem "Feast, MLflow, Model Registry, TrustyAI" "Platform services accessed through SDKs in images" "Internal RHOAI"
        gateway = softwareSystem "Platform Gateway" "Gateway API HTTPRoute on NB_PREFIX, TLS termination" "Internal RHOAI"

        k8s = softwareSystem "Kubernetes / OpenShift API" "Cluster API" "External"
        s3 = softwareSystem "S3-compatible object storage" "Elyra pipeline artefacts" "External"
        aipcc = softwareSystem "AIPCC" "Digest-pinned base images and Python channel index" "External"
        konflux = softwareSystem "Konflux" "Hermetic multi-arch builds, check-payload, Conforma" "External"
        registry = softwareSystem "quay.io/rhoai and registry.redhat.io" "Image registries" "External"
        git = softwareSystem "Git remotes / GitHub" "Source repos, BYO Copilot" "External"

        user -> gateway "Opens workbench" "HTTPS/443 TLS 1.2+, OAuth/OIDC"
        gateway -> notebookController "kube-rbac-proxy sidecar enforces SAR" "HTTPS, service CA"
        gateway -> jupyter "Proxied via kube-rbac-proxy" "HTTP/8888 pod-local"
        gateway -> codeserver "Proxied via kube-rbac-proxy" "HTTP/8888 pod-local"
        admin -> dashboard "Manages image catalogue"

        notebookController -> jupyter "Launches pod, injects NOTEBOOK_ARGS, culls" "HTTP/8888"
        notebookController -> codeserver "Launches pod, injects NB_PREFIX, culls" "HTTP/8888"
        operator -> manifests "Applies ImageStreams and ConfigMaps" "HTTPS/6443"
        dashboard -> manifests "Reads ImageStream labels" "HTTPS/6443"
        dsp -> runtimes "Runs as pipeline node pods"
        dsp -> universal "Runs in runtime mode"
        trainer -> universal "Image reuse"

        jupyter -> dsp "Submits pipelines (Elyra/KFP)" "HTTPS/8888 or 443, Bearer SA token"
        jupyter -> s3 "Uploads notebook + deps" "HTTPS or HTTP"
        jupyter -> k8s "oc, kubernetes client, CodeFlare SDK" "HTTPS/6443, Bearer"
        jupyter -> codeflare "Manages Ray clusters" "HTTPS/6443"
        jupyter -> platformClients "SDK access"
        jupyter -> git "jupyterlab-git, nbgitpuller" "HTTPS/443, SSH/22"
        codeserver -> git "BYO Copilot (optional)" "HTTPS/443, device-code OAuth"
        runtimes -> s3 "bootstrapper.py downloads inputs, uploads outputs" "HTTPS or HTTP, static keys / IRSA"
        mongocli -> jupyter "Copied into image at build"

        notebooks -> aipcc "FROM base images, hash-pinned wheels" "HTTPS/443"
        konflux -> notebooks "Builds 15 images hermetically"
        konflux -> registry "Pushes images" "HTTPS/443"
        manifests -> registry "References N-1...N-5 digests"
    }

    views {
        systemContext notebooks "SystemContext" {
            include *
            autoLayout
        }

        container notebooks "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
