.PHONY: build test clean lint

BINARY := arch-doc
BUILD_DIR := ../../bin

build:
	mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(BINARY) .

test:
	go test ./...

clean:
	rm -f $(BUILD_DIR)/$(BINARY)
	go clean

lint:
	go vet ./...
