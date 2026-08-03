# AI usage disclosure

## Tools used

### OpenAI Codex

Used as a development copilot to:

- inspect and scope the project brief;
- discuss architecture and product decisions interactively;
- draft FastAPI, Pydantic, JavaScript, CSS and test code;
- identify the missing follow-up-memory behaviour;
- draft architecture, decision and testing documentation;
- run and correct automated tests.

### OpenAI documentation

Official current documentation was consulted while evaluating an earlier optional integration. The delivered application does not call the OpenAI API at runtime.

### iaedu chatbot API

The delivered prototype optionally calls the course-provided iaedu chatbot endpoint for intent extraction only. Its API key, endpoint and channel ID are read from the local `.env` file and are never sent to the browser or committed to the repository. The backend sends the current message, an anonymous per-session thread ID and an empty `user_info` object; it then validates the returned JSON before applying local catalogue retrieval.

### Built-in OpenAI image generation

Used to create 12 fictional editorial product images. The built-in tool did not require the application's iaedu credentials. Images were copied into the project, resized and converted to WebP. They are labelled “Illustrative image” in the UI.

## Image prompt set

All images used this shared production prompt:

```text
Use case: product-mockup
Asset type: fictional furniture catalogue card for a premium European home-shopping prototype
Style: photorealistic high-end interior editorial photography
Composition: horizontal 4:3, complete product visible, restrained setting
Lighting: soft natural light, warm and refined
Constraints: fictional unbranded product; no people; no logo; no text;
no watermark; no recognisable branded design
```

The individual subjects were:

1. Aurora — compact rounded beige two-seat sofa
2. Harbor — forest-green velvet three-seat sofa
3. Mosaic — terracotta two-module sofa
4. Nordic — warm oak desk with two drawers
5. Forge — slim matte-black metal desk with raised shelf
6. Extend — extendable natural-oak dining table
7. Orbit — round dark-ash pedestal table
8. Cane — oak and woven-cane dining chair
9. Terra — curved terracotta lounge chair
10. Halo — terracotta mushroom table lamp
11. Lumen — handwoven rattan pendant
12. Weave — neutral geometric wool rug

Each prompt added the product-specific material, form, setting and composition. No existing retailer product imagery or visual reference was supplied.

## Outputs accepted

- FastAPI/Jinja2 separation and repository/service structure
- Structured `SearchCriteria` contract
- Deterministic fallback and provider-error handling
- Server-side memory for the previous result set
- Editorial layout and generated fictional image set
- First drafts of automated tests and documentation

## Outputs modified

- Budget parsing was corrected after tests exposed thousands separators in `€1,000` and `1 000 €`.
- Dining intent was expanded after a Portuguese test exposed the phrase “de jantar”.
- Visual comparison bypasses the LLM to avoid unnecessary cost.
- A vague “cheaper” suggested follow-up was replaced with a supported product-details action.
- Generated PNG files were resized and converted to WebP for a smaller deliverable.

## Outputs rejected or avoided

- Claims that the application uses live Atelier Home data
- A simple unexplained sustainability boolean
- LLM-selected product IDs, prices or attributes
- A second model call solely to make templated answers sound more natural
- Reuse of a ChatGPT subscription as an API credential
- Remote product photographs with unclear persistence or licensing
- A production-ready claim

## Human judgement and verification

I selected every material architectural and product choice. AI output was treated as a draft: product facts are fictional and explicit, the source code was compiled, all automated tests were run, image outputs were visually reviewed, and limitations are documented.
