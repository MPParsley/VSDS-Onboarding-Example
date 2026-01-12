#!/bin/bash

# Allow optional pipeline file parameter, default to pipeline.yml
PIPELINE_FILE=${1:-pipeline.yml}

echo "Using pipeline file: $PIPELINE_FILE"

# Wait for Fuseki to be ready
echo "Waiting for Fuseki to be ready..."
until curl -s http://localhost:3031/$/ping > /dev/null; do
  echo "Fuseki not ready yet, waiting..."
  sleep 2
done
echo "Fuseki is ready!"

# Create dataset in Fuseki
echo "Creating dataset 'lpdc' in Fuseki..."
curl -X POST http://localhost:3031/$/datasets \
  -u admin:admin \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data "dbName=lpdc&dbType=tdb2"

echo "Dataset created!"

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
