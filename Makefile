.PHONY: build build-arch-query build-arch-analyzer build-embedded test test-python test-arch-query test-arch-analyzer clean lint lint-python lint-go lint-overlays lint-platforms lint-architecture-docs

build: build-arch-query build-arch-analyzer

build-arch-query:
	$(MAKE) -C src/arch-query build

build-arch-analyzer:
	$(MAKE) -C src/arch-analyzer build

build-embedded:
	$(MAKE) -C src/arch-query build-embedded

test: test-python test-arch-query test-arch-analyzer

test-python:
	uv run pytest -q tests/test_agent_runner.py tests/test_architecture_baseline.py tests/test_architecture_corpus.py tests/test_architecture_merge.py tests/test_architecture_phase.py tests/test_architecture_routing.py tests/test_cli.py tests/test_distribution.py tests/test_static_analysis.py tests/test_rebase_architecture_synthesis.py tests/test_validate_architecture.py

test-arch-query:
	$(MAKE) -C src/arch-query test

test-arch-analyzer:
	$(MAKE) -C src/arch-analyzer test

clean:
	$(MAKE) -C src/arch-query clean
	$(MAKE) -C src/arch-analyzer clean

lint: lint-python lint-go lint-overlays lint-platforms lint-architecture-docs

lint-python:
	uv run ruff check .

lint-go:
	$(MAKE) -C src/arch-query lint
	$(MAKE) -C src/arch-analyzer lint

lint-overlays:
	uv run python scripts/lint_overlays.py

lint-platforms:
	uv run python scripts/lint_platforms.py

lint-architecture-docs:
	uv run python scripts/lint_architecture_docs.py
