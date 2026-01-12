# Setup Notes - Leuven Zalen LDES Server

## Issues Fixed

### 1. Port Mapping Issue
**Problem**: The LDES server was returning "Empty reply from server" (curl error 52).

**Root Cause**: The docker-compose.yml had incorrect port mapping. The LDES server listens on port 8080 internally, but the port mapping was configured as `9003:80`.

**Solution**: Updated docker-compose.yml to map `9003:8080`.

### 2. Missing Environment Variables
**Problem**: Warning messages in logs about missing SIS_DATA and other configuration issues.

**Root Cause**: The docker-compose.yml was missing several environment variables present in the reference minimal-server example.

**Solution**: Added the following environment variables to docker-compose.yml:
- `SIS_DATA=/tmp` - Fixes the SIS_DATA warning
- `SPRING_BATCH_JDBC_INITIALIZESCHEMA=always` - Ensures proper database initialization
- `MANAGEMENT_TRACING_ENABLED=false` - Disables unnecessary tracing
- `SPRING_TASK_SCHEDULING_POOL_SIZE=5` - Configures task scheduling

### 3. Configuration Volume Path
**Problem**: Application configuration wasn't being loaded correctly.

**Root Cause**: The config volume was mounted to `/config/application.yml` instead of `/application.yml`.

**Solution**: Changed volume mount from `./config/application.yml:/config/application.yml:ro` to `./config/application.yml:/application.yml:ro`.

### 4. Removed SPRING_CONFIG_LOCATION
**Problem**: Environment variable `SPRING_CONFIG_LOCATION=/config/` was conflicting with the volume mount.

**Solution**: Removed this environment variable as it's not needed when mounting the config file directly to `/application.yml`.

### 5. Stream Definition Version Creation
**Problem**: Data ingestion was failing with SHACL validation errors about duplicate timestamp and versionOf properties.

**Root Cause**: The LDES stream definition had `ldes:createVersions true`, which meant the server would automatically add versioning properties. However, the sample data already included these properties (`dcterms:isVersionOf` and `prov:generatedAtTime`).

**Solution**: Changed `ldes:createVersions true` to `ldes:createVersions false` in `definitions/zalen.ttl`.

### 6. Added Healthcheck
**Problem**: No easy way to verify when the server is fully initialized.

**Solution**: Added healthcheck configuration to docker-compose.yml:
```yaml
healthcheck:
  test: ["CMD", "wget", "-qO-", "http://ldes-server:8080/actuator/health"]
```

## Automation Scripts Created

### setup-ldes.sh
Automates the initial setup of the LDES server:
- Checks if server is running
- Creates the event stream from `definitions/zalen.ttl`
- Creates the paginated view from `definitions/zalen.by-page.ttl`
- Provides clear feedback and next steps

### ingest-data.sh
Automates loading sample data:
- Validates server availability
- Ingests all .ttl files from the data/ directory
- Provides progress feedback with counters
- Reports success/failure for each file
- Shows final summary with viewing URLs

## Updated Documentation

### README.md Improvements
1. **Quick Start section**: Added automated setup instructions using the new scripts
2. **Manual Setup section**: Preserved detailed manual instructions for advanced users
3. **API Endpoints**: Expanded to include both public and admin endpoints
4. **Project Structure**: Added visual tree showing all files and their purposes
5. **Troubleshooting section**: Added common issues and their solutions
6. **Corrected endpoints**: Changed incorrect `/ldes/zalen` to `/zalen` for ingestion

## Startup Time
The LDES server takes approximately 2-3 minutes to fully initialize. This is normal and due to:
- Database schema migration (Liquibase changesets)
- Spring Boot application initialization
- Derby spatial database initialization

Users can monitor startup progress with:
```bash
docker-compose logs -f ldes-server
```

And wait for the message:
```
Started Application in X seconds
```

## Testing Results
All four sample zalen were successfully ingested and are accessible via:
- http://localhost:9003/zalen (stream metadata)
- http://localhost:9003/zalen/by-page?pageNumber=1 (actual data)

Sample data includes:
1. Bosstraat Zaal 1 (50 people capacity)
2. Raadzaal (120 people capacity)
3. Celestijntje (80 people capacity)
4. Vlierbeekveld Zaal (100 people capacity)
