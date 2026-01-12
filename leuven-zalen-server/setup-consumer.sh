#!/bin/bash

# Setup script for Leuven Zalen LDES Consumer
# This script sets up Fuseki and starts the LDES consumer pipeline

set -e

FUSEKI_URL="http://localhost:3032"
LDIO_URL="http://localhost:9008"
DATASET_NAME="zalen"
PIPELINE_NAME="leuven-zalen-to-fuseki"

echo "================================================"
echo "Leuven Zalen LDES Consumer Setup"
echo "================================================"
echo ""

# Check if Fuseki is running
echo "Checking if Fuseki is running..."
max_attempts=30
attempt=0
while ! curl -s "${FUSEKI_URL}/$/ping" > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "Error: Fuseki did not start within expected time"
        echo "Check logs with: docker-compose logs fuseki"
        exit 1
    fi
    echo "Waiting for Fuseki to be ready... (attempt $attempt/$max_attempts)"
    sleep 2
done
echo "✓ Fuseki is running"
echo ""

# Check if LDIO Workbench is running
echo "Checking if LDIO Workbench is running..."
attempt=0
while ! curl -s "${LDIO_URL}/actuator/health" > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "Error: LDIO Workbench did not start within expected time"
        echo "Check logs with: docker-compose logs ldio-workbench"
        exit 1
    fi
    echo "Waiting for LDIO Workbench to be ready... (attempt $attempt/$max_attempts)"
    sleep 2
done
echo "✓ LDIO Workbench is running"
echo ""

# Check if dataset already exists
echo "Checking if dataset '${DATASET_NAME}' exists in Fuseki..."
if curl -s -u admin:admin "${FUSEKI_URL}/$/datasets" | grep -q "\"${DATASET_NAME}\""; then
    echo "✓ Dataset '${DATASET_NAME}' already exists"
else
    echo "Creating TDB2 dataset '${DATASET_NAME}' in Fuseki..."
    response=$(curl -s -w "\n%{http_code}" \
        -u admin:admin \
        -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "dbName=${DATASET_NAME}" \
        --data "dbType=tdb2" \
        "${FUSEKI_URL}/$/datasets")

    http_code=$(echo "$response" | tail -n 1)

    if [ "$http_code" -eq 200 ]; then
        echo "✓ Dataset '${DATASET_NAME}' created successfully"
    elif [ "$http_code" -eq 409 ]; then
        echo "✓ Dataset '${DATASET_NAME}' already exists (HTTP 409)"
    else
        echo "✗ Failed to create dataset (HTTP ${http_code})"
        echo "$response" | head -n -1
        exit 1
    fi
fi
echo ""

# Check if pipeline already exists
echo "Checking if pipeline '${PIPELINE_NAME}' exists..."
if curl -s "${LDIO_URL}/admin/api/v1/pipeline/${PIPELINE_NAME}/status" | grep -q "RUNNING\|STOPPED\|HALTED"; then
    echo "Pipeline '${PIPELINE_NAME}' already exists. Deleting and recreating..."
    curl -X DELETE "${LDIO_URL}/admin/api/v1/pipeline/${PIPELINE_NAME}" -s > /dev/null
    echo "✓ Old pipeline deleted"
    sleep 2
fi

# Upload pipeline configuration
echo "Uploading pipeline configuration..."
response=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Content-Type: application/yaml" \
    --data-binary "@pipeline.yml" \
    "${LDIO_URL}/admin/api/v1/pipeline")

http_code=$(echo "$response" | tail -n 1)

if [ "$http_code" -eq 201 ] || [ "$http_code" -eq 200 ]; then
    echo "✓ Pipeline '${PIPELINE_NAME}' created and started successfully"
else
    echo "✗ Failed to create pipeline (HTTP ${http_code})"
    echo "$response" | head -n -1
    exit 1
fi
echo ""

echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
echo "Your LDES consumer is now running and will start consuming data."
echo ""
echo "Services:"
echo "  • Fuseki:         ${FUSEKI_URL}"
echo "  • LDIO Workbench: ${LDIO_URL}"
echo "  • API/Swagger:    ${LDIO_URL}/swagger-ui/index.html"
echo ""
echo "Useful Commands and Queries:"
echo ""
echo "# Check pipeline status:"
echo "  curl ${LDIO_URL}/admin/api/v1/pipeline/${PIPELINE_NAME}/status"
echo ""
echo "# Count triples in Fuseki (run in Fuseki UI > Query tab):"
echo "  SELECT (COUNT(*) as ?count) WHERE { ?s ?p ?o }"
echo ""
echo "# Query zalen in Fuseki (list zaal names):"
echo "  PREFIX schema: <https://schema.org/>"
echo "  SELECT ?zaal ?name WHERE { ?zaal schema:name ?name }"
echo ""
echo "# Access Fuseki UI:"
echo "  Open ${FUSEKI_URL} in your browser"
echo "  Username: admin"
echo "  Password: admin"
echo ""
