# Leuven Zalen LDES Server

This is a Linked Data Event Stream (LDES) server for publishing information about meeting rooms and halls (zalen) in Stad Leuven, based on OSLO standards.

## Overview

This LDES feed provides versioned information about public rooms and halls that can be reserved in Leuven. The data is modeled using:

- **OSLO Zaalreservatie**: https://data.vlaanderen.be/ns/zaalreservatie
- **OSLO Cultuur en Jeugd Infrastructuur**: https://data.vlaanderen.be/ns/cultuur-en-jeugd/infrastructuur
- **Schema.org**: For general properties (Place, maximumAttendeeCapacity, etc.)
- **DCTERMS**: For versioning metadata
- **PROV**: For temporal tracking

## Data Model

Each zaal (room/hall) is modeled as:
- `schema:Place` - Basic location and contact information
- `infrastructure:Infrastructuurobject` - Cultural/youth infrastructure
- Properties include:
  - Basic info: name, description, identifier
  - Location: address using OSLO address model
  - Capacity: maximum attendee capacity
  - Facilities: available amenities and equipment
  - Availability: opening hours, booking status
  - Accessibility: wheelchair access, public transport

## Sample Data

The server includes sample data for four Leuven zalen:

1. **Bosstraat Zaal 1** - Meeting room in administrative center (50 people)
2. **Raadzaal** - Historic council chamber in city hall (120 people)
3. **Celestijntje** - Cultural venue for workshops and events (80 people)
4. **Vlierbeekveld Zaal** - Multipurpose community center hall (100 people)

## Quick Start

### Prerequisites
- Docker
- Docker Compose

### Starting the Server

1. Navigate to this directory:
```bash
cd leuven-zalen-server
```

2. Start the services:
```bash
docker-compose up -d
```

3. Wait for the server to initialize (about 30 seconds)

4. Access the LDES stream:
```bash
curl http://localhost:9003/zalen
```

### Ingesting Sample Data

To ingest the sample zalen data into the LDES:

```bash
# Ingest Bosstraat Zaal 1
curl -X POST http://localhost:9003/ldes/zalen \
  -H "Content-Type: text/turtle" \
  --data-binary "@data/bosstraat-zaal1.ttl"

# Ingest Raadzaal
curl -X POST http://localhost:9003/ldes/zalen \
  -H "Content-Type: text/turtle" \
  --data-binary "@data/raadzaal.ttl"

# Ingest Celestijntje
curl -X POST http://localhost:9003/ldes/zalen \
  -H "Content-Type: text/turtle" \
  --data-binary "@data/celestijntje-zaal.ttl"

# Ingest Vlierbeekveld
curl -X POST http://localhost:9003/ldes/zalen \
  -H "Content-Type: text/turtle" \
  --data-binary "@data/vlierbeekveld-zaal.ttl"
```

Or ingest all at once:
```bash
for file in data/*.ttl; do
  echo "Ingesting $file..."
  curl -X POST http://localhost:9003/ldes/zalen \
    -H "Content-Type: text/turtle" \
    --data-binary "@$file"
  sleep 1
done
```

## API Endpoints

- **LDES Stream**: `http://localhost:9003/zalen`
- **Paginated View**: `http://localhost:9003/zalen/by-page`
- **Ingest Endpoint**: `POST http://localhost:9003/ldes/zalen`

## Architecture

```
┌─────────────────────┐
│   LDES Server       │
│   (Port 9003)       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   PostgreSQL        │
│   (Port 5432)       │
└─────────────────────┘
```

## Configuration Files

- `docker-compose.yml` - Service orchestration
- `.env` - Database credentials
- `config/application.yml` - LDES Server configuration with namespace prefixes
- `definitions/zalen.ttl` - LDES stream definition
- `definitions/zalen.by-page.ttl` - Pagination view definition
- `data/*.ttl` - Sample zalen data

## Versioning

The LDES uses temporal versioning:
- `prov:generatedAtTime` - Timestamp of each version
- `dcterms:isVersionOf` - Links versions to the immutable entity URI

Each update to a zaal creates a new version in the stream while preserving all historical versions.

## Data Format

All data is in Turtle (`.ttl`) format, using standard RDF/Linked Data principles.

Example:
```turtle
<https://www.leuven.be/raadzaal#2026-01-12T10:00:00Z>
  a schema:Place , infrastructure:Infrastructuurobject ;
  dcterms:isVersionOf <https://www.leuven.be/raadzaal> ;
  prov:generatedAtTime "2026-01-12T10:00:00Z"^^xsd:dateTime ;
  schema:name "Raadzaal"@nl ;
  schema:maximumAttendeeCapacity "120"^^xsd:integer ;
  zaalreservatie:beschikbaar true .
```

## Stopping the Server

```bash
docker-compose down
```

To also remove the data volume:
```bash
docker-compose down -v
```

## Extending the Dataset

To add more zalen:

1. Create a new `.ttl` file in the `data/` directory
2. Follow the same structure as existing samples
3. Ensure each version has:
   - Unique timestamped URI
   - `dcterms:isVersionOf` pointing to the base entity URI
   - `prov:generatedAtTime` with ISO 8601 timestamp
4. Ingest via POST to the LDES endpoint

## Related Resources

- [LDES Specification](https://semiceu.github.io/LinkedDataEventStreams/)
- [OSLO Zaalreservatie Vocabularium](https://data.vlaanderen.be/ns/zaalreservatie/)
- [OSLO Cultuur en Jeugd Infrastructuur](https://data.vlaanderen.be/doc/applicatieprofiel/cultuur-en-jeugd/infrastructuur/)
- [Leuven Zaalverhuur](https://www.leuven.be/zaalverhuur)
