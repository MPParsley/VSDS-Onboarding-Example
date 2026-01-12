#!/bin/bash
# Demo script for Leuven Zalen LDES Server and Consumer
# This script tears down everything and sets it all up from scratch

set -e

pause() {
  echo ""
  read -r -n 1 -s -p "Press any key to continue..."
  echo ""
}

echo "================================================"
echo "Gent LDES Demo"
echo "================================================"
echo ""

# Tear down everything
echo "Stopping and removing all containers..."
docker-compose down -v
echo "✓ All containers stopped and volumes removed"
pause

# Start all services
echo "Starting all Docker services..."
docker-compose up -d
pause

# Allow optional pipeline file parameter, default to pipeline.yml
PIPELINE_FILE=${1:-pipeline.yml}

echo "Using pipeline file: $PIPELINE_FILE"

# Wait for Fuseki to be ready
echo "Waiting for Fuseki to be ready..."
until curl -s http://localhost:3031/\$/ping > /dev/null; do
  echo "Fuseki not ready yet, waiting..."
  sleep 2
done
echo "Fuseki is ready!"

# Create dataset in Fuseki if it does not exist yet
echo "Ensuring dataset 'lpdc' exists in Fuseki..."
if curl -sf -u admin:admin http://localhost:3031/\$/datasets | grep -q '/lpdc\"'; then
  echo "Dataset already present, skipping creation."
else
  echo "Creating dataset 'lpdc' in Fuseki..."
  curl -X POST http://localhost:3031/\$/datasets \
    -u admin:admin \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data "dbName=lpdc&dbType=tdb2"
  echo "Dataset created!"
fi

# Setup RDF4J repository
./setup-rdf4j.sh

# Wait for LDIO workbench to be ready
echo "Waiting for LDIO workbench to be ready..."
until curl -s http://localhost:9006/actuator/health > /dev/null; do
  echo "LDIO workbench not ready yet, waiting..."
  sleep 2
done
echo "LDIO workbench is ready!"

# Upload pipeline
echo "Uploading pipeline to LDIO workbench..."
curl -X POST http://localhost:9006/admin/api/v1/pipeline \
  -H "Content-Type: application/yaml" \
  --data-binary @$PIPELINE_FILE

echo "Pipeline uploaded and started!"
echo ""
echo "========================================"
echo "Setup complete!"
echo "========================================"
echo "Fuseki UI: http://localhost:3031"
echo "  - Username: admin"
echo "  - Password: admin"
echo "  - Dataset: lpdc"
echo "  - SPARQL Query endpoint: http://localhost:3031/#/dataset/lpdc/query"
echo "  - Graph: http://stad.gent/lpdc/graph"
echo ""
echo "LDIO Workbench: http://localhost:9006"
echo "========================================"
