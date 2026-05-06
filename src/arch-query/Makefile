.PHONY: build build-embedded test clean clean-embedded smoke smoke-embedded lint lint-fix

BINARY    := arch-query
BUILD_DIR := ../../bin
ARCH_DIR  := ../../architecture

build:
	mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY) .

build-embedded:
	rm -rf _embedded/architecture
	mkdir -p _embedded/architecture
	@# Copy only .md files from real version directories (skip symlinks, diagrams, JSON)
	@for d in $(ARCH_DIR)/*/; do \
		name=$$(basename "$$d"); \
		if [ ! -L "$(ARCH_DIR)/$$name" ]; then \
			mkdir -p "_embedded/architecture/$$name"; \
			find "$$d" -maxdepth 1 -name '*.md' -exec cp {} "_embedded/architecture/$$name/" \; ; \
		fi; \
	done
	@python3 -c "import os,json; d='$(ARCH_DIR)'; \
		print(json.dumps({e:os.readlink(os.path.join(d,e)) \
		for e in sorted(os.listdir(d)) if os.path.islink(os.path.join(d,e))}))" \
		> _embedded/architecture/symlinks.json
	@if [ -d "$(ARCH_DIR)/../overlays" ]; then \
		cp -r "$(ARCH_DIR)/../overlays" _embedded/architecture/overlays; \
	fi
	mkdir -p $(BUILD_DIR)
	go build -tags embedded -o $(BUILD_DIR)/$(BINARY) .
	rm -rf _embedded

test:
	go test ./...

clean:
	rm -f $(BUILD_DIR)/$(BINARY)
	go clean

clean-embedded:
	rm -rf _embedded

smoke: build
	$(BUILD_DIR)/$(BINARY) --base-dir $(ARCH_DIR) versions
	@echo "---"
	$(BUILD_DIR)/$(BINARY) --base-dir $(ARCH_DIR) list --names-only | wc -l
	@echo "---"
	$(BUILD_DIR)/$(BINARY) --base-dir $(ARCH_DIR) component kserve
	@echo "---"
	$(BUILD_DIR)/$(BINARY) --base-dir $(ARCH_DIR) search vllm
	@echo "---"
	$(BUILD_DIR)/$(BINARY) --base-dir $(ARCH_DIR) --version current-ga list --names-only | wc -l

smoke-embedded: build-embedded
	@echo "=== Embedded mode (no --base-dir, running from /tmp) ==="
	cd /tmp && $(CURDIR)/$(BUILD_DIR)/$(BINARY) versions
	@echo "---"
	cd /tmp && $(CURDIR)/$(BUILD_DIR)/$(BINARY) list --names-only | wc -l
	@echo "---"
	cd /tmp && $(CURDIR)/$(BUILD_DIR)/$(BINARY) component kserve
	@echo "---"
	cd /tmp && $(CURDIR)/$(BUILD_DIR)/$(BINARY) search vllm
	@echo "---"
	cd /tmp && $(CURDIR)/$(BUILD_DIR)/$(BINARY) --version current-ga list --names-only | wc -l

lint:
	golangci-lint run ./...

lint-fix:
	golangci-lint run --fix ./...
