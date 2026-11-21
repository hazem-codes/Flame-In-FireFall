# Flame in Freefall

Search NASA PSI combustion investigations by fire-safety needs. The backend ranks investigations from the active filters. Gemini selects up to three candidate experiments per investigation and provides qualitative interpretation. Run-level findings and verified report citations come from the backend.

```
flame-in-freefall/
├── start.bat            ← double-click: everything at http://127.0.0.1:5000
├── dev.bat              ← for editing the frontend (live reload at http://localhost:5173)
├── build-frontend.bat   ← rebuild the frontend after changing frontend/src
├── shared/schemas/      ← the JSON contract both sides use
├── backend/             ← Python (Flask) + Gemini
└── frontend/            ← React + TypeScript (Vite)
```

## How the two halves connect

```
frontend/src/lib/api.ts  ──HTTP──▶  backend/app.py  ──▶  pipeline.py + gemini_client.py ──▶ Gemini
        │                                │
        └──── both validate with ────────┘
              shared/schemas/*.json
```

| Frontend calls (`frontend/src/lib/api.ts`) | Backend route (`backend/app.py`) | Returns |
|---|---|---|
| `getStatus()` | `GET /api/status` | Live or saved-example mode, model, loaded investigations |
| `search()` | `POST /api/search` with `{input, research_question}` | `{output, meta}`; `output` follows `output.schema.json` |
| Compatibility endpoint | `GET /api/records?experiment_ids=A,B` | Per-test chart data, also bundled in the search response |
| PDF evidence links | `GET /api/reports/<psi-id>/<filename>` | A local report with support for PDF range requests |

- `input` follows `shared/schemas/input.schema.json` (the filters).
- `output` follows `shared/schemas/output.schema.json` (ranking, top experiments, comparison, insights).
- `meta` says how the result was made (model, seconds, corrections). Type: `RunMeta` in `frontend/src/types.ts`.
- `research_question` is saved with each run in `backend/runs/` but not sent to Gemini yet (reserved for the planned chat).

In production the backend serves the built frontend (`frontend/dist`), so both use the same address. In development, `frontend/vite.config.ts` forwards `/api` to the backend on port 5000.

## Prerequisites

Before running the project, make sure the following software is installed:

- **Python 3.14.x** – Required for the backend. Python must be available through the system `PATH`.
  - Download: https://www.python.org/downloads/

- **Node.js 22.x LTS** – Required for the frontend build and development server. Node.js must be available through the system `PATH`. npm is included with the Node.js installation.
  - Download: https://nodejs.org/en/download

The `start.bat` and `dev.bat` launchers automatically check for the required versions and stop with an error message if either requirement is not met.

Python and frontend dependencies are installed automatically by the respective launch scripts. No separate installation of project libraries is necessary.

## Run

**Normal use:** double-click `start.bat`, then open http://127.0.0.1:5000. The first run installs packages and builds the frontend (needs Node.js), which takes a few minutes.

**Editing the frontend:** double-click `dev.bat` and open http://localhost:5173. Changes in `frontend/src` show up immediately. Run `build-frontend.bat` when done, so `start.bat` serves the new version.

**Editing the backend:** change files in `backend/`, then close the window and run `start.bat` again.

## Settings: `backend/.env`

| Setting | Meaning |
|---|---|
| `GEMINI_API_KEY` | Your key. Without it the app returns the saved example. |
| `GEMINI_MODEL` | Model ID, default `gemini-3.5-flash-lite` (fastest). |
| `GEMINI_FALLBACK_MODEL` | Used automatically if the main model is overloaded. |
| `REPORT_MODE` | `text` (bounded report excerpts, default), `pdf` (whole PDFs through the Gemini Files API), `none` |

`start.bat` copies `.env` from the old `..\flame-dashboard` folder the first time, if it finds one.

## Add an investigation

1. Build its record: `backend/data/psi/<PSI-ID>/record.json`, following `shared/schemas/investigation.schema.json`. The scripts in `backend/tools/` built FLEX and BASS-II; copy one and adapt it to the new table.
   - `condition_sets` = the experiments (IDs like `PSI-69-CS56`), used for ranking.
   - `tests` = one row per test run with numbers, used for the charts.
2. Put its PDF reports in `backend/data/psi/<PSI-ID>/reports/`.
3. Restart. The new investigation is picked up automatically; nothing in the frontend changes.

## Where to change things

| To change | Edit |
|---|---|
| What Gemini is told | `backend/prompts/system_prompt.md` |
| Which experiments and report pages are sent | `backend/pipeline.py` (`score_experiment`, `select_report_pages`) |
| Gemini call, retries, fallback model | `backend/gemini_client.py` |
| API routes | `backend/app.py` |
| The filters / the result format | `shared/schemas/*.json`, then `frontend/src/types.ts` to match |
| Page layout and charts | `frontend/src/pages`, `frontend/src/components` |

Every search is logged in `backend/runs/<time>/` (input, Gemini's raw answer, output, timings).

## Verification

Run `python -m unittest discover -s tests -v` in `backend/` after installing its requirements. From `frontend/`, run `npm ci`, `node --test tests/chartData.test.mjs`, and `npm run build`. The tests do not need a Gemini key.
