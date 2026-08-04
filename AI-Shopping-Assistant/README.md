# Léo: AI Shopping Assistant

A focused FastAPI prototype for the Atelier Home AI shopping assistant portfolio case study. Léo helps a shopper find, understand and compare fictional home and furniture products.

> **Important:** this is a public portfolio prototype. All products, prices, availability and images are fictional or illustrative and do not represent any live retailer catalogue.

The public version uses the fictional **Atelier Home** brand and a synthetic 12-product catalogue. It contains no retailer data, recruitment materials or production credentials.

## Live demo

Try the [client-only portfolio demo](https://antoniornavalhas.github.io/projects/ai-shopping-assistant/). It reproduces the main discovery and comparison flow entirely in the browser with the fictional catalogue, without an API key, backend, personal-data collection or live retailer data.

The live page is intentionally a static demonstration for GitHub Pages. The FastAPI implementation, API contracts, server-side conversation memory and optional provider integration remain available in this repository and can be run locally as described below.

## What it demonstrates

- Natural-language product discovery
- Hard filters for category, budget, dimensions, colour, material and sustainability
- Explainable ranking using catalogue attributes
- Follow-up memory, including “Why is it sustainable?”
- Natural-language and visual comparison for up to three products
- English, French and Portuguese; the page language and conversation language may differ
- Responsive editorial interface served by FastAPI
- Optional iaedu intent extraction with automatic deterministic fallback
- OpenAPI documentation at `/docs`

## Quick start

Python 3.11 or newer is recommended.

### Windows PowerShell

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

### macOS or Linux

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

Open [http://127.0.0.1:8000](http://127.0.0.1:8000).

## Demonstration flow

1. Ask: `Show me sustainable dining furniture`
2. Follow up: `Why is it sustainable?`
3. Ask: `Compare the first two`
4. Ask: `Procuro um sofá compacto abaixo de 1 000 €`
5. Select two product cards and use the visual **Compare** action.

## Demo mode and AI mode

The application is fully functional without an API key.

- **Demo mode:** local language detection and deterministic intent extraction.
- **AI mode:** one optional iaedu call converts the message into validated `SearchCriteria`. Python still retrieves, ranks and renders every product fact.
- **Fallback:** any timeout, quota or provider failure automatically uses Demo mode.

To enable AI mode:

1. Copy `.env.example` to `.env`.
2. Set `IAEDU_API_KEY`, `IAEDU_API_ENDPOINT` and `IAEDU_CHANNEL_ID` locally, using the values supplied by iaedu.
3. Optionally change `IAEDU_TIMEOUT_SECONDS` (default: 12).
4. Restart Uvicorn.

Never commit or send `.env`. The iaedu agent must be configured to return only the documented `SearchCriteria` JSON object. The browser never receives this key.

## Tests

```powershell
python -m pip install -r requirements-dev.txt
python -m pytest -q
```

The suite covers retrieval, multilingual budgets, sustainability evidence, follow-up context, comparison, API contracts and provider fallback.

## Project structure

```text
app/
├── main.py                 FastAPI routes and dependency wiring
├── config.py               Environment configuration
├── models.py               Pydantic contracts
├── repository.py           JSON catalogue and ranking
├── memory.py               In-memory conversation sessions
├── services/
│   ├── assistant.py        Conversation orchestration
│   └── intent.py           Local/iaedu intent extraction
├── templates/index.html    Server-rendered HTML shell
└── static/
    ├── css/styles.css
    ├── js/app.js
    └── images/             Local illustrative WebP assets
data/products.json          Fictional catalogue
tests/                      Automated backend/API tests
docs/                       Architecture and decision documents
```

## Known limitations

- Session memory is process-local, expires after one hour and is lost on restart.
- The catalogue contains only 12 fictional products.
- Demo-mode language detection intentionally handles a limited vocabulary.
- Availability, delivery, promotions, variants and live pricing are not integrated.
- Product imagery is AI-generated and illustrative.

See [Architecture](docs/ARCHITECTURE.md), [Decision log](docs/DECISION_LOG.md), [AI usage](docs/AI_USAGE.md) and [Test plan](docs/TEST_PLAN.md).
