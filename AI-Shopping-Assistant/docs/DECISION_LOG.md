# Decision log

## What I decided to build

A narrow, testable discovery-to-comparison journey for home and furniture:

- describe a need in natural language;
- retrieve products that respect hard constraints;
- understand why each option was returned;
- ask contextual follow-up questions;
- compare up to three products through conversation or visual selection.

The prototype is a Python FastAPI application serving Jinja2 HTML, CSS and vanilla JavaScript. Product data lives in JSON. The optional LLM performs one structured intent-extraction call; Python owns product selection and all factual output.

## Decisions made

| Decision | Choice | Rationale |
|---|---|---|
| Python framework | FastAPI | Typed API contracts, OpenAPI docs and reuse by web/mobile |
| Catalogue | Local JSON | Portable, readable and replaceable behind a repository |
| Intelligence | Hybrid with deterministic fallback | Real optional AI without making the demo dependent on credentials |
| Provider | iaedu streaming API | Uses the course-provided chatbot credentials without exposing them to the browser |
| Provider response | Strict `SearchCriteria` JSON | Validated before local retrieval; product facts stay in Python |
| LLM calls | One per message, intent only | Lower cost/latency and fewer hallucination paths |
| Retrieval | Attribute filters + scoring | Exact constraints matter more than semantic breadth in this MVP |
| Conversation state | In-memory Python store | Simple follow-ups plus one anonymous iaedu thread per session |
| Languages | Local EN/FR/PT templates | Multilingual fallback works without an API |
| Frontend | Jinja2 + vanilla JavaScript | Full design control without Node/build tooling |
| Visual format | Editorial page with embedded assistant | Demonstrates realistic commerce integration |
| Catalogue scope | Home and furniture | Rich objective attributes for comparison |
| Sustainability | Specific evidence | Avoids unsupported `sustainable=true` claims |
| Comparison | Natural language + visual selection | Conversational and predictable paths |
| Images | Local AI-generated editorial photography | Portable, consistent and clearly illustrative |
| Tests | Pytest backend/API + manual UI plan | High confidence for the most important logic |
| Dependencies | `requirements.txt` | Lowest-friction evaluator setup |
| Deployment | Local Uvicorn, no Docker | Infrastructure is not needed to assess the MVP |
| Assistant name | Léo, explicitly conceptual | Memorable across supported languages without claiming official status |

## What I decided not to build

- Live PIM, stock, pricing, promotions, product variants or basket integration
- Checkout, authentication, accounts or order history
- Behavioural personalisation or persistent customer profiles
- Vector database or embeddings in the four-hour version
- A second LLM call for natural response generation
- Voice, visual search or autonomous purchasing
- Native mobile application; the responsive web contract demonstrates the shared flow
- Redis, containerisation, CI/CD or cloud infrastructure

## Assumptions

- A production catalogue exposes stable product IDs, market-specific price and stock, dimensions, materials, variants and evidence fields.
- Discovery and comparison create more early value than agentic checkout.
- Anonymous use should work; personalisation requires consent.
- English, French and Portuguese are demonstration languages, not a launch-market commitment.
- The product source of truth must always override the model.
- The four-hour limit rewards a coherent vertical slice rather than nominal feature breadth.

## Prioritisation

| Capability | Customer value | Learning value | Delivery risk | Result |
|---|---:|---:|---:|---|
| Needs-based discovery | High | High | Low | Built |
| Grounded explanation | High | High | Low | Built |
| Contextual follow-ups | High | High | Medium | Built |
| Product comparison | High | High | Low | Built |
| Multilingual fallback | High | Medium | Medium | Built |
| Live catalogue | High | High | Unknown/high | Designed only |
| Embedding search | Medium/high | High | Medium | Two-week evolution |
| Personalisation | Medium | High | High/privacy | Deferred |
| Checkout | Medium | Low for assistant hypothesis | High | Excluded |

## What I would do with two additional weeks

### Week 1 — improve the chatbot

1. Connect a larger, more realistic product catalogue.
2. Test the chatbot with users and collect the questions it does not understand well.
3. Improve how it handles vague requests and follow-up questions.
4. Make product recommendations easier to understand by showing the exact reasons for each result.

### Week 2 — make it more reliable

1. Keep recent conversations more reliably, while protecting user privacy.
2. Improve search for broad requests such as a style, a room or a use case.
3. Add a simple “helpful / not helpful” feedback option.
4. Use the feedback and test results to improve the chatbot before a small live trial.

## Success metrics

- Product-card click-through after assistant use
- Comparison completion and downstream product-page visits
- Add-to-basket conversion versus existing search
- Reduction in zero-result and query-reformulation rates
- Constraint adherence and product-fact accuracy
- Explicit helpfulness score
- p50/p95 latency, availability and cost per session
