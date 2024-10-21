#!/bin/bash

CT_LIST_FILE="/tmp/ctlist"

# Check if the file exists
if [ ! -f "$CT_LIST_FILE" ]; then
    echo "File $CT_LIST_FILE does not exist. Please create the file with the CT IDs."
    exit 1
else
    read -p "File $CT_LIST_FILE found. Do you want to continue? (yes/no) " response
    if [ "$response" != "yes" ]; then
        echo "Operation aborted by the user."
        exit 1
    fi
fi

echo "This will kill all listed containers."

# Function to shut down containers
shutdown_containers() {
    for i in "${listct[@]}"; do
        echo "I will shut down CT $i"
        pct shutdown $i
        echo "CT $i has been shut down"
        echo ""
    done
}

# Function to destroy containers
destroy_containers() {
    for i in "${listct[@]}"; do
        echo "I will destroy CT $i"
        pct destroy $i --purge
        echo "CT $i has been destroyed"
        echo ""
    done
}

# Load container list from file
mapfile -t listct < "$CT_LIST_FILE"

# Shutdown and destroy containers
shutdown_containers
destroy_containers
