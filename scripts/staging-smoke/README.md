# Staging Bash Smoke Tests

These scripts test the deployed backend through its public REST API. They do not connect directly to PostgreSQL, do not run the development seed, and do not contain real secrets.

## Requirements

- Bash
- `curl`
- Node.js
- Synthetic staging credentials stored outside Git

Run the scripts from WSL, Git Bash, Linux, or macOS.

On Windows, run them inside Git Bash or invoke Git Bash explicitly from PowerShell. Plain `bash` may launch WSL instead:

```powershell
& "C:\Program Files\Git\bin\bash.exe" --login -c "cd 'C:/Users/user/Desktop/Sam Proj/Workforce-Management' && bash scripts/staging-smoke/01-infrastructure.sh"
```

## Configure

```bash
cp scripts/staging-smoke/smoke.env.example scripts/staging-smoke/smoke.env
```

Fill `scripts/staging-smoke/smoke.env` locally. The file is gitignored.

## Run

Local Prisma validation, generation, typecheck, build, and Jest suite:

```bash
bash scripts/staging-smoke/00-local-release-checks.sh
```

Set `RUN_NPM_CI=true` when you also want a clean dependency install.

Public infrastructure checks:

```bash
bash scripts/staging-smoke/01-infrastructure.sh
```

Five-role authentication, authorization, and logout checks:

```bash
bash scripts/staging-smoke/02-auth-and-boundaries.sh
```

All non-data-creating checks:

```bash
bash scripts/staging-smoke/run-all.sh
```

Full core workflow:

```bash
RUN_CORE_WORKFLOW=true bash scripts/staging-smoke/03-core-workflow.sh
```

The core workflow:

- Hard-fails unless `/health` reports `environment = staging`.
- Creates two timestamped synthetic companies and four company role accounts.
- Tests geofence, face verification, attendance, shifts, leave, OKRs, reviews, notifications, reports, subscriptions, privacy, and cross-company scope.
- Leaves the synthetic company and accounts in staging for frontend verification.

`CORE_ACCOUNT_PASSWORD` is used for the four generated company accounts but is never printed. Store the generated account emails and password in the approved password manager.

## Migration Confirmation

Confirm in the Railway deployment logs that the pre-deploy command ran:

```bash
npm run prisma:migrate:deploy
```

Do not run migrations from this smoke-test toolkit and do not run `npm run seed` against staging.
