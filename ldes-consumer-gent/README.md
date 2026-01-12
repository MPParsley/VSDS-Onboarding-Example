# LDES Consumer voor Gent LPDC met Fuseki Triplestore

Dit voorbeeld toont hoe je een LDES consumer opzet die de Gent LPDC (Lokale Producten- en Dienstencatalogus) feed consumeert en de data opslaat in een Apache Jena Fuseki triplestore.

## Overzicht

Deze setup gebruikt:
- **LDIO Workbench** (Linked Data Interactions Orchestrator): Voor het consumeren van de LDES feed
- **Apache Jena Fuseki**: Als RDF triplestore voor het opslaan van de data
- **LDES Client**: Component binnen LDIO voor het repliceren en synchroniseren van LDES views

## Architectuur

```
LDES Feed (Gent LPDC)
         ↓
   LDIO Workbench
   (LdesClient)
         ↓
    HttpSparqlOut
         ↓
   Fuseki Triplestore
   (TDB2 dataset)
```

## Data Source

De LDES feed bevat de Lokale Producten- en Dienstencatalogus van Stad Gent:
- **LDES URL**: https://ldes.stad.gent/ldes/lpdc
- **View URL**: https://ldes.stad.gent/ldes/lpdc/by-page?pageNumber=1

Deze feed bevat informatie over lokale overheidsdiensten en producten.

## Prerequisites

- Docker en Docker Compose geïnstalleerd
- Minimaal 2GB vrij geheugen voor Fuseki
- Internetverbinding voor toegang tot de LDES feed

> **Opmerking over netwerktoegang**: De Gent LPDC LDES feed kan netwerk beperkingen hebben afhankelijk van waar je de consumer draait. Als je problemen ondervindt met toegang tot `https://ldes.stad.gent/ldes/lpdc`, gebruik dan `pipeline-test.yml` die een publiek toegankelijke test feed gebruikt (Brugge observations) om de Fuseki integratie te valideren.

## Aan de slag

### 1. Start de services

Start de Docker containers:

```bash
cd ldes-consumer-gent
docker-compose up -d
```

Dit start:
- Fuseki triplestore op http://localhost:3031
- RDF4J server op http://localhost:8080
- LDIO Workbench op http://localhost:9006
  - API Documentatie: http://localhost:9006/v3/api-docs

### 2. Setup uitvoeren

Voer het setup script uit om de Fuseki dataset aan te maken en de pipeline te starten:

```bash
./setup.sh
```

Dit script:
1. Wacht tot Fuseki en LDIO Workbench ready zijn
2. Creëert een TDB2 dataset genaamd `lpdc` in Fuseki
3. Upload en start de LDES consumer pipeline

### 3. Controleer de status

**LDIO Workbench status:**
```bash
curl http://localhost:9006/admin/api/v1/pipeline/gent-lpdc-to-fuseki/status
```

**Controleer aantal triples in Fuseki:**
```bash
curl -X POST http://localhost:3030/lpdc/sparql \
  --data-urlencode "query=SELECT (COUNT(*) as ?count) WHERE { GRAPH <http://stad.gent/lpdc/graph> { ?s ?p ?o } }" \
  -H "Accept: application/sparql-results+json"
```

## Fuseki Triplestore

### Toegang

Fuseki heeft een web interface beschikbaar op:
- **URL**: http://localhost:3030
- **Username**: admin
- **Password**: admin

### Dataset informatie

- **Dataset naam**: `lpdc`
- **Type**: TDB2 (high-performance native RDF store)
- **Named Graph**: `http://stad.gent/lpdc/graph`

### SPARQL Endpoints

- **Query endpoint**: http://localhost:3030/lpdc/sparql
- **Update endpoint**: http://localhost:3030/lpdc/update (authentication required)
- **Graph Store Protocol**: http://localhost:3030/lpdc/data

### Voorbeeld SPARQL Queries

**Count alle statements:**
```sparql
SELECT (COUNT(*) as ?count)
WHERE {
  GRAPH <http://stad.gent/lpdc/graph> {
    ?s ?p ?o
  }
}
```

**Lijst van alle subjects (eerste 100):**
```sparql
SELECT DISTINCT ?subject
WHERE {
  GRAPH <http://stad.gent/lpdc/graph> {
    ?subject ?p ?o
  }
}
LIMIT 100
```

**Alle types in de dataset:**
```sparql
SELECT DISTINCT ?type (COUNT(?s) as ?count)
WHERE {
  GRAPH <http://stad.gent/lpdc/graph> {
    ?s a ?type
  }
}
GROUP BY ?type
ORDER BY DESC(?count)
```

**Specifiek item ophalen (vervang de URI):**
```sparql
DESCRIBE <URI_VAN_ITEM>
```

## Pipeline Configuratie

De pipeline is gedefinieerd in `pipeline.yml`:

```yaml
name: gent-lpdc-to-fuseki
description: "Consumes Gent LPDC LDES and stores members in Fuseki triplestore"
input:
  name: Ldio:LdesClient
  config:
    urls:
      - https://ldes.stad.gent/ldes/lpdc/by-page?pageNumber=1
    materialisation:
      enabled: true
outputs:
  - name: Ldio:HttpSparqlOut
    config:
      endpoint: http://fuseki:3030/lpdc/update
      graph: http://stad.gent/lpdc/graph
```

