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
echo "Leuven Zalen LDES Demo"
echo "================================================"
echo ""

# Tear down everything
echo "Stopping and removing all containers..."
docker-compose down -v
rm -f state/leuven-zalen-to-fuseki.db 
echo "✓ All containers stopped and volumes removed"
pause

# Start all services
echo "Starting all Docker services..."
docker-compose up -d
pause

# Wait for services to be healthy
echo "Waiting for services to be ready..."
echo "This may take up to 60 seconds..."
sleep 30

# Check if LDES server is healthy
max_attempts=30
attempt=0
while ! curl -s http://localhost:9003/actuator/health > /dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "✗ LDES server did not start in time"
        exit 1
    fi
    sleep 2
done
echo "✓ LDES server is ready"
pause

# Setup LDES server (event stream and view)
echo "Setting up LDES server..."
./setup-ldes.sh
pause

# Ingest sample data
echo "Ingesting sample data..."
./ingest-data.sh
pause

# Setup consumer (Fuseki dataset and LDIO pipeline)
echo "Setting up LDES consumer..."
./setup-consumer.sh
pause

# Wait for data to be consumed
echo "Waiting for data to be consumed (20 seconds)..."
sleep 20
pause

# Query Fuseki to verify data
echo "Verifying data in Fuseki triplestore..."
count=$(curl -s -X POST "http://localhost:3032/zalen/sparql" \
    --data-urlencode 'query=SELECT (COUNT(*) as ?count) WHERE { ?s ?p ?o }' \
    -H 'Accept: application/sparql-results+json' \
    -u admin:admin 2>/dev/null | \
    python3 -c "import sys, json; print(json.load(sys.stdin)['results']['bindings'][0]['count']['value'])")

echo "✓ Fuseki contains ${count} triples"
echo ""

# Query for zalen
echo "Querying for zalen..."
curl -s -X POST "http://localhost:3032/zalen/sparql" \
    --data-urlencode 'query=PREFIX schema: <https://schema.org/> SELECT DISTINCT ?name WHERE { ?zaal schema:name ?name } ORDER BY ?name' \
    -H 'Accept: application/sparql-results+json' \
    -u admin:admin 2>/dev/null | \
    python3 -c "import sys, json; results = json.load(sys.stdin)['results']['bindings']; print('\n'.join(['  • ' + r['name']['value'] for r in results]))"
echo ""

pause

echo "================================================"
echo "Demo Complete!"
echo "================================================"
echo ""
echo "Services running:"
echo "  • LDES Server:    http://localhost:9003/admin/doc/v1/swagger-ui/index.html"
echo "  • LDES Feed:      http://localhost:9003/zalen"
echo "  • LDES View:      http://localhost:9003/zalen/by-page?pageNumber=1"
echo "  • Fuseki:         http://localhost:3032 (admin/admin)"
echo "  • RDF4J:          http://localhost:8082"
echo "  • LDIO Workbench: http://localhost:9008/swagger-ui/index.html"
echo ""
echo "To stop all services:"
echo "  docker-compose down"
echo ""
