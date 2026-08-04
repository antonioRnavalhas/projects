const translations = {
  en: {
    kicker: "YOUR PERSONAL SHOPPING EDIT",
    heroTitle: "A clearer way to find the right piece.",
    heroIntro: "Meet Léo, a shopping assistant that turns your needs into relevant, explainable choices.",
    proof1: "Natural language", proof2: "Clear comparisons", proof3: "Grounded answers",
    tryAsking: "TRY ASKING", promptHeading: "Start with a need, not a product name.",
    starter1: "A sofa for a small room", starter2: "Sustainable dining furniture", starter3: "Compare two desks",
    principleTitle: "Evidence before claims", principleBody: "Recommendations cite catalogue attributes rather than invented facts.",
    ready: "Ready to help", newChat: "New chat", selected: "selected", compare: "Compare",
    placeholder: "What are you looking for?", prototypeNote: "Static browser demo using fictional products and illustrative images. Availability is not live.",
    howKicker: "WHY THIS APPROACH", step1Title: "Understand", step1Body: "Léo identifies intent and constraints from the conversation.",
    step2Title: "Retrieve", step2Body: "The browser filters and ranks only known catalogue products.",
    step3Title: "Explain", step3Body: "Every result is supported by visible product attributes.",
    welcome: "Hello — I’m Léo. Tell me what you need, your budget and any preferences.",
    illustrative: "Illustrative image", details: "View details", price: "Price", material: "Material", dimensions: "Dimensions",
    rating: "Rating", sustainability: "Sustainability evidence", none: "No specific evidence listed", error: "Something went wrong. Please try again."
  },
  fr: {
    kicker: "VOTRE SÉLECTION PERSONNALISÉE",
    heroTitle: "Une façon plus claire de trouver la bonne pièce.",
    heroIntro: "Découvrez Léo, un assistant qui transforme vos besoins en choix pertinents et explicables.",
    proof1: "Langage naturel", proof2: "Comparaisons claires", proof3: "Réponses factuelles",
    tryAsking: "ESSAYEZ DE DEMANDER", promptHeading: "Commencez par un besoin, pas par un nom de produit.",
    starter1: "Un canapé pour un petit salon", starter2: "Mobilier de salle à manger durable", starter3: "Comparer deux bureaux",
    principleTitle: "Des preuves avant les affirmations", principleBody: "Les recommandations citent les attributs du catalogue.",
    ready: "Prêt à vous aider", newChat: "Nouvelle discussion", selected: "sélectionné(s)", compare: "Comparer",
    placeholder: "Que recherchez-vous ?", prototypeNote: "Démo statique avec produits fictifs et images illustratives. Disponibilité non réelle.",
    howKicker: "POURQUOI CETTE APPROCHE", step1Title: "Comprendre", step1Body: "Léo identifie l’intention et les contraintes.",
    step2Title: "Rechercher", step2Body: "Le navigateur filtre et classe uniquement les produits connus.",
    step3Title: "Expliquer", step3Body: "Chaque résultat est justifié par des attributs visibles.",
    welcome: "Bonjour — je suis Léo. Indiquez ce que vous cherchez, votre budget et vos préférences.",
    illustrative: "Image illustrative", details: "Voir les détails", price: "Prix", material: "Matière", dimensions: "Dimensions",
    rating: "Note", sustainability: "Éléments de durabilité", none: "Aucun élément spécifique indiqué", error: "Une erreur est survenue. Veuillez réessayer."
  },
  pt: {
    kicker: "A SUA SELEÇÃO PERSONALIZADA",
    heroTitle: "Uma forma mais clara de encontrar a peça certa.",
    heroIntro: "Conheça o Léo, um assistente que transforma necessidades em escolhas relevantes e explicáveis.",
    proof1: "Linguagem natural", proof2: "Comparações claras", proof3: "Respostas fundamentadas",
    tryAsking: "EXPERIMENTE PERGUNTAR", promptHeading: "Comece por uma necessidade, não pelo nome de um produto.",
    starter1: "Um sofá para uma sala pequena", starter2: "Mobiliário de jantar sustentável", starter3: "Comparar duas secretárias",
    principleTitle: "Evidências antes de afirmações", principleBody: "As recomendações citam atributos do catálogo.",
    ready: "Pronto para ajudar", newChat: "Nova conversa", selected: "selecionados", compare: "Comparar",
    placeholder: "O que procura?", prototypeNote: "Demo estática com produtos fictícios e imagens ilustrativas. A disponibilidade não é real.",
    howKicker: "PORQUÊ ESTA ABORDAGEM", step1Title: "Compreender", step1Body: "O Léo identifica a intenção e as restrições da conversa.",
    step2Title: "Pesquisar", step2Body: "O navegador filtra e ordena apenas produtos conhecidos.",
    step3Title: "Explicar", step3Body: "Cada resultado é sustentado por atributos visíveis.",
    welcome: "Olá — sou o Léo. Diga-me o que procura, o seu orçamento e preferências.",
    illustrative: "Imagem ilustrativa", details: "Ver detalhes", price: "Preço", material: "Material", dimensions: "Dimensões",
    rating: "Avaliação", sustainability: "Evidências de sustentabilidade", none: "Sem evidência específica indicada", error: "Ocorreu um erro. Tente novamente."
  }
};

