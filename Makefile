# Variables
VERSION := $(if $(VERSION),$(VERSION),$(error VERSION is not set))
TARGET_VERSION := $(if $(TARGET_VERSION),$(TARGET_VERSION),$(error TARGET_VERSION is not set))

# Default target
all: init

# Download the docker-compose.yaml file and pull the images
download:
	curl -LO https://openfga.dev/docker-compose.yaml || (echo "Failed to download docker-compose.yaml" && exit 1)
	docker compose pull || (echo "Failed to pull Docker images" && exit 1)

# Replace the image version in docker-compose.yaml
replace:
	sed -i.bak "s|image: openfga/openfga:latest|image: openfga/openfga:$(VERSION)|" docker-compose.yaml

# Initialize the workshop
init: download replace load-stores
	@echo "Workshop initialized with OpenFGA version $(VERSION)."

# Start the specified version of OpenFGA
start:
	docker compose up -d || (echo "Failed to start OpenFGA" && exit 1)

# Load stores from the sample stores repository
load-stores:
	mkdir -p tmp
	(cd tmp && \
	curl -L https://github.com/openfga/sample-stores/archive/refs/heads/main.zip -o sample-stores.zip && \
	unzip sample-stores.zip) || (echo "Failed to download and unzip sample stores" && exit 1)
	# Replace this with the actual command to load stores
	./load-stores.sh tmp/sample-stores-main || (echo "Failed to load stores" && exit 1)

# Replace the version in docker-compose.yaml and pull the new image
download-new-version:
	sed -i.bak "s|image: openfga/openfga:.*|image: openfga/openfga:$(TARGET_VERSION)|" docker-compose.yaml
	docker compose pull || (echo "Failed to pull new Docker images" && exit 1)

# Stop the current version and start the new one
upgrade-version:
	docker compose down || (echo "Failed to stop OpenFGA" && exit 1)
	docker compose up -d || (echo "Failed to start OpenFGA with new version" && exit 1)

# Upgrade command to perform all the steps
upgrade: start download-new-version upgrade-version
	@echo "Upgraded OpenFGA to version $(TARGET_VERSION)."

# Clean up backup files and downloaded files
clean:
	rm -f docker-compose.yaml.bak
	rm -rf tmp

.PHONY: all download replace init start load-stores upgrade-version upgrade clean

