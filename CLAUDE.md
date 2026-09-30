# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

"Wie is de volgende jarige?" — a small Dutch-language app: a group shares a code, and the app shows whose birthday is next within that group. Vue 3 + Vite SPA, backed by Cloudflare Pages Functions and a Cloudflare D1 (SQLite) database. User-facing text is in Dutch.

## Commands

```sh
npm install
echo y | npm run create-dev-database   # apply migrations/ to the local D1 db (.wrangler/state)
npm run build && npm run devserver     # full app (SPA + functions + D1) via wrangler on :4242
npm run dev                            # Vite only, hot reload; proxies /api to wrangler on :8788

npx vitest run                         # all tests (npm test starts watch mode)
npx vitest run test/date.test.ts       # single file
npx vitest run -t "parseRequestBody"   # single test by name

npm run type-check                     # vue-tsc
npm run lint                           # eslint with --fix
npm run format                         # prettier on src/ and root *.json
```

CI (`.github/workflows/default.yaml`) runs prettier, type-check, eslint and `vitest run`, then deploys `dist/` to Cloudflare Pages on every push to `main`.

`wrangler pages dev` serves the built `dist/`, so rebuild after frontend changes when using `devserver`. For hot reload, run `npm run dev` alongside `npx wrangler pages dev` (default port 8788, which the Vite proxy targets).

The local database is seeded by `migrations/0002_insert_test_data.sql` with group code `test123`; open `/code/test123` or `GET /api/birthdays/test123/next`.

## Architecture

- **`src/`**: the SPA. Routes are defined in `src/router/index.ts`: `/` (enter a group code), `/code/:code` (result), `/add` (register a birthday). All API calls go through `src/lib/api.ts`. `src/lib/birthday.ts` converts raw JSON (ISO date strings) into objects with `Date`/`URL` fields. Styling is Tailwind v4 via the Vite plugin.
- **`functions/`**: Cloudflare Pages Functions with file-based routing.
  - `functions/api/birthdays.ts`: `POST /api/birthdays`. `parseRequestBody` validates input and throws `ValidationError`, which becomes a 422. The `website` field only accepts `lijstje.nl` URLs.
  - `functions/api/birthdays/[code]/next.ts`: `GET /api/birthdays/:code/next`. By default it returns only the people sharing the soonest upcoming birthday. `?all=1` returns the whole group sorted by next birthday, and `?type=<species>` filters by species.
  - `functions/database.ts` holds the SQL. Next birthday and age are computed in JS (`functions/date.ts`), not in SQL.
  - The D1 binding is `DB` (`Env` in `functions/types.ts`). It's configured in `wrangler.toml`; the preview database is `volgendeverjaardag_preview` and production uses `[env.production]`.
- **Types are duplicated** between frontend and backend: `allowedSpecies`/`Species`/`Birthday` exist in both `src/lib/birthday.ts` and `functions/types.ts`. Keep them in sync.
- **Schema changes** go in a new numbered file in `migrations/`, created with `npx wrangler d1 migrations create volgendeverjaardag_preview <name>`. `birth_date` is stored as a `YYYY-MM-DD` string.
- **Tests** live in `test/` (the only path vitest includes) and import backend modules directly from `functions/`. There are no frontend component tests.
- **TypeScript projects**: `tsconfig.json` references only `tsconfig.app.json` (src) and `tsconfig.node.json`. `tsconfig.functions.json` isn't referenced, so `npm run type-check` doesn't type-check `functions/`.

## Cloud sessions

`.claude/hooks/session-start.sh` runs `npm install` and applies the local migrations at the start of each Claude Code on the web session, mirroring `.devcontainer/devcontainer.json`.
