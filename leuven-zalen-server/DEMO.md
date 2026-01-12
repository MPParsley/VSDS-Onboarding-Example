# Leuven Zalen LDES Demo Scenario

This document describes a step-by-step demo scenario to showcase the Leuven Zalen LDES server and consumer setup.

## Prerequisites

Make sure you're in the `leuven-zalen-server` directory:
```bash
cd leuven-zalen-server
```

## Demo Scenario

### Step 1: Reset Everything

Tear down all containers and volumes to start fresh:

```bash
docker-compose down -v
```

Then start all services from scratch:

```bash
docker-compose up -d
```

Wait for services to be ready (about 30 seconds), then setup the LDES server:

```bash
./setup-ldes.sh
```

Ingest the initial sample data:

```bash
./ingest-data.sh
```

Setup the consumer (Fuseki dataset and LDIO pipeline):

```bash
./setup-consumer.sh
```

Wait 20 seconds for data to be consumed:

```bash
sleep 20
```

### Step 2: Query All Zalen

Query all zalen currently in the Fuseki triplestore:

```bash
curl -X POST "http://localhost:3032/zalen/sparql" \
  --data-urlencode 'query=PREFIX schema: <https://schema.org/> SELECT DISTINCT ?name WHERE { ?zaal schema:name ?name } ORDER BY ?name' \
  -H 'Accept: application/sparql-results+json' \
  -u admin:admin | python3 -m json.tool
```

**Expected result:** 3 zalen (Bosstraat Zaal 1, Celestijntje, Vlierbeekveld Zaal)

### Step 3: Ingest New Zaal Data

Ingest a new zaal (Raadzaal) into the LDES server:

```bash
curl -X POST http://localhost:9003/zalen \
  -H "Content-Type: text/turtle" \
  --data-binary "@data/demo/raadzaal.ttl"
```

Wait for the consumer to process the new data:

```bash
sleep 10
```

### Step 4: Query Zalen with Details

Query all zalen with their capacity, surface area, and facilities:

```bash
curl -X POST "http://localhost:3032/zalen/sparql" \
  --data-urlencode 'query=PREFIX schema: <https://schema.org/> PREFIX infra: <https://data.vlaanderen.be/ns/cultuur-en-jeugd/infrastructuur#> PREFIX zaalres: <https://data.vlaanderen.be/ns/zaalreservatie#> SELECT ?name ?capacity ?oppervlakte ?faciliteit WHERE { ?zaal schema:name ?name . OPTIONAL { ?zaal schema:maximumAttendeeCapacity ?capacity } OPTIONAL { ?zaal zaalres:oppervlakte ?oppervlakte } OPTIONAL { ?zaal infra:faciliteiten ?faciliteit } } ORDER BY ?name' \
  -H 'Accept: application/sparql-results+json' \
  -u admin:admin | python3 -m json.tool
```

**Expected result:** 4 zalen with their detailed properties:
- **Bosstraat Zaal 1**: capacity 50, oppervlakte 75 m², facilities: Beamer, WiFi, Flip-over
- **Celestijntje**: capacity 30, oppervlakte 45 m², facilities: WiFi, Whiteboard
- **Raadzaal**: capacity 100, oppervlakte 150 m², facilities: Microfoons, Beamer, WiFi, Geluidsinstallatie
- **Vlierbeekveld Zaal**: capacity 80, oppervlakte 120 m², facilities: Beamer, WiFi, Geluidsinstallatie

## Understanding the Flow

1. **LDES Server**: Publishes versioned zalen data as a Linked Data Event Stream
2. **LDIO Workbench**: Consumes the LDES feed and materializes members
3. **RDF4J Server**: Acts as a SPARQL proxy to Fuseki
4. **Fuseki**: Stores the materialized zalen data in a triplestore
5. **SPARQL Queries**: Retrieve and analyze the data

## Service URLs

- **LDES Server**: http://localhost:9003/zalen
- **LDES Paginated View**: http://localhost:9003/zalen/by-page
- **Fuseki UI**: http://localhost:3032 (admin/admin)
- **RDF4J Workbench**: http://localhost:8082
- **LDIO Workbench**: http://localhost:9008

## Automated Demo Script

To run the entire demo automatically:

```bash
./demo.sh
```

This script performs all steps automatically and verifies the setup is working correctly.

## Clean Up

To stop all services and remove volumes:

```bash
docker-compose down -v
```
