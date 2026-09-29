# DBVC dashboard

The Angular dashboard presents the deterministic public demo served by the DBVC API.

```bash
npm install
npm start
```

The development server runs at `http://localhost:4200` and proxies `/api` to the backend on port `8080`.

```bash
npm test -- --watch=false
npm run build
```

The production image builds this application and serves it from the same origin as the API.
