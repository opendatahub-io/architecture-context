.PHONY: build build-embedded test clean lint lint-python lint-go lint-overlays

build:
	$(MAKE) -C src/arch-query build

build-embedded:
	$(MAKE) -C src/arch-query build-embedded

test:
	$(MAKE) -C src/arch-query test

clean:
	$(MAKE) -C src/arch-query clean

lint: lint-python lint-go lint-overlays

lint-python:
	uv run ruff check .

lint-go:
	$(MAKE) -C src/arch-query lint

lint-overlays:
	uv run python scripts/lint_overlays.py