const state = {
  language: "en",
  selected: new Map(),
  products: new Map(),
  catalogue: [],
  lastResultIds: [],
  busy: false
};

const messages = document.querySelector("#messages");
const input = document.querySelector("#chat-input");
const sendButton = document.querySelector("#send-button");
const languageSelect = document.querySelector("#language-select");
const compareTray = document.querySelector("#compare-tray");
const productDialog = document.querySelector("#product-dialog");

function t(key) { return translations[state.language][key] || translations.en[key] || key; }
function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, character => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;"
  }[character]));
}
function formatPrice(value) {
  const locale = state.language === "fr" ? "fr-FR" : state.language === "pt" ? "pt-PT" : "en-IE";
  return new Intl.NumberFormat(locale, { style: "currency", currency: "EUR", maximumFractionDigits: 0 }).format(value);
}

function setLanguage(language, reset = false) {
  state.language = language;
  document.documentElement.lang = language;
  languageSelect.value = language;
  document.querySelectorAll("[data-i18n]").forEach(element => {
    element.textContent = t(element.dataset.i18n);
  });
  document.querySelectorAll("[data-i18n-placeholder]").forEach(element => {
    element.placeholder = t(element.dataset.i18nPlaceholder);
  });
  if (reset) startNewChat();
}

function addUserMessage(text) {
  const element = document.createElement("div");
  element.className = "message user";
  element.textContent = text;
  messages.appendChild(element);
  scrollMessages();
}

function addAssistantMessage(payload, isError = false) {
  const element = document.createElement("div");
  element.className = "message assistant";
  const products = payload.products || [];
  products.forEach(product => state.products.set(product.id, product));
  element.innerHTML = `
    <div class="assistant-copy ${isError ? "error-copy" : ""}">
      <p>${escapeHtml(payload.message)}</p>
    </div>
    ${products.length ? renderProducts(products) : ""}
    ${payload.comparison?.length ? renderComparison(payload.comparison) : ""}
    ${payload.suggestions?.length && !isError ? renderSuggestions(payload.suggestions) : ""}
  `;
  messages.appendChild(element);
  updateMode(payload.mode);
  scrollMessages();
}

function renderProducts(products) {
  return `<div class="product-grid">${products.map(product => `
    <article class="product-card">
      <div class="product-image">
        <button class="select-product ${state.selected.has(product.id) ? "selected" : ""}" data-select="${escapeHtml(product.id)}" aria-label="Select ${escapeHtml(product.name)}">${state.selected.has(product.id) ? "✓" : "+"}</button>
        <img src="${escapeHtml(product.image)}" alt="${escapeHtml(product.name)}" loading="lazy">
        <span class="image-note">${t("illustrative")}</span>
      </div>
      <div class="product-content">
        <p class="product-category">${escapeHtml(product.category)}</p>
        <h3>${escapeHtml(product.name)}</h3>
        <div class="product-line"><b>${formatPrice(product.price)}</b><span>★ ${product.rating}</span></div>
        <p class="product-description">${escapeHtml(product.description)}</p>
        ${product.sustainability.length ? `<span class="evidence-tag">✓ ${escapeHtml(product.sustainability[0].label)}</span>` : ""}
        <button class="details-button" data-details="${escapeHtml(product.id)}">${t("details")}</button>
      </div>
    </article>
  `).join("")}</div>`;
}

