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
    placeholder: "What are you looking for?", prototypeNote: "Prototype using fictional products and illustrative images. Availability is not live.",
    howKicker: "WHY THIS APPROACH", step1Title: "Understand", step1Body: "Léo identifies intent and constraints from the conversation.",
    step2Title: "Retrieve", step2Body: "Python filters and ranks only known catalogue products.",
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
    placeholder: "Que recherchez-vous ?", prototypeNote: "Prototype avec produits fictifs et images illustratives. Disponibilité non réelle.",
    howKicker: "POURQUOI CETTE APPROCHE", step1Title: "Comprendre", step1Body: "Léo identifie l’intention et les contraintes.",
    step2Title: "Rechercher", step2Body: "Python filtre et classe uniquement les produits connus.",
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
    placeholder: "O que procura?", prototypeNote: "Protótipo com produtos fictícios e imagens ilustrativas. A disponibilidade não é real.",
    howKicker: "PORQUÊ ESTA ABORDAGEM", step1Title: "Compreender", step1Body: "O Léo identifica a intenção e as restrições da conversa.",
    step2Title: "Pesquisar", step2Body: "O Python filtra e ordena apenas produtos conhecidos.",
    step3Title: "Explicar", step3Body: "Cada resultado é sustentado por atributos visíveis.",
    welcome: "Olá — sou o Léo. Diga-me o que procura, o seu orçamento e preferências.",
    illustrative: "Imagem ilustrativa", details: "Ver detalhes", price: "Preço", material: "Material", dimensions: "Dimensões",
    rating: "Avaliação", sustainability: "Evidências de sustentabilidade", none: "Sem evidência específica indicada", error: "Ocorreu um erro. Tente novamente."
  }
};

const state = {
  language: "en",
  sessionId: null,
  selected: new Map(),
  products: new Map(),
  busy: false
};

const messages = document.querySelector("#messages");
const form = document.querySelector("#chat-form");
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
function updateMode(mode) {
  if (!mode) return;
  const badge = document.querySelector("#mode-badge");
  badge.textContent = `${mode.toUpperCase()} MODE`;
  badge.classList.toggle("ai", mode === "ai");
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
    const response = await fetch("/api/chat", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        session_id: state.sessionId,
        message: cleanText,
        // The selector translates the interface only. The server detects the
        // conversational language from the shopper's message and its context.
        language: null,
        selected_product_ids: selectedIds
      })
    });
    if (!response.ok) throw new Error("Request failed");
    const payload = await response.json();
    state.sessionId = payload.session_id;
    hideTyping();
    addAssistantMessage(payload);
    clearSelection();
  } catch (error) {
    hideTyping();
    addAssistantMessage({ message: t("error"), mode: "demo" }, true);
  } finally {
    state.busy = false;
    sendButton.disabled = false;
    input.focus();
  }
}

async function startNewChat() {
  const oldSession = state.sessionId;
  state.sessionId = null;
  clearSelection();
  messages.innerHTML = "";
  addAssistantMessage({ message: t("welcome"), mode: window.APP_CONFIG.initialMode, suggestions: [] });
  if (oldSession) {
    fetch(`/api/sessions/${encodeURIComponent(oldSession)}`, { method: "DELETE" }).catch(() => {});
  }
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

form.addEventListener("submit", event => {
  event.preventDefault();
  sendMessage(input.value);
});
input.addEventListener("input", resizeInput);
input.addEventListener("keydown", event => {
  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();
    form.requestSubmit();
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

setLanguage("en");
startNewChat();
