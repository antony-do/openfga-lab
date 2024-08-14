#!/bin/bash

# Directory containing the sample stores projects
STORE_DIR="$1"

# Function to print an error message and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Function to check if a store already exists
store_exists() {
  local store_name="$1"
  if fga store list | grep -q "$store_name"; then
    return 0 # Store exists
  else
    return 1 # Store does not exist
  fi
}

# Function to compare semantic versions
version_less_than() {
  if [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" == "$1" ] && [ "$1" != "$2" ]; then
    return 0 # $1 is less than $2
  else
    return 1 # $1 is not less than $2
  fi
}

# Check if the directory was provided
if [ -z "$STORE_DIR" ]; then
  error_exit "Usage: $0 <path_to_sample_stores_directory>"
fi

# Check if VERSION environment variable is set
if [ -z "$VERSION" ]; then
  error_exit "Environment variable VERSION is not set."
fi

# Check if the directory exists
if [ ! -d "$STORE_DIR" ]; then
  error_exit "Directory $STORE_DIR does not exist."
fi

# Iterate over each project directory within STORE_DIR
for project_dir in "$STORE_DIR"/stores/*/; do
  if [ -d "$project_dir" ]; then
    # Get the project name (e.g., "project1")
    project_name=$(basename "$project_dir")
    
    echo "Processing project: $project_name"

    # Iterate over each .fga.yaml file in the project directory
    for store_file in "$project_dir"/*.fga.yaml; do
      if [ -f "$store_file" ]; then
        # Extract store name from the project directory name (e.g., "condition-data-types.fga.yaml" -> "condition-data-types")
        store_name=$(basename "$project_dir")

        # Skip the "condition-data-types" store if VERSION < v1.4.0
        if [ "$store_name" == "condition-data-types" ] && version_less_than "$VERSION" "v1.4.0"; then
          echo "Skipping 'condition-data-types' store for project '$project_name' as VERSION is less than v1.4.0"
          continue
        fi
	# Importing data into store 'modular' from tmp/sample-stores-main/stores/modular//store.fga.yaml...
	# Error: failed to import store: failed to create store: failed to write model due to WriteAuthorizationModel validation error for POST WriteAuthorizationModel with body {"code":"validation_error","message":"invalid WriteAuthorizationModelRequest.SchemaVersion: value must be in list [1.0 1.1]"} with error code validation_error#  error message: invalid WriteAuthorizationModelRequest.SchemaVersion: value must be in list [1.0 1.1]
	# Error: Failed to import store data from tmp/sample-stores-main/stores/modular//store.fga.yaml Failed to load stores
        if [ "$store_name" == "modular" ]; then
          echo "Skipping 'modular' store for project '$project_name' as invalid WriteAuthorizationModelRequest.SchemaVersion: value must be in list [1.0 1.1]}"
	  continue
	fi

        # Check if the store already exists
        if store_exists "$store_name"; then
          echo "Store '$store_name' for project '$project_name' already exists. Skipping..."
          continue
        fi

        echo "Creating store with name '$store_name' for project '$project_name'..."
        
        # Create a new store using the OpenFGA CLI
        if ! fga store create --name="$store_name"; then
          error_exit "Failed to create store '$store_name' for project '$project_name'"
        fi

        echo "Importing data into store '$store_name' from $store_file..."

        # Import the store data from the YAML file
        if ! fga store import --file="$store_file"; then
          error_exit "Failed to import store data from $store_file"
        fi

        echo "Store '$store_name' for project '$project_name' imported successfully."
      else
        echo "No .fga.yaml files found in $project_dir"
      fi
    done
  else
    echo "No valid project directories found in $STORE_DIR/stores"
  fi
done

echo "All applicable stores created and imported successfully for all projects."

