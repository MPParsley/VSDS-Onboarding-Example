#!/bin/bash

# Script to configure RDF4J SPARQL repository pointing to Fuseki

echo "Waiting for RDF4J server to be ready..."
until curl -sf http://localhost:8080/rdf4j-server/repositories >/dev/null 2>&1; do
  echo "  RDF4J not ready yet, waiting..."
  sleep 2
done
echo "✓ RDF4J server is ready"

echo "Creating SPARQL repository 'lpdc' in RDF4J..."
curl -X PUT 'http://localhost:8080/rdf4j-server/repositories/lpdc' \
  --header 'Content-Type: text/turtle' \
  --data-raw '@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#>.
@prefix rep: <http://www.openrdf.org/config/repository#>.
@prefix sparql: <http://www.openrdf.org/config/sparql#>.
@prefix config: <tag:rdf4j.org,2023:config/>.

[] a config:Repository ;
  config:rep.id "lpdc" ;
  rdfs:label "SPARQL endpoint to Fuseki LPDC dataset" ;
  config:rep.impl [
      config:rep.type "openrdf:SPARQLRepository";
      config:sparql.queryEndpoint <http://fuseki:3030/lpdc/sparql>;
      config:sparql.updateEndpoint <http://fuseki:3030/lpdc/update>
  ].'

echo ""
echo "✓ RDF4J repository 'lpdc' created successfully"
