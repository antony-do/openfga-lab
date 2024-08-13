#!/bin/bash

# Directory containing the sample stores projects
STORE_DIR="$1"

# Function to print an error message and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Check if the directory was provided
if [ -z "$STORE_DIR" ]; then
  error_exit "Usage: $0 <path_to_sample_stores_directory>"
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
        # Extract store name from the file name (e.g., "store1.fga.yaml" -> "store1")
        store_name=$(basename "$project_dir")

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

echo "All stores created and imported successfully for all projects."

