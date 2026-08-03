# Architecture Change Evidence

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | architecture_components | jupyter-minimal | * | <empty> | <empty> | RHOAI manifests ship the minimal Jupyter image stream. | manifests/rhoai/base/kustomization.yaml:1-8 |
| add | architecture_components | jupyter-datascience | * | <empty> | <empty> | RHOAI manifests ship the data science Jupyter image stream. | manifests/rhoai/base/kustomization.yaml:5-9 |
| add | architecture_components | jupyter-pytorch | * | <empty> | <empty> | RHOAI manifests ship the PyTorch Jupyter image stream. | manifests/rhoai/base/kustomization.yaml:7-10 |
| add | architecture_components | jupyter-pytorch-llmcompressor | * | <empty> | <empty> | RHOAI manifests ship the LLMCompressor Jupyter image stream. | manifests/rhoai/base/kustomization.yaml:14-17 |
| add | architecture_components | jupyter-tensorflow | * | <empty> | <empty> | RHOAI manifests ship the TensorFlow Jupyter image stream. | manifests/rhoai/base/kustomization.yaml:8-11 |
| add | architecture_components | jupyter-trustyai | * | <empty> | <empty> | RHOAI manifests ship the TrustyAI Jupyter image stream. | manifests/rhoai/base/kustomization.yaml:9-12 |
| add | architecture_components | jupyter-rocm-pytorch | * | <empty> | <empty> | RHOAI manifests parameterize the ROCm PyTorch image stream. | manifests/rhoai/base/kustomization.yaml:459-498 |
| add | architecture_components | jupyter-rocm-tensorflow | * | <empty> | <empty> | RHOAI manifests parameterize the ROCm TensorFlow image stream. | manifests/rhoai/base/kustomization.yaml:511-550 |
| add | architecture_components | codeserver | * | <empty> | <empty> | RHOAI manifests ship the code-server image stream. | manifests/rhoai/base/kustomization.yaml:355-394 |
| add | architecture_components | runtime-minimal | * | <empty> | <empty> | RHOAI manifests ship the minimal pipeline runtime. | manifests/rhoai/base/kustomization.yaml:1161-1173 |
| add | architecture_components | runtime-datascience | * | <empty> | <empty> | RHOAI manifests ship the data science pipeline runtime. | manifests/rhoai/base/kustomization.yaml:1174-1186 |
| add | architecture_components | runtime-pytorch | * | <empty> | <empty> | RHOAI manifests ship CUDA and ROCm PyTorch runtimes. | manifests/rhoai/base/kustomization.yaml:1187-1212 |
| add | architecture_components | runtime-pytorch-llmcompressor | * | <empty> | <empty> | RHOAI manifests ship the LLMCompressor pipeline runtime. | manifests/rhoai/base/kustomization.yaml:1239-1250 |
| add | architecture_components | runtime-tensorflow | * | <empty> | <empty> | RHOAI manifests ship CUDA and ROCm TensorFlow runtimes. | manifests/rhoai/base/kustomization.yaml:1213-1238 |
| add | architecture_components | runtime-rocm-pytorch | * | <empty> | <empty> | RHOAI manifests name the ROCm PyTorch runtime. | manifests/rhoai/base/kustomization.yaml:1200-1212 |
| add | architecture_components | runtime-rocm-tensorflow | * | <empty> | <empty> | RHOAI manifests name the ROCm TensorFlow runtime. | manifests/rhoai/base/kustomization.yaml:1226-1238 |
| add | architecture_components | mongocli | * | <empty> | <empty> | The data science image builds and installs the MongoDB CLI. | jupyter/datascience/ubi9-python-3.12/Dockerfile.konflux.cpu:7-31; jupyter/datascience/ubi9-python-3.12/Dockerfile.konflux.cpu:137-137 |
| add | architecture_components | buildinputs | * | <empty> | <empty> | The build creates the buildinputs helper binary. | Makefile:175-181 |
| add | http_endpoints | get :: /lab | * | <empty> | <empty> | The image explicitly starts JupyterLab, whose UI route is `/lab`. | jupyter/minimal/ubi9-python-3.12/start-notebook.sh:46-50 |
| add | http_endpoints | get :: / | * | <empty> | <empty> | The nginx configuration registers the root redirect. | codeserver/ubi9-python-3.12/nginx/serverconf/proxy.conf.template:34-39 |
| add | http_endpoints | get :: /api | * | <empty> | <empty> | The nginx configuration registers the probe API redirect. | codeserver/ubi9-python-3.12/nginx/serverconf/proxy.conf.template:1-11 |
| add | external_dependencies | pytorch | * | <empty> | <empty> | The shipped PyTorch image stream records PyTorch 2.11. | manifests/rhoai/base/jupyter-pytorch-notebook-imagestream.yaml:24-31 |
| add | external_dependencies | code-server | * | <empty> | <empty> | The Konflux Dockerfile pins and installs code-server 4.106.3. | codeserver/ubi9-python-3.12/Dockerfile.konflux.cpu:43-49; codeserver/ubi9-python-3.12/Dockerfile.konflux.cpu:225-230 |
| add | external_dependencies | nginx | * | <empty> | <empty> | The code-server image pins and installs nginx 1.24. | codeserver/ubi9-python-3.12/Dockerfile.konflux.cpu:243-263 |
| add | external_dependencies | node.js | * | <empty> | <empty> | The code-server image enables and installs Node.js 22. | codeserver/ubi9-python-3.12/Dockerfile.konflux.cpu:56-63 |
| add | external_dependencies | elyra bootstrapper | * | <empty> | <empty> | Runtime images install the Elyra 4.3.1 bootstrapper. | runtimes/minimal/ubi9-python-3.12/Dockerfile.konflux.cpu:54-58 |
| add | internal_dependencies | rhods-operator / opendatahub-operator | * | <empty> | <empty> | The repository provides distinct RHOAI and ODH platform manifest trees. | manifests/rhoai/base/kustomization.yaml:1-22 |
| add | services | jupyterlab (in-container) | * | <empty> | <empty> | The entrypoint starts JupyterLab on the configured notebook port. | jupyter/minimal/ubi9-python-3.12/start-notebook.sh:18-25; jupyter/minimal/ubi9-python-3.12/start-notebook.sh:46-50 |
| add | integration_points | aipcc base images :: from directive | * | <empty> | <empty> | Konflux images consume AIPCC base images through build arguments. | jupyter/minimal/ubi9-python-3.12/Dockerfile.konflux.cpu:10-19 |
| add | integration_points | konflux / cachi2 :: build system | * | <empty> | <empty> | Konflux Dockerfiles install dependencies exclusively from Cachi2 output. | codeserver/ubi9-python-3.12/Dockerfile.konflux.cpu:1-11 |
| add | integration_points | rhods-operator :: manifest consumption (kustomize) | * | <empty> | <empty> | The RHOAI manifest tree is a kustomize package of shipped ImageStreams. | manifests/rhoai/base/kustomization.yaml:1-22 |
| add | integration_points | opendatahub-operator :: manifest consumption (kustomize) | * | <empty> | <empty> | The repository also contains the ODH distribution manifest tree. | manifests/odh/base/kustomization.yaml:1-22 |