### Pipeline componenten

**Input: Ldio:LdesClient**
- Consumeert de LDES feed vanaf de opgegeven URL
- Volgt automatisch TREE relations voor paginatie
- Synchroniseert continu voor nieuwe members
- Materialiseert versioned objects naar hun laatste staat (via `materialisation: enabled: true`)

**Output: Ldio:HttpSparqlOut**
- Schrijft LDES members naar de triplestore via SPARQL UPDATE
- Maakt verbinding met Fuseki's SPARQL update endpoint
- Vervangt oude versies van members met nieuwe versies
- Slaat data op in de opgegeven named graph

## Monitoring

### LDIO Workbench

**API Documentatie:**
- OpenAPI/Swagger specificatie: http://localhost:9006/v3/api-docs
- Actuator health: http://localhost:9006/actuator/health

Bekijk pipeline status:
```bash
curl http://localhost:9006/admin/api/v1/pipeline
```

Bekijk pipeline metrics:
```bash
curl http://localhost:9006/actuator/metrics
```

### Fuseki

Bekijk Fuseki stats via de web UI:
- Ga naar http://localhost:3030
- Selecteer de `lpdc` dataset
- Klik op "info" voor dataset statistieken

## Logs bekijken

**LDIO Workbench logs:**
```bash
docker logs -f ldio-workbench
```

**Fuseki logs:**
```bash
docker logs -f fuseki
```

## Stoppen en herstarten

**Stop alle services:**
```bash
docker-compose down
```

**Stop en verwijder data (WAARSCHUWING: dit verwijdert alle opgeslagen data):**
```bash
docker-compose down -v
```

**Herstart services:**
```bash
docker-compose up -d
```

## Troubleshooting

### Pipeline start niet

Controleer of Fuseki actief is:
```bash
curl http://localhost:3030/$/ping
```

Controleer LDIO logs:
```bash
docker logs ldio-workbench
```

### LDES feed niet bereikbaar (403 Forbidden)

Als je een 403 error krijgt bij toegang tot de Gent LPDC feed, kan dit komen door netwerk beperkingen. Gebruik de test pipeline om de setup te valideren:

```bash
# Gebruik de test pipeline met Brugge LDES feed
./setup.sh pipeline-test.yml
```

Of upload handmatig:
```bash
curl -X POST http://localhost:9006/admin/api/v1/pipeline \
  -H "Content-Type: application/yaml" \
  --data-binary @pipeline-test.yml
```

De test pipeline gebruikt een publiek toegankelijke LDES feed en valideert dat:
- LDIO Workbench correct werkt
- Fuseki verbinding succesvol is
- HttpSparqlOut correct functioneert

### Geen data in Fuseki

1. Controleer of de pipeline actief is:
```bash
curl http://localhost:9006/admin/api/v1/pipeline/gent-lpdc-to-fuseki/status
# Of voor test pipeline:
curl http://localhost:9006/admin/api/v1/pipeline/test-ldes-to-fuseki/status
```

2. Controleer of de LDES feed bereikbaar is:
```bash
curl -I https://ldes.stad.gent/ldes/lpdc/by-page?pageNumber=1
```

3. Bekijk LDIO logs voor errors:
```bash
docker logs ldio-workbench
```

### Memory issues

Als Fuseki te weinig geheugen heeft, pas de JVM_ARGS aan in `docker-compose.yml`:
```yaml
environment:
  - JVM_ARGS=-Xmx4g  # Verhoog naar 4GB
```

## Advanced Usage

### Backup maken van de data

```bash
# Exporteer alle data van de named graph
curl -X GET "http://localhost:3030/lpdc/data?graph=http://stad.gent/lpdc/graph" \
  -H "Accept: application/n-triples" \
  -u admin:admin \
  -o backup.nt
```

### Data importeren

```bash
# Importeer data naar de named graph
curl -X POST "http://localhost:3030/lpdc/data?graph=http://stad.gent/lpdc/graph" \
  -H "Content-Type: application/n-triples" \
  -u admin:admin \
  --data-binary @backup.nt
```

### Pipeline pauzeren

```bash
# Stop de pipeline
curl -X POST http://localhost:9006/admin/api/v1/pipeline/gent-lpdc-to-fuseki/halt

# Herstart de pipeline
curl -X POST http://localhost:9006/admin/api/v1/pipeline/gent-lpdc-to-fuseki/resume
```

## Referenties

- [LDES Specificatie](https://semiceu.github.io/LinkedDataEventStreams/)
- [LDIO Documentatie](https://informatievlaanderen.github.io/VSDS-Linked-Data-Interactions/)
- [Apache Jena Fuseki](https://jena.apache.org/documentation/fuseki2/)
- [SPARQL 1.1 Query Language](https://www.w3.org/TR/sparql11-query/)
- [Gent Open Data Portal](https://data.stad.gent/)

## Over LPDC

De Lokale Producten- en Dienstencatalogus (LPDC) is een catalogus van producten en diensten aangeboden door lokale overheden in Vlaanderen. Door deze data als LDES te publiceren, kunnen andere systemen:
- De volledige catalogus repliceren
- Continu synchroniseren met updates
- Efficiënt zoeken en filteren op de data
- De data combineren met andere datasets
