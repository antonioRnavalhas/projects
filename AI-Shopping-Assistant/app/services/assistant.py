from __future__ import annotations

from app.config import Settings
from app.memory import ConversationState, InMemoryConversationStore
from app.models import ChatRequest, ChatResponse, Language, Product, SearchCriteria
from app.repository import ProductRepository
from app.repository import normalise
from app.services.intent import IntentExtractor

COPY = {
    "en": {
        "welcome": "Hello — I’m Léo. Tell me what you need, your budget and any preferences.",
        "help": "I can find home products, explain recommendations and compare up to three options. Try asking for a compact sofa under €1,000.",
        "found": "I found {count} relevant option{plural}. Each match is based on the catalogue attributes shown below.",
        "none": "I couldn’t find a product matching every requirement. Try changing the category, budget, size or material.",
        "compare": "Here is a factual side-by-side comparison. The best option depends on which trade-offs matter to you.",
        "need_compare": "Tell me which two products to compare, or select them from the product cards.",
        "why_sustainable": "These choices have specific sustainability evidence in the sample catalogue:",
        "not_assessment": "This evidence is not a complete lifecycle or environmental-impact assessment.",
        "no_context": "I need a little more context. Ask about one of the products I just showed you.",
        "details": "Here are the catalogue details for the products we were discussing:",
    },
    "fr": {
        "welcome": "Bonjour — je suis Léo. Indiquez ce que vous cherchez, votre budget et vos préférences.",
        "help": "Je peux trouver des produits pour la maison, expliquer mes recommandations et comparer jusqu’à trois options. Essayez de demander un canapé compact à moins de 1 000 €.",
        "found": "J’ai trouvé {count} option{plural} pertinente{plural}. Chaque résultat repose sur les attributs du catalogue affichés ci-dessous.",
        "none": "Je n’ai trouvé aucun produit répondant à tous les critères. Essayez de modifier la catégorie, le budget, la taille ou la matière.",
        "compare": "Voici une comparaison factuelle. Le meilleur choix dépend des compromis qui comptent pour vous.",
        "need_compare": "Indiquez les deux produits à comparer ou sélectionnez-les dans les cartes.",
        "why_sustainable": "Ces choix disposent d’éléments précis de durabilité dans le catalogue de démonstration :",
        "not_assessment": "Ces éléments ne constituent pas une analyse complète du cycle de vie ou de l’impact environnemental.",
        "no_context": "J’ai besoin de contexte. Posez une question sur l’un des produits que je viens de présenter.",
        "details": "Voici les informations du catalogue pour les produits concernés :",
    },
    "pt": {
        "welcome": "Olá — sou o Léo. Diga-me o que procura, o seu orçamento e preferências.",
        "help": "Posso encontrar produtos para casa, explicar recomendações e comparar até três opções. Experimente pedir um sofá compacto abaixo de 1 000 €.",
        "found": "Encontrei {count} opç{ending} relevante{plural}. Cada resultado baseia-se nos atributos do catálogo apresentados abaixo.",
        "none": "Não encontrei um produto que cumpra todos os requisitos. Experimente alterar a categoria, orçamento, dimensão ou material.",
        "compare": "Aqui está uma comparação factual. A melhor escolha depende dos compromissos mais importantes para si.",
        "need_compare": "Indique os dois produtos que pretende comparar ou selecione-os nos cartões.",
        "why_sustainable": "Estas opções têm evidências específicas de sustentabilidade no catálogo de demonstração:",
        "not_assessment": "Estas evidências não representam uma avaliação completa do ciclo de vida ou impacto ambiental.",
        "no_context": "Preciso de algum contexto. Pergunte sobre um dos produtos que acabei de apresentar.",
        "details": "Estes são os detalhes do catálogo para os produtos em discussão:",
    },
}


