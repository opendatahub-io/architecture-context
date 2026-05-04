.PHONY: build test clean

build:
	$(MAKE) -C src/arch-query build

test:
	$(MAKE) -C src/arch-query test

clean:
	$(MAKE) -C src/arch-query clean
