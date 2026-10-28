# App1 functional lab application

This deliberately small application validates the lab's complete request path without adding an application framework beyond the API itself:

```text
Browser -> Nginx frontend -> FastAPI backend -> PostgreSQL
```

- `frontend` serves static HTML, CSS, and JavaScript on port 80. Nginx proxies `/api/*` to the backend, so the browser never contacts the backend directly.
- `backend` serves a small FastAPI API on port 8080 and reports its container or pod hostname.
- `database` is a local PostgreSQL container used only by Docker Compose. It is not exposed to the host.

## Run locally in WSL

From the repository root:

```bash
cd app
cp .env.example .env
docker compose build
docker compose up -d
docker compose ps
```

Open <http://localhost:8080> in a browser, or test the proxied API directly:

```bash
curl http://localhost:8080/api/health
curl http://localhost:8080/api/db
curl -X POST http://localhost:8080/api/db/check
```

Inspect logs and stop the environment:

```bash
docker compose logs -f
docker compose down
```

To also discard the local PostgreSQL data volume:

```bash
docker compose down --volumes
```

The `.env.example` values are intentionally simple local-only credentials. Copying it to `.env` keeps local overrides out of Git.

## Database authentication modes

The same backend image supports two modes through `DB_AUTH_MODE`:

- `local` uses `DB_USER` and `DB_PASSWORD`. Docker Compose selects this mode for its local PostgreSQL container.
- `iam` uses the workload's AWS credentials and `boto3` to generate a short-lived RDS IAM authentication token. `DB_PASSWORD` is not used, and the PostgreSQL connection requires SSL. EKS will use this mode with its environment-specific backend workload identity.

Both modes use `DB_HOST`, `DB_PORT`, `DB_NAME`, and `DB_USER`. IAM mode additionally requires `AWS_REGION`. No database credentials are embedded in either image.

## Backend API and schema

- `GET /health` returns backend health and the container or pod hostname.
- `GET /db` verifies PostgreSQL connectivity and returns the existing check count without inserting a row.
- `POST /db/check` inserts one check record and returns its ID, timestamp, and the new total count.

The backend creates this lab table when needed:

```sql
CREATE TABLE app1_health_checks (
    id BIGSERIAL PRIMARY KEY,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

Important files are `frontend/nginx.conf` for API proxying, `frontend/static/` for the page, `backend/main.py` for the API and database logic, and `docker-compose.yml` for the local topology.
