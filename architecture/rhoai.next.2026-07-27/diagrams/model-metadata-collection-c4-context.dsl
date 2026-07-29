workspace {
    model {
        ciPipeline = person "CI/CD Pipeline" "Executes model-metadata-collection as a batch job"
        developer = person "Developer" "Runs model-metadata-collection locally for testing"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "CLI data pipeline that extracts metadata from Red Hat AI model containers, enriches it with HuggingFace data, and generates structured catalogs" {
            modelExtractor = container "model-extractor" "Main extraction pipeline: fetches OCI manifests, extracts model cards, enriches with HuggingFace and GitHub data, generates catalogs" "Go CLI"
            metadataReport = container "metadata-report" "Generates completeness reports from catalog output" "Go CLI"
            registryClient = container "Registry Client" "Fetches OCI container manifests and blob layers from registries" "Go Library (internal/registry)"
            huggingfaceClient = container "HuggingFace Client" "Fetches model details, collections, READMEs, and tool-calling config" "Go Library (internal/huggingface)"
            githubClient = container "GitHub Client" "Fetches agent.yaml and README.md from GitHub repositories" "Go Library (internal/github)"
            catalogBuilder = container "Catalog Builder" "Merges, deduplicates, and consolidates model metadata into unified catalogs" "Go Library (internal/catalog)"
        }

        ociRegistry = softwareSystem "OCI Container Registry" "Red Hat container image registry (registry.redhat.io) storing AI model containers" "External"
        huggingface = softwareSystem "HuggingFace" "ML model hub providing model metadata, READMEs, tags, and collections" "External"
        github = softwareSystem "GitHub" "Source code hosting providing agent configurations and documentation" "External"

        ciPipeline -> modelMetadataCollection "Executes batch extraction"
        developer -> modelMetadataCollection "Runs locally for testing"

        modelExtractor -> registryClient "Uses for OCI operations"
        modelExtractor -> huggingfaceClient "Uses for metadata enrichment"
        modelExtractor -> githubClient "Uses for agent data"
        modelExtractor -> catalogBuilder "Uses for catalog generation"

        registryClient -> ociRegistry "Fetches manifests and layers" "HTTPS/443"
        huggingfaceClient -> huggingface "Fetches model details and collections" "HTTPS/443, Bearer HF_TOKEN"
        githubClient -> github "Fetches agent configs and READMEs" "HTTPS/443, Bearer GITHUB_TOKEN"
    }

    views {
        systemContext modelMetadataCollection "SystemContext" {
            include *
            autoLayout
        }

        container modelMetadataCollection "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6baed6
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
