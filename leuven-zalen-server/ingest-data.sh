#!/bin/bash

# Script to ingest sample zalen data into the LDES server
# Usage: ./ingest-data.sh

set -e

LDES_SERVER="http://localhost:9003"
DATA_DIR="data"

echo "================================================"
echo "Ingesting Leuven Zalen Sample Data"
echo "================================================"
echo ""

# Check if server is running
if ! curl -s "${LDES_SERVER}/actuator/health" > /dev/null 2>&1; then
    echo "Error: LDES server is not running at ${LDES_SERVER}"
    echo "Please start the server with: docker-compose up -d"
    exit 1
fi

echo "Server is running. Starting data ingestion..."
echo ""

# Count total files
total_files=$(ls -1 "${DATA_DIR}"/*.ttl 2>/dev/null | wc -l | tr -d ' ')

if [ "$total_files" -eq 0 ]; then
    echo "Error: No .ttl files found in ${DATA_DIR}/"
    exit 1
fi

echo "Found ${total_files} files to ingest"
echo ""

# Counter for progress
count=0
failed=0

# Ingest each file
for file in "${DATA_DIR}"/*.ttl; do
    count=$((count + 1))
    filename=$(basename "$file")

    echo "[$count/$total_files] Ingesting ${filename}..."

    # POST the file to the LDES endpoint
    response=$(curl -X POST "${LDES_SERVER}/zalen" \
        -H "Content-Type: text/turtle" \
        --data-binary "@${file}" \
        -s -w "\n%{http_code}" -o /tmp/ldes_response.txt)

    # Extract HTTP status code (last line)
    http_code=$(echo "$response" | tail -n 1)

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo "  ✓ Successfully ingested ${filename}"
    else
        echo "  ✗ Failed to ingest ${filename} (HTTP ${http_code})"
        cat /tmp/ldes_response.txt
        failed=$((failed + 1))
    fi

    # Small delay between requests
    sleep 1
    echo ""
done

# Clean up
rm -f /tmp/ldes_response.txt

# Summary
echo "================================================"
echo "Ingestion Complete"
echo "================================================"
echo "Total files: ${total_files}"
echo "Successful: $((total_files - failed))"
echo "Failed: ${failed}"
echo ""

if [ "$failed" -eq 0 ]; then
    echo "All data ingested successfully!"
    echo ""
    echo "View the LDES stream at:"
    echo "  ${LDES_SERVER}/zalen"
    echo ""
    echo "View paginated data at:"
    echo "  ${LDES_SERVER}/zalen/by-page?pageNumber=1"
    exit 0
else
    echo "Some files failed to ingest. Please check the errors above."
    exit 1
fi
