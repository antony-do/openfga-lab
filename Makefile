# Variables
VERSION := $(if $(VERSION),$(VERSION),$(error VERSION is not set))

# Default target
all: init

# Download the docker-compose.yaml file
download:
	curl -LO https://openfga.dev/docker-compose.yaml

# Replace the image version in docker-compose.yaml
replace:
	sed -i.bak "s|image: openfga/openfga:latest|image: openfga/openfga:$(VERSION)|" docker-compose.yaml

# Initialize the workshop
init: download replace
	@echo "Workshop initialized with OpenFGA version $(VERSION)."

# Clean up backup files created by sed
clean:
	rm -f docker-compose.yaml.bak

.PHONY: all download replace init clean