function renderComparison(products) {
  products.forEach(product => state.products.set(product.id, product));
  const row = (label, value) => `<tr><td>${label}</td>${products.map(product => `<td>${value(product)}</td>`).join("")}</tr>`;
  return `<div class="comparison-wrap"><table class="comparison">
    <thead><tr><th></th>${products.map(product => `<th>${escapeHtml(product.name)}</th>`).join("")}</tr></thead>
    <tbody>
      ${row(t("price"), product => formatPrice(product.price))}
      ${row(t("material"), product => escapeHtml(product.material))}
      ${row(t("dimensions"), product => `${product.width_cm} × ${product.height_cm} × ${product.depth_cm} cm`)}
      ${row(t("rating"), product => `★ ${product.rating}`)}
      ${row(t("sustainability"), product => product.sustainability.length ? escapeHtml(product.sustainability.map(item => item.label).join(", ")) : t("none"))}
    </tbody>
  </table></div>`;
}

function renderSuggestions(suggestions) {
  return `<div class="suggestions">${suggestions.map(text =>
    `<button class="suggestion" data-suggestion="${escapeHtml(text)}">${escapeHtml(text)}</button>`
  ).join("")}</div>`;
}

function showTyping() {
  const element = document.createElement("div");
  element.id = "typing";
  element.className = "message assistant";
  element.innerHTML = '<div class="assistant-copy typing">•••</div>';
  messages.appendChild(element);
  scrollMessages();
}
function hideTyping() { document.querySelector("#typing")?.remove(); }
function scrollMessages() { messages.scrollTop = messages.scrollHeight; }

const demoCopy = {
  en: {
    found: count => `I found ${count} catalogue-backed option${count === 1 ? "" : "s"} that match your request.`,
    none: "I couldn’t find an exact match in this small fictional catalogue. Try a different category or a higher budget.",
    comparison: names => `Here is a catalogue-based comparison of ${names.join(" and ")}.`,
    needComparison: "Choose at least two products, name two products, or search first so I can compare the results.",
    evidence: (name, details) => `${name}: ${details}`,
    noEvidence: name => `The fictional catalogue does not list specific sustainability evidence for ${name}.`,
    loadError: "The fictional catalogue could not be loaded. Refresh the page and try again.",
    compareSuggestion: "Compare the first two",
    evidenceSuggestion: "Why is the first option sustainable?"
  },
  fr: {
    found: count => `J’ai trouvé ${count} option${count === 1 ? "" : "s"} du catalogue correspondant à votre demande.`,
    none: "Je n’ai pas trouvé de correspondance exacte dans ce petit catalogue fictif. Essayez une autre catégorie ou un budget plus élevé.",
    comparison: names => `Voici une comparaison fondée sur le catalogue de ${names.join(" et ")}.`,
    needComparison: "Sélectionnez ou nommez au moins deux produits, ou lancez d’abord une recherche.",
    evidence: (name, details) => `${name} : ${details}`,
    noEvidence: name => `Le catalogue fictif ne contient pas d’élément de durabilité précis pour ${name}.`,
    loadError: "Le catalogue fictif n’a pas pu être chargé. Actualisez la page et réessayez.",
    compareSuggestion: "Comparer les deux premiers",
    evidenceSuggestion: "Pourquoi la première option est-elle durable ?"
  },
  pt: {
    found: count => `Encontrei ${count} ${count === 1 ? "opção" : "opções"} fundamentadas no catálogo que correspondem ao pedido.`,
    none: "Não encontrei uma correspondência exata neste pequeno catálogo fictício. Experimente outra categoria ou um orçamento superior.",
    comparison: names => `Aqui está uma comparação baseada no catálogo entre ${names.join(" e ")}.`,
    needComparison: "Selecione ou indique pelo menos dois produtos, ou faça primeiro uma pesquisa para eu comparar os resultados.",
    evidence: (name, details) => `${name}: ${details}`,
    noEvidence: name => `O catálogo fictício não apresenta evidências específicas de sustentabilidade para ${name}.`,
    loadError: "Não foi possível carregar o catálogo fictício. Atualize a página e tente novamente.",
    compareSuggestion: "Comparar os dois primeiros",
    evidenceSuggestion: "Porque é sustentável a primeira opção?"
  }
};

function normalizeText(value) {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();
}

function detectLanguage(text) {
  const normalized = normalizeText(text);
  if (/\b(procuro|quero|mostre|mostrar|abaixo|orcamento|sustentavel|secretaria|cadeira|candeeiro|compare os|porque)\b/.test(normalized)) return "pt";
  if (/\b(cherche|montrez|moins|budget|durable|bureau|chaise|canape|comparez|pourquoi)\b/.test(normalized)) return "fr";
  return state.language;
}

