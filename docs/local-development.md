# Local development

## Web application

```powershell
cd backend
npm ci
npm start
```

In another terminal:

```powershell
cd frontend
npm ci
npm start
```

Open `http://localhost:4200`.

## Engine checks

```powershell
./engine/Test-Dbvc.ps1
```

These tests do not need SQL Server. `Verify` and `Apply` require `sqlcmd` and an explicitly configured target.

## Containers

`docker compose up --build app` starts the safe web demo. `docker compose up sqlserver` starts an optional local SQL Server Developer instance. Choose your own strong password in `.env`; the Compose fallback is local-only and must never be reused.
