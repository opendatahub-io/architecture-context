workspace {
    model {
        dataScientist = person "Data Scientist" "Launches AutoRAG pipeline runs to find the best RAG pattern"

        pipelinesComponents = softwareSystem "pipelines-components (AutoRAG)" "KFP @dsl.component wrappers; artifact I/O, secrets, images, asset generation" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "Executes KFP pods (Argo); mounts CA bundles via SSL_CERT_DIR" "Internal ODH"

        ai4rag = softwareSystem "ai4rag" "Python library that optimizes RAG templates via HPO over chunking, embedding, retrieval and generation settings" {
            experiment = container "AI4RAGExperiment" "Orchestrates pre-selection, HPO search, per-iteration index/generate/evaluate, event publishing" "Python"
            preSelector = container "ModelsPreSelector" "Narrows candidate foundation and embedding models" "Python"
            hpo = container "HPO Optimizers" "GAMOptimizer (pyGAM) and RandomOptimizer" "Python"
            ragTemplates = container "RAG Templates" "AgenticRAG (LangChain tool-calling) and SequentialRAG" "Python"
            vectorStores = container "Vector Store Adapters" "Milvus, Milvus Lite, pgvector, Neo4j; ai4rag-prefixed collections" "Python"
            evaluators = container "Evaluators" "LLM-as-a-judge, RAGAS, unitxt" "Python"
            clients = container "Clients + Network Policy" "create_maas_client, create_s3_client, ensure_safe_url" "Python"
            dataUtils = container "Data Utils" "S3 discovery/download, Docling extraction with OCR/ASR" "Python"
            eventHandlers = container "Event Handlers" "KFPEventHandler (in-memory), LocalEventHandler (JSON files)" "Python"
        }

        maas = softwareSystem "Models-as-a-Service" "OpenAI-compatible inference: models, embeddings, chat completions" "Internal ODH"
        s3 = softwareSystem "S3-compatible Storage" "Knowledge-base documents and benchmark data (data connections)" "External"
        milvus = softwareSystem "Milvus / Zilliz" "Vector database" "External"
        pgvector = softwareSystem "PostgreSQL + pgvector" "Vector database" "External"
        neo4j = softwareSystem "Neo4j" "Graph database for graph RAG" "External"
        hf = softwareSystem "Hugging Face Hub" "Pinned RapidOCR / Whisper models (connected mode only)" "External"

        dataScientist -> dsp "Starts AutoRAG pipeline run"
        dsp -> pipelinesComponents "Runs component pods"
        pipelinesComponents -> ai4rag "Imports and invokes (in-process)" "Python"

        pipelinesComponents -> experiment "Runs experiment" "Python"
        pipelinesComponents -> dataUtils "extract_text / prepare_extraction" "Python"
        experiment -> preSelector "Pre-selects models"
        experiment -> hpo "Drives search"
        experiment -> vectorStores "Indexes per-iteration collections"
        experiment -> ragTemplates "Answers benchmark questions"
        experiment -> evaluators "Scores answers"
        experiment -> eventHandlers "Publishes status and patterns"
        ragTemplates -> vectorStores "Retrieves context"
        ragTemplates -> clients "Generates via"
        evaluators -> clients "Judge model via"
        dataUtils -> clients "Uses S3 client"

        clients -> maas "Chat, embeddings, model listing" "HTTPS/443, Bearer API key"
        clients -> s3 "Downloads documents" "HTTPS/443, AWS SigV4"
        vectorStores -> milvus "Index and hybrid search" "gRPC/19530, token"
        vectorStores -> pgvector "Index and hybrid search" "PG wire/5432, TLS verify-full, user/password"
        vectorStores -> neo4j "KG indexing and graph retrieval" "Bolt/7687, TLS, user/password"
        dataUtils -> hf "Downloads pinned models" "HTTPS/443"
    }

    views {
        systemContext ai4rag "SystemContext" {
            include *
            autoLayout
        }

        container ai4rag "Containers" {
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
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}