function localizedValue(value, language) {
  if (typeof value === "string") return value;
  return value?.[language] || value?.en || "";
}

function localizeProduct(product, language) {
  return {
    ...product,
    material: localizedValue(product.material, language),
    description: localizedValue(product.description, language),
    sustainability: (product.sustainability || []).map(item => ({
      label: localizedValue(item.label, language),
      detail: localizedValue(item.detail, language)
    })),
    image: `./assets/images/${String(product.image).split("/").pop()}`
  };
}

function extractBudget(text) {
  const normalized = normalizeText(text);
  const hasBudgetSignal = /€|\beur\b|\b(under|below|less than|budget|max|maximum|moins de|abaixo de|menos de|ate)\b/.test(normalized);
  if (!hasBudgetSignal) return null;
  const candidates = String(text).match(/\d(?:[\d\s.,]*\d)?/g) || [];
  const values = candidates
    .map(value => Number(value.replace(/\D/g, "")))
    .filter(value => Number.isFinite(value) && value > 0);
  return values.length ? Math.max(...values) : null;
}

function requestedCategories(normalized) {
  if (/(dining|salle a manger|jantar)/.test(normalized)) return ["table", "chair"];
  const groups = [
    ["sofa", /(sofa|canape)/],
    ["desk", /(desk|bureau|secretaria|escrivaninha)/],
    ["table", /(table|mesa)/],
    ["chair", /(chair|chaise|cadeira|fauteuil|poltrona)/],
    ["lighting", /(lamp|light|lighting|luminaire|lampe|candeeiro|iluminacao)/],
    ["textile", /(rug|tapis|tapete|textile)/]
  ];
  const matches = groups.filter(([, pattern]) => pattern.test(normalized)).map(([category]) => category);
  return matches;
}

function findNamedProducts(normalized) {
  const generic = new Set(["sofa", "desk", "table", "chair", "lamp", "rug"]);
  return state.catalogue.filter(product => {
    const distinctiveTokens = product.id.split("-").filter(token => !generic.has(token) && token.length > 3);
    return distinctiveTokens.some(token => normalized.includes(normalizeText(token)));
  });
}

function buildCriteria(text) {
  const normalized = normalizeText(text);
  const colors = ["beige", "green", "blue", "terracotta", "black", "natural"];
  const materialGroups = [
    { query: /\b(oak|wood|carvalho|chene|madeira|bois)\b/, catalogue: /(oak|wood|veneer|ash)/ },
    { query: /\b(metal|steel|acier|aco)\b/, catalogue: /(metal|steel)/ },
    { query: /\b(wool|laine|la)\b/, catalogue: /wool/ },
    { query: /\b(rattan|rotin)\b/, catalogue: /rattan/ },
    { query: /\b(polyester)\b/, catalogue: /polyester/ },
    { query: /\b(linen|lin|linho)\b/, catalogue: /linen/ },
    { query: /\b(cotton|coton|algodao)\b/, catalogue: /cotton/ }
  ];
  const material = materialGroups.find(group => group.query.test(normalized));
  return {
    normalized,
    categories: requestedCategories(normalized),
    maxPrice: extractBudget(text),
    sustainable: /(sustainab|sustent|durable|ecolog|responsavel|responsable)/.test(normalized),
    compact: /(compact|small room|small space|petit|pequeno|pouco espaco)/.test(normalized),
    color: colors.find(color => normalized.includes(color)) || null,
    material: material?.catalogue || null,
    namedProducts: findNamedProducts(normalized)
  };
}

