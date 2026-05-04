.PHONY: build test clean smoke

BINARY    := arch-query
BUILD_DIR := ../../bin

build:
	mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY) .

test:
	go test ./...

clean:
	rm -f $(BUILD_DIR)/$(BINARY)
	go clean

smoke: build
	$(BUILD_DIR)/$(BINARY) versions
	@echo "---"
	$(BUILD_DIR)/$(BINARY) list --names-only | wc -l
	@echo "---"
	$(BUILD_DIR)/$(BINARY) component kserve
	@echo "---"
	$(BUILD_DIR)/$(BINARY) search vllm
	@echo "---"
	$(BUILD_DIR)/$(BINARY) --version current-ga list --names-only | wc -l
