.PHONY: build test clean smoke lint

BINARY := arch-analyzer
BUILD_DIR := ../../bin

build:
	mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY) .

test:
	go test ./...

lint:
	test -z "$$(gofmt -l .)"
	go vet ./...

smoke: build
	$(BUILD_DIR)/$(BINARY) render \
		--input ../../architecture/rhoai.next/kueue.json \
		--output /tmp/kueue-arch-analyzer.md \
		--distribution RHOAI

clean:
	rm -f $(BUILD_DIR)/$(BINARY)
	go clean