function searchCatalogue(criteria) {
  let candidates = [...state.catalogue];
  if (criteria.namedProducts.length) candidates = criteria.namedProducts;
  if (criteria.categories.length) candidates = candidates.filter(product => criteria.categories.includes(product.category));
  if (criteria.maxPrice !== null) candidates = candidates.filter(product => product.price <= criteria.maxPrice);
  if (criteria.sustainable) candidates = candidates.filter(product => product.sustainability?.length);
  if (criteria.compact) candidates = candidates.filter(product => product.tags?.some(tag => /compact|small room/.test(normalizeText(tag))) || product.width_cm <= 175);
  if (criteria.color) candidates = candidates.filter(product => product.colors?.map(normalizeText).includes(criteria.color));
  if (criteria.material) candidates = candidates.filter(product => criteria.material.test(normalizeText(localizedValue(product.material, "en"))));

  return candidates
    .map(product => {
      let score = product.rating;
      if (criteria.sustainable && product.sustainability?.length) score += 4;
      if (criteria.compact && product.tags?.some(tag => /compact|small room/.test(normalizeText(tag)))) score += 3;
      if (criteria.maxPrice !== null) score += Math.max(0, (criteria.maxPrice - product.price) / Math.max(criteria.maxPrice, 1));
      if (criteria.namedProducts.includes(product)) score += 8;
      return { product, score };
    })
    .sort((left, right) => right.score - left.score || right.product.rating - left.product.rating)
    .slice(0, 4)
    .map(item => item.product);
}

function processMessage(text, selectedIds = []) {
  const language = detectLanguage(text);
  const copy = demoCopy[language];
  const normalized = normalizeText(text);
  const wantsComparison = /(compare|comparison|comparer|comparaison)/.test(normalized);
  const asksForEvidence = /(why|pourquoi|porque)/.test(normalized) && /(sustainab|sustent|durable|ecolog)/.test(normalized);

  if (wantsComparison) {
    const selected = selectedIds.map(id => state.catalogue.find(product => product.id === id)).filter(Boolean);
    const named = findNamedProducts(normalized);
    const recent = state.lastResultIds.map(id => state.catalogue.find(product => product.id === id)).filter(Boolean);
    const unique = [...new Map([...selected, ...named, ...recent].map(product => [product.id, product])).values()].slice(0, 3);
    if (unique.length < 2) return { message: copy.needComparison, mode: "static", suggestions: [] };
    state.lastResultIds = unique.map(product => product.id);
    const products = unique.map(product => localizeProduct(product, language));
    return {
      message: copy.comparison(products.map(product => product.name)),
      comparison: products,
      mode: "static",
      suggestions: []
    };
  }

  if (asksForEvidence && state.lastResultIds.length) {
    const recent = state.lastResultIds.map(id => state.catalogue.find(product => product.id === id)).filter(Boolean);
    const product = recent.find(item => item.sustainability?.length) || recent[0];
    const localized = localizeProduct(product, language);
    const details = localized.sustainability.map(item => `${item.label}: ${item.detail}`).join(" ");
    return {
      message: details ? copy.evidence(localized.name, details) : copy.noEvidence(localized.name),
      products: [localized],
      mode: "static",
      suggestions: []
    };
  }

  const results = searchCatalogue(buildCriteria(text));
  state.lastResultIds = results.map(product => product.id);
  if (!results.length) return { message: copy.none, mode: "static", suggestions: [] };

  const suggestions = [];
  if (results.length > 1) suggestions.push(copy.compareSuggestion);
  if (results[0].sustainability?.length) suggestions.push(copy.evidenceSuggestion);
  return {
    message: copy.found(results.length),
    products: results.map(product => localizeProduct(product, language)),
    mode: "static",
    suggestions
  };
}

function updateMode(mode) {
  if (!mode) return;
  const badge = document.querySelector("#mode-badge");
  badge.textContent = mode === "static" ? "STATIC DEMO" : `${mode.toUpperCase()} MODE`;
  badge.classList.toggle("ai", mode === "ai");
  badge.classList.toggle("static", mode === "static");
}

async function sendMessage(text, selectedIds = []) {
  const cleanText = text.trim();
  if (!cleanText || state.busy) return;
  state.busy = true;
  sendButton.disabled = true;
  addUserMessage(cleanText);
  input.value = "";
  resizeInput();
  showTyping();
  try {
    if (!state.catalogue.length) throw new Error("Catalogue unavailable");
    await new Promise(resolve => window.setTimeout(resolve, 260));
    const payload = processMessage(cleanText, selectedIds);
    hideTyping();
    addAssistantMessage(payload);
    clearSelection();
  } catch (error) {
    hideTyping();
    addAssistantMessage({ message: demoCopy[state.language].loadError, mode: "static" }, true);
  } finally {
    state.busy = false;
    sendButton.disabled = false;
    input.focus();
  }
}

function startNewChat() {
  state.lastResultIds = [];
  clearSelection();
  messages.innerHTML = "";
  addAssistantMessage({ message: t("welcome"), mode: window.APP_CONFIG.initialMode, suggestions: [] });
}

