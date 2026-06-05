# STAGING ENV CHECKLIST

Use this checklist in the hosting provider dashboard or secret manager before starting the staging backend. Do not put real staging secrets in this repository, `.env.example`, screenshots, tickets, or Lovable prompts.

## Staging URL Status

```text
STAGING_BACKEND_URL=https://workforce-management-production.up.railway.app
```

Verified on June 5, 2026: `/health` and `/ready` pass against this Railway staging URL.

## Required Staging Variables

| Variable | Required Value / Source | Notes |
| -------- | ----------------------- | ----- |
| `NODE_ENV` | `staging` | Enables deployed-environment validation. |
| `PORT` | Hosting provider assigned port or `4000` | The app defaults to `4000`, but the hosting platform may inject a port. |
| `DATABASE_URL` | Secret-managed PostgreSQL connection URL | Required in staging. Never commit it. |
| `JWT_SECRET` | Secret-managed high-entropy value | Required in staging. Used as access-token fallback. |
| `JWT_REFRESH_SECRET` | Secret-managed high-entropy value | Required in staging even though no refresh endpoint exists yet. |
| `CORS_ORIGIN` or `CORS_ORIGINS` | Exact frontend/Lovable origin(s) | Required in staging. Do not use `*`. Add the Lovable/frontend origin once available. |
| `LOG_LEVEL` | `info` recommended | Allowed values: `debug`, `info`, `warn`, `error`. |

## Optional Current Variables

| Variable | Recommended Staging Value | Notes |
| -------- | ------------------------- | ----- |
| `JWT_ACCESS_SECRET` | Optional secret-managed high-entropy value | Overrides `JWT_SECRET` for access-token signing when set. |
| `JWT_ACCESS_TTL` | `15m` unless changed intentionally | Optional. |
| `JWT_REFRESH_TTL` | `7d` unless changed intentionally | Optional; refresh endpoint is not implemented. |
| `FACE_PROVIDER` | `mock` | CP8 staging uses the mock provider unless a real provider is explicitly implemented later. |
| `STORAGE_PROVIDER` | `local` or provider-specific staging value | Placeholder only; no production file-storage workflow is implemented. |

## Optional / Future Integration Placeholders

Leave these unset unless a future checkpoint or approved provider implementation makes them real. They are placeholders only and are not required for CP15 manual billing.

| Variable | Required Now | Notes |
| -------- | ------------ | ----- |
| `STRIPE_SECRET_KEY` | No | Placeholder only. CP15 supports manual billing records, not live Stripe charging. |
| `TWILIO_ACCOUNT_SID` | No | Placeholder only. SMS delivery is not implemented. |
| `TWILIO_AUTH_TOKEN` | No | Placeholder only. Do not add Twilio secrets until SMS is implemented. |
| `EMAIL_PROVIDER` | No | Placeholder only. Email delivery is not implemented. |

## CORS Rules

- Set `CORS_ORIGIN` to one exact frontend origin when there is a single frontend URL.
- Use `CORS_ORIGINS` for comma-separated additional origins.
- Do not use wildcard `*`; startup validation rejects wildcard origins with credentials.
- Add the Lovable frontend origin once Lovable creates it.
- CORS errors must be fixed by updating backend allowlist variables or correcting frontend request origins, not by bypassing auth.

## Secret Handling Rules

- Use the hosting provider dashboard, secret manager, or environment-variable manager.
- Do not commit real staging secrets.
- Do not paste secrets into docs, prompts, issue descriptions, or chat.
- Rotate staging secrets if they are exposed.
- Local `.env.example` values are development placeholders only.

## Pre-Start Verification

- `NODE_ENV=staging` is set.
- `DATABASE_URL` is set and points to the staging PostgreSQL database.
- `JWT_SECRET` and `JWT_REFRESH_SECRET` are set to different high-entropy values.
- At least one explicit CORS origin is set.
- `LOG_LEVEL` is set.
- Future integration placeholders are blank unless intentionally implemented.

## Post-Deploy Documentation Updates

After staging is live:

1. Record the real backend staging URL in the deployment notes.
2. Keep handoff usage aligned with `https://workforce-management-production.up.railway.app`.
3. Update `docs/TEST_ACCOUNTS.md` with synthetic staging account emails and company name only.
4. Keep passwords and secrets in the approved password manager or staging secret store.
