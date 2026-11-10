workspace {
    model {
        maintainer = person "Catalog Maintainer" "Runs catalog generation and reviews data/*.yaml PRs"
        dataScientist = person "Data Scientist" "Browses Model Catalog and MCP Catalog in RHOAI"

        mmc = softwareSystem "model-metadata-collection" "Curated YAML catalogs (models, MCP servers, agents, serving runtimes) shipped as a static data image" {
            dataImage = container "odh-model-metadata-collection-rhel9" "Static data image. /app/data VOLUME, UID 1001, sleep infinity, no ports" "UBI9 minimal PQC"
            catalogData = container "data/*.yaml" "100 validated models, 44 other models, 12 MCP servers, 14 agents, 24 serving runtimes" "YAML in git"
            modelExtractor = container "model-extractor" "Builds model, MCP and agent catalogs (offline)" "Go CLI"
            srCatalog = container "serving-runtime-catalog" "Renders ServingRuntime template catalog using skopeo, kustomize, cosign (offline)" "Go CLI"
            srValidate = container "serving-runtime-validate" "Validates serving-runtime catalog against embedded model-registry schemas" "Go CLI"
            metadataReport = container "metadata-report" "Metadata completeness reports" "Go CLI"
        }

        huggingface = softwareSystem "HuggingFace Hub" "Model collections, metadata, READMEs" "External"
        github = softwareSystem "GitHub" "Agent repos (api.github.com, raw.githubusercontent.com)" "External"
        rhRegistry = softwareSystem "registry.redhat.io" "ModelCar, MCP and RHOAI controller images, SBOM attestations" "External"
        konflux = softwareSystem "Konflux" "Hermetic multi-arch image build (konflux-central pipeline)" "External"
        quay = softwareSystem "quay.io/rhoai" "Image registry for shipped data image" "External"

        modelRegistry = softwareSystem "model-registry catalog service" "Serves Model Catalog and MCP Catalog APIs; loads /app/data as catalog sources" "Internal RHOAI"
        operator = softwareSystem "rhods-operator / model-registry-operator" "Deploys data image and configures catalog source paths" "Internal RHOAI"
        kserve = softwareSystem "KServe controllers" "Source of ServingRuntime templates" "Internal RHOAI"
        dashboard = softwareSystem "odh-dashboard" "Catalog UI" "Internal RHOAI"

        maintainer -> modelExtractor "Runs via make"
        maintainer -> srCatalog "Runs via make"
        maintainer -> catalogData "Reviews PRs"
        modelExtractor -> huggingface "Collections, metadata, README" "HTTPS/443, optional Bearer HF_TOKEN"
        modelExtractor -> github "Agent SHA resolution, agent.yaml" "HTTPS/443, optional Bearer GITHUB_TOKEN"
        modelExtractor -> rhRegistry "ModelCar manifests and layers" "HTTPS/443 OCI"
        modelExtractor -> catalogData "Writes"
        srCatalog -> rhRegistry "skopeo extract, cosign SBOM" "HTTPS/443 OCI"
        srCatalog -> kserve "Extracts templates from controller images"
        srCatalog -> catalogData "Writes"
        srValidate -> catalogData "Validates"
        metadataReport -> catalogData "Reports on"
        konflux -> catalogData "Copies data/*.yaml"
        konflux -> quay "Pushes image" "HTTPS/443"
        konflux -> dataImage "Builds"
        operator -> dataImage "Deploys (inferred)"
        modelRegistry -> dataImage "Mounts /app/data (inferred)" "Volume"
        dashboard -> modelRegistry "Reads catalog"
        dataScientist -> dashboard "Browses catalogs"
    }

    views {
        systemContext mmc "SystemContext" {
            include *
            autoLayout
        }

        container mmc "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
