# Test plan

## Automated scope

Run:

```powershell
python -m pytest -q
```

The suite checks:

- JSON catalogue validation through Pydantic
- Sustainable dining retrieval returns only products with evidence
- Compact and budget constraints are hard filters
- Unknown product IDs cannot enter a response
- English, French and Portuguese price formats
- Portuguese dining and sustainability intent
- iaedu failure or malformed output falls back locally
- Follow-up sustainability explanation uses the previous results
- Visual product selection produces a comparison without an LLM call
- Message-language detection with conversation-language fallback for short follow-ups
- FastAPI serves HTML, health and chat contracts

## Manual acceptance tests

| ID | Action | Expected |
|---|---|---|
| M1 | Start Uvicorn without `.env` | Page loads and badge shows Demo mode |
| M2 | Ask `Show me sustainable dining furniture` | Extend and Cane are returned |
| M3 | Follow with `Why is it sustainable?` | The same products receive specific FSC evidence; no new generic search |
| M4 | Follow with `Compare the first two` | A two-column factual comparison appears |
| M5 | Ask `I need a compact sofa under €1,000` | Only qualifying sofas appear; Harbor is excluded |
| M6 | Ask `Procuro um sofá compacto abaixo de 1 000 €` | Portuguese response and correct budget |
| M7 | Ask `Je cherche un bureau compact à moins de 300 €` | French response and Forge result |
| M8 | Select two product `+` controls and compare | Comparison uses exactly the selected products |
| M9 | Open product details | Dimensions, material, price and evidence match JSON |
| M10 | Change the language selector, then send a message in another supported language | Static UI remains in the selected language; Léo answers in the language of the message |
| M11 | Resize browser to 390 px | Chat, cards, modal and comparison remain usable |
| M12 | Open `/docs` | Interactive FastAPI documentation is available |
| M13 | Configure invalid iaedu credentials | Request falls back to Demo mode without failing |
| M14 | Start a new chat | Previous session is deleted and follow-up context clears |

## Production evaluation

Create a versioned, anonymised evaluation set representing real catalogue queries and markets. At minimum, measure:

- intent and entity extraction accuracy;
- hard-constraint adherence;
- retrieval recall@k and nDCG;
- product-fact groundedness;
- unsupported sustainability-claim rate;
- multilingual quality;
- p50/p95 end-to-end latency;
- provider fallback rate and cost per session;
- product click, comparison and add-to-basket outcomes.

Require regression thresholds in CI before changes to prompts, models, taxonomy or ranking.
