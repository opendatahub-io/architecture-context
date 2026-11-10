workspace "distributed-workloads (RHOAI 3.7.0-ea.1)" "Universal training images, Ray runtime images and the distributed-workloads E2E suite" {
    model {
        dataScientist = person "Data Scientist" "Uses workbenches and submits TrainJobs via the Kubeflow SDK"
        ciOperator = person "CI Operator" "Runs the E2E suite against a live cluster"

        dw = softwareSystem "distributed-workloads" "Build repo for universal training and Ray runtime images plus the Go E2E test suite (no deployed service)" {
            cudaImage = container "th-torch-cuda-py312" "Universal CUDA 13.0 image: Jupyter workbench + Trainer runtime, OpenMPI/SSH, vLLM 0.31" "Container image (Python 3.12)"
            cpuImage = container "th-torch-cpu-py312" "Universal CPU image (x86_64, arm64, ppc64le) with OpenMPI/SSH" "Container image (Python 3.12)"
            rocmImage = container "th-torch-rocm-py312" "Universal ROCm 7.14 image (x86_64), no MPI/SSH" "Container image (Python 3.12)"
            entrypoint = container "entrypoint-universal.sh" "Switches between workbench mode (NOTEBOOK_ARGS) and command passthrough" "Shell"
            uidExec = container "openshift-uid-exec.sh" "mpirun/mpiexec wrapper: UID registration, MPI host DNS wait, nofile cap" "Shell"
            rayImages = container "Ray runtime images" "KubeRay head/worker images, Ray 2.52.1 / 2.58.0" "Container image (UBI9 Python)"
            testsImage = container "tests image" "gotestsum + oc 4.18" "Container image (Go 1.26)"
            e2e = container "E2E test suite" "kfto, trainer, odh, fms suites" "Go / gomega"
        }

        notebooks = softwareSystem "notebooks" "Jupyter minimal workbench base images and workbench controller" "Internal RHOAI"
        trainer = softwareSystem "Kubeflow Trainer v2" "ClusterTrainingRuntimes referencing universal images" "Internal RHOAI"
        kfto = softwareSystem "Training Operator v1" "PyTorchJob" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay" "RayCluster / RayJob" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Quota and admission" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC PyPI index" "public-rhai/rhoai/3.6 wheels" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API" "Cluster API server" "External"
        s3 = softwareSystem "S3-compatible storage" "Dataset/model staging" "External"
        hf = softwareSystem "Hugging Face Hub" "Model/dataset download" "External"
        prom = softwareSystem "Prometheus / Thanos" "GPU metrics" "External"

        dataScientist -> notebooks "Opens workbench" "HTTPS/443 OAuth"
        notebooks -> entrypoint "Starts Jupyter via NOTEBOOK_ARGS" "HTTP/8888"
        dataScientist -> k8s "Creates TrainJob via Kubeflow SDK" "HTTPS/6443 Bearer"
        trainer -> cudaImage "Runs launcher/worker pods"
        trainer -> cpuImage "Runs launcher/worker pods"
        trainer -> rocmImage "Runs training pods"
        kuberay -> rayImages "Runs Ray head/worker"
        cudaImage -> entrypoint "Uses"
        cpuImage -> entrypoint "Uses"
        rocmImage -> entrypoint "Uses"
        cudaImage -> uidExec "mpirun symlink"
        cpuImage -> uidExec "mpirun symlink"
        uidExec -> cudaImage "OpenMPI launcher to worker sshd" "SSH/2222 pubkey"
        cudaImage -> s3 "Downloads datasets/models" "HTTPS/443 AWS keys"
        cudaImage -> hf "Downloads models" "HTTPS/443 HF_TOKEN"

        notebooks -> dw "Supplies BASE_IMAGE"
        aipcc -> dw "Supplies wheels (Cachi2 prefetch)"

        ciOperator -> testsImage "Runs with kubeconfig"
        testsImage -> e2e "Executes"
        e2e -> k8s "Creates namespaces, queues, RBAC, workloads" "HTTPS/6443 kubeconfig"
        e2e -> trainer "Validates TrainJob / JobSet / MPI"
        e2e -> kfto "Validates PyTorchJob"
        e2e -> kuberay "Submits RayJobs via dashboard Route" "HTTPS/443, TLS verify off"
        e2e -> kueue "Validates admission and quotas"
        e2e -> prom "Queries GPU metrics" "HTTPS/443 Bearer"
        e2e -> s3 "Stages/verifies artifacts" "HTTPS/443, TLS verify off"
    }

    views {
        systemContext dw "SystemContext" {
            include *
            autoLayout
        }

        container dw "Containers" {
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
                background #4a90e2
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