class ShoppingAssistant:
    def __init__(
        self,
        repository: ProductRepository,
        memory: InMemoryConversationStore,
        extractor: IntentExtractor,
        settings: Settings,
    ):
        self.repository = repository
        self.memory = memory
        self.extractor = extractor
        self.settings = settings

    def chat(self, request: ChatRequest) -> ChatResponse:
        session_id, state = self.memory.get_or_create(request.session_id)
        selected_products = self.repository.get_many(request.selected_product_ids)
        if selected_products:
            criteria = SearchCriteria(
                intent="compare",
                language=request.language or state.language,
            )
            used_ai = False
        else:
            criteria, used_ai = self.extractor.extract(
                request.message,
                request.language,
                state.language if state.messages else None,
                state.iaedu_thread_id,
                state.messages,
                [product.name for product in self.repository.all()],
            )
        if request.language:
            criteria.language = request.language
        state.language = criteria.language
        self.memory.add_message(state, "user", request.message)

        message_text = normalise(request.message)
        if (
            criteria.intent == "compare"
            and not selected_products
            and any(term in message_text for term in ["first two", "deux premiers", "dois primeiros"])
        ):
            selected_products = self.repository.get_many(state.last_product_ids[:2])

        response = self._respond(criteria, state, selected_products)
        response.session_id = session_id
        response.mode = "ai" if used_ai else "demo"
        state.last_criteria = criteria
        self.memory.add_message(state, "assistant", response.message)
        return response

    def _respond(
        self,
        criteria: SearchCriteria,
        state: ConversationState,
        selected_products: list[Product],
    ) -> ChatResponse:
        language = criteria.language
        copy = COPY[language]
        base = {
            "session_id": "",
            "language": language,
            "mode": "demo",
            "intent": criteria.intent,
            "suggestions": self._suggestions(language),
        }

        if criteria.intent == "greeting":
            return ChatResponse(message=copy["welcome"], **base)
        if criteria.intent == "help":
            return ChatResponse(message=copy["help"], **base)
        if criteria.intent == "sustainability_followup":
            products = self.repository.get_many(state.last_product_ids)
            sustainable = [product for product in products if product.sustainability]
            if not sustainable:
                return ChatResponse(message=copy["no_context"], **base)
            evidence_lines = []
            for product in sustainable:
                evidence = "; ".join(
                    item.detail.for_language(language) for item in product.sustainability
                )
                evidence_lines.append(f"{product.name}: {evidence}")
            message = f"{copy['why_sustainable']} {' '.join(evidence_lines)} {copy['not_assessment']}"
            return ChatResponse(
                message=message,
                products=[product.public_dict(language) for product in sustainable],
                **base,
            )
        if criteria.intent == "product_details":
            products = self.repository.get_many(state.last_product_ids)
            if not products:
                return ChatResponse(message=copy["no_context"], **base)
            return ChatResponse(
                message=copy["details"],
                products=[product.public_dict(language) for product in products],
                **base,
            )
        if criteria.intent == "compare":
            products = selected_products or self.repository.find_by_names(criteria.product_names)
            if len(products) < 2:
                products = self.repository.get_many(state.last_product_ids)[:3]
            if len(products) < 2:
                return ChatResponse(message=copy["need_compare"], **base)
            products = products[:3]
            state.last_product_ids = [product.id for product in products]
            return ChatResponse(
                message=copy["compare"],
                comparison=[product.public_dict(language) for product in products],
                **base,
            )

        products = self.repository.search(criteria, limit=self.settings.max_results)
        state.last_product_ids = [product.id for product in products]
        if not products:
            return ChatResponse(message=copy["none"], **base)
        count = len(products)
        if language == "pt":
            message = copy["found"].format(
                count=count,
                ending="ão" if count == 1 else "ões",
                plural="" if count == 1 else "s",
            )
        else:
            message = copy["found"].format(
                count=count,
                plural="" if count == 1 else "s",
            )
        return ChatResponse(
            message=message,
            products=[product.public_dict(language) for product in products],
            **base,
        )

    @staticmethod
    def _suggestions(language: Language) -> list[str]:
        return {
            "en": [
                "Why is it sustainable?",
                "Compare the first two",
                "Tell me more about these products",
            ],
            "fr": [
                "Pourquoi est-ce durable ?",
                "Comparez les deux premiers",
                "Plus de détails sur ces produits",
            ],
            "pt": [
                "Porque é sustentável?",
                "Compare os dois primeiros",
                "Mais detalhes sobre estes produtos",
            ],
        }[language]
