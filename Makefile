.PHONY: build build-embedded test clean

build:
	$(MAKE) -C src/arch-query build

build-embedded:
	$(MAKE) -C src/arch-query build-embedded

test:
	$(MAKE) -C src/arch-query test

clean:
	$(MAKE) -C src/arch-query clean
