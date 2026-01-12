#!/bin/bash

# Script to set up the LDES event stream and view
# This script should be run once after starting the LDES server
# Usage: ./setup-ldes.sh

set -e

LDES_SERVER="http://localhost:9003"
DEFINITIONS_DIR="definitions"

echo "================================================"
echo "Setting up Leuven Zalen LDES Server"
echo "================================================"
echo ""

# Check if server is running
echo "Checking if LDES server is running..."
if ! curl -s "${LDES_SERVER}/actuator/health" > /dev/null 2>&1; then
    echo "Error: LDES server is not running at ${LDES_SERVER}"
    echo "Please start the server with: docker-compose up -d"
    echo "Wait about 30 seconds for the server to fully initialize."
    exit 1
fi
echo "✓ Server is running"
echo ""

# Check if event stream already exists
echo "Checking if 'zalen' event stream exists..."
if curl -s "${LDES_SERVER}/zalen" 2>&1 | grep -q "could not be found"; then
    echo "Event stream does not exist. Creating..."

    # Create the event stream
    echo "Creating event stream from ${DEFINITIONS_DIR}/zalen.ttl..."
    response=$(curl -X POST "${LDES_SERVER}/admin/api/v1/eventstreams" \
        -H "Content-Type: text/turtle" \
        --data-binary "@${DEFINITIONS_DIR}/zalen.ttl" \
        -s -w "\n%{http_code}" -o /tmp/ldes_setup_stream.txt)

    http_code=$(echo "$response" | tail -n 1)

    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        echo "✓ Event stream created successfully"
    else
        echo "✗ Failed to create event stream (HTTP ${http_code})"
        cat /tmp/ldes_setup_stream.txt
        exit 1
    fi
else
    echo "✓ Event stream already exists"
fi
echo ""

# Create the paginated view
echo "Creating paginated view from ${DEFINITIONS_DIR}/zalen.by-page.ttl..."
response=$(curl -X POST "${LDES_SERVER}/admin/api/v1/eventstreams/zalen/views" \
    -H "Content-Type: text/turtle" \
    --data-binary "@${DEFINITIONS_DIR}/zalen.by-page.ttl" \
    -s -w "\n%{http_code}" -o /tmp/ldes_setup_view.txt 2>&1)

http_code=$(echo "$response" | tail -n 1)

if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
    echo "✓ Paginated view created successfully"
elif echo "$response" | grep -q "already exists"; then
    echo "✓ Paginated view already exists"
else
    echo "✗ Failed to create paginated view (HTTP ${http_code})"
    cat /tmp/ldes_setup_view.txt
    exit 1
fi

# Clean up
rm -f /tmp/ldes_setup_stream.txt /tmp/ldes_setup_view.txt

echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Your LDES server is ready to use:"
echo ""
echo "  LDES Stream:      ${LDES_SERVER}/zalen"
echo "  Paginated View:   ${LDES_SERVER}/zalen/by-page"
echo "  Ingest Endpoint:  POST ${LDES_SERVER}/zalen"
echo ""
echo "Next steps:"
echo "  1. Run ./ingest-data.sh to load sample data"
echo "  2. View the data at ${LDES_SERVER}/zalen/by-page?pageNumber=1"
echo ""
