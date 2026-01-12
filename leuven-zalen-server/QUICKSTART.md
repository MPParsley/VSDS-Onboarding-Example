# Quick Start Guide - Leuven Zalen LDES Server

This guide will get you up and running in 5 minutes.

## Prerequisites
- Docker
- Docker Compose
- curl (for testing)

## Setup Steps

### 1. Start the Services
```bash
cd leuven-zalen-server
docker-compose up -d
```

### 2. Wait for Initialization
The server takes 2-3 minutes to initialize. Wait until you see "Started Application":
```bash
docker-compose logs -f ldes-server
```

Press Ctrl+C when you see the startup message.

### 3. Initialize the LDES Stream
```bash
./setup-ldes.sh
```

This creates the event stream and configures the paginated view.

### 4. Load Sample Data
```bash
./ingest-data.sh
```

This ingests all 4 sample zalen (meeting rooms) into the LDES.

### 5. View Your Data
```bash
# View stream metadata
curl http://localhost:9003/zalen

# View actual data (the zalen members)
curl http://localhost:9003/zalen/by-page?pageNumber=1
```

## What You Get

After setup, you'll have 4 zalen available:

1. **Bosstraat Zaal 1** - Meeting room (50 capacity)
2. **Raadzaal** - Council chamber (120 capacity)
3. **Celestijntje** - Cultural venue (80 capacity)
4. **Vlierbeekveld Zaal** - Community center (100 capacity)

Each includes:
- Name, description, identifier
- Address (OSLO address model)
- Capacity
- Facilities and amenities
- Opening hours
- Contact information

## Next Steps

### Add Your Own Data
Create a new `.ttl` file in the `data/` directory following this template:

```turtle
@prefix schema: <https://schema.org/> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix prov: <http://www.w3.org/ns/prov#> .
@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
@prefix infrastructure: <https://data.vlaanderen.be/ns/cultuur-en-jeugd/infrastructuur#> .

<https://www.leuven.be/your-zaal#2026-01-12T10:00:00Z>
  a schema:Place , infrastructure:Infrastructuurobject ;
  dcterms:isVersionOf <https://www.leuven.be/your-zaal> ;
  prov:generatedAtTime "2026-01-12T10:00:00Z"^^xsd:dateTime ;
  schema:name "Your Zaal Name"@nl ;
  schema:maximumAttendeeCapacity "100"^^xsd:integer .
```

Then ingest it:
```bash
curl -X POST http://localhost:9003/zalen \
  -H "Content-Type: text/turtle" \
  --data-binary "@data/your-zaal.ttl"
```

### Clean Up
To stop and remove everything:
```bash
docker-compose down -v
```

## Troubleshooting

**Problem**: `curl: (52) Empty reply from server`
**Solution**: Server is still initializing. Wait 2-3 minutes and check logs.

**Problem**: `Resource of type: eventstream with id: zalen could not be found`
**Solution**: Run `./setup-ldes.sh` to create the event stream.

**Problem**: Data ingestion fails with validation errors
**Solution**: Ensure your data includes both `dcterms:isVersionOf` and `prov:generatedAtTime` properties.

## API Reference

- **Stream metadata**: `GET http://localhost:9003/zalen`
- **Paginated data**: `GET http://localhost:9003/zalen/by-page?pageNumber=1`
- **Ingest data**: `POST http://localhost:9003/zalen` (Content-Type: text/turtle)
- **Health check**: `GET http://localhost:9003/actuator/health`

## Resources

- [LDES Specification](https://semiceu.github.io/LinkedDataEventStreams/)
- [OSLO Zaalreservatie](https://data.vlaanderen.be/ns/zaalreservatie)
- [Full README](README.md) - Detailed documentation
- [Setup Notes](SETUP_NOTES.md) - Technical details about fixes