function toggleSelection(productId, button) {
  if (state.selected.has(productId)) {
    state.selected.delete(productId);
    button.classList.remove("selected");
    button.textContent = "+";
  } else {
    if (state.selected.size >= 3) return;
    state.selected.set(productId, state.products.get(productId));
    button.classList.add("selected");
    button.textContent = "✓";
  }
  updateCompareTray();
}
function clearSelection() {
  state.selected.clear();
  document.querySelectorAll(".select-product.selected").forEach(button => {
    button.classList.remove("selected");
    button.textContent = "+";
  });
  updateCompareTray();
}
function updateCompareTray() {
  document.querySelector("#selected-count").textContent = state.selected.size;
  compareTray.hidden = state.selected.size < 2;
}

function openDetails(productId) {
  const product = state.products.get(productId);
  if (!product) return;
  const evidence = product.sustainability.length
    ? `<div class="dialog-evidence"><b>${t("sustainability")}</b><br>${product.sustainability.map(item => `<p><strong>${escapeHtml(item.label)}</strong><br>${escapeHtml(item.detail)}</p>`).join("")}</div>`
    : "";
  document.querySelector("#dialog-content").innerHTML = `
    <article class="dialog-product">
      <img src="${escapeHtml(product.image)}" alt="${escapeHtml(product.name)}">
      <div class="dialog-copy">
        <p class="product-category">${escapeHtml(product.category)}</p>
        <h2>${escapeHtml(product.name)}</h2>
        <p>${escapeHtml(product.description)}</p>
        <dl>
          <dt>${t("price")}</dt><dd>${formatPrice(product.price)}</dd>
          <dt>${t("material")}</dt><dd>${escapeHtml(product.material)}</dd>
          <dt>${t("dimensions")}</dt><dd>${product.width_cm} × ${product.height_cm} × ${product.depth_cm} cm</dd>
          <dt>${t("rating")}</dt><dd>★ ${product.rating}</dd>
        </dl>
        ${evidence}
        <small>${t("illustrative")}</small>
      </div>
    </article>`;
  productDialog.showModal();
}

function resizeInput() {
  input.style.height = "auto";
  input.style.height = `${Math.min(input.scrollHeight, 120)}px`;
}

sendButton.addEventListener("click", () => sendMessage(input.value));
input.addEventListener("input", resizeInput);
input.addEventListener("keydown", event => {
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    sendMessage(input.value);
  }
});
languageSelect.addEventListener("change", event => {
  setLanguage(event.target.value, true);
});
document.querySelector("#new-chat").addEventListener("click", startNewChat);
document.querySelector("#compare-selected").addEventListener("click", () => {
  const prompt = state.language === "fr" ? "Comparez les produits sélectionnés" : state.language === "pt" ? "Compare os produtos selecionados" : "Compare the selected products";
  sendMessage(prompt, [...state.selected.keys()]);
});
document.querySelector("#close-dialog").addEventListener("click", () => productDialog.close());
productDialog.addEventListener("click", event => {
  if (event.target === productDialog) productDialog.close();
});
document.querySelectorAll(".starter").forEach(button => {
  button.addEventListener("click", () => sendMessage(button.dataset[`prompt${state.language[0].toUpperCase()}${state.language.slice(1)}`] || button.dataset.promptEn));
});
document.addEventListener("click", event => {
  const selectButton = event.target.closest("[data-select]");
  const detailsButton = event.target.closest("[data-details]");
  const suggestionButton = event.target.closest("[data-suggestion]");
  if (selectButton) toggleSelection(selectButton.dataset.select, selectButton);
  if (detailsButton) openDetails(detailsButton.dataset.details);
  if (suggestionButton) sendMessage(suggestionButton.dataset.suggestion);
});

async function initializeCatalogue() {
  state.busy = true;
  sendButton.disabled = true;
  setLanguage("en");
  try {
    const response = await fetch("./data/products.json");
    if (!response.ok) throw new Error("Catalogue request failed");
    const catalogue = await response.json();
    if (!Array.isArray(catalogue) || !catalogue.length) throw new Error("Catalogue is empty");
    state.catalogue = catalogue;
    startNewChat();
    state.busy = false;
    sendButton.disabled = false;
  } catch (error) {
    state.busy = false;
    messages.innerHTML = "";
    addAssistantMessage({ message: demoCopy[state.language].loadError, mode: "static" }, true);
  }
}

initializeCatalogue();
