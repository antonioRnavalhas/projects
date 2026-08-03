from __future__ import annotations

import json
import logging
import re
from collections.abc import Iterator
from typing import Any

import httpx

from app.models import Language, SearchCriteria
from app.repository import normalise

logger = logging.getLogger(__name__)

CATEGORY_TERMS = {
    "sofa": ["sofa", "couch", "canape"],
    "desk": ["desk", "bureau", "secretaria", "escrivaninha"],
    "table": ["table", "mesa"],
    "chair": ["chair", "chaise", "cadeira"],
    "dining": ["dining", "salle a manger", "sala de jantar", "de jantar"],
    "lighting": ["lamp", "lighting", "light", "lampe", "luminaire", "candeeiro", "iluminacao"],
    "textile": ["rug", "carpet", "tapis", "tapete", "cushion", "almofada"],
}

LANGUAGE_HINTS = {
    "pt": ["procuro", "quero", "preciso", "porque", "sustentavel", "preco", "pequeno", "sala"],
    "fr": ["cherche", "besoin", "pourquoi", "durable", "prix", "petit", "salon", "avec"],
}

COLOR_TERMS = {
    "beige": ["beige"],
    "green": ["green", "vert", "verde"],
    "blue": ["blue", "bleu", "azul"],
    "grey": ["grey", "gray", "gris", "cinzento", "cinza"],
    "black": ["black", "noir", "preto"],
    "white": ["white", "blanc", "branco"],
    "terracotta": ["terracotta"],
    "natural": ["natural", "naturel"],
}


class IntentExtractor:
    """Converts a shopper message to validated criteria, with local fallback."""

    def __init__(
        self,
        api_key: str | None,
        endpoint: str | None,
        channel_id: str | None,
        timeout_seconds: float = 12.0,
        debug_stream: bool = False,
    ):
        self._api_key = api_key
        self._endpoint = endpoint
        self._channel_id = channel_id
        self._timeout_seconds = timeout_seconds
        self._debug_stream = debug_stream

    @property
    def _iaedu_enabled(self) -> bool:
        return bool(self._api_key and self._endpoint and self._channel_id)

    def extract(
        self,
        message: str,
        language_preference: Language | None,
        conversation_language: Language | None,
        thread_id: str,
        history: list[dict[str, str]],
        known_product_names: list[str],
    ) -> tuple[SearchCriteria, bool]:
        if self._iaedu_enabled:
            try:
                return self._extract_with_iaedu(message, thread_id), True
            except Exception as exc:
                # The catalogue must remain usable when the external provider is unavailable.
                logger.warning(
                    "iaedu intent extraction failed (%s): %s; using Demo mode.",
                    type(exc).__name__,
                    exc,
                )
        return (
            self._extract_locally(
                message,
                language_preference,
                conversation_language,
                known_product_names,
            ),
            False,
        )

    def _extract_with_iaedu(self, message: str, thread_id: str) -> SearchCriteria:
        """Call the configured iaedu streaming endpoint without sending user profile data."""
        files = {
            "channel_id": (None, self._channel_id),
            "thread_id": (None, thread_id),
            "user_info": (None, "{}"),
            "message": (None, message),
        }
        headers = {"x-api-key": self._api_key, "Accept": "text/event-stream"}
        with httpx.Client(timeout=self._timeout_seconds, follow_redirects=True) as client:
            with client.stream(
                "POST",
                self._endpoint,
                headers=headers,
                files=files,
            ) as response:
                response.raise_for_status()
                lines = list(response.iter_lines())
        return self._criteria_from_stream(lines, debug=self._debug_stream)

    @classmethod
    def _criteria_from_stream(cls, lines: list[str], debug: bool = False) -> SearchCriteria:
        """Accept normal JSON or common Server-Sent Event JSON stream shapes."""
        parsed_events: list[Any] = []
        fragments: list[str] = []
        for line in lines:
            value = line.strip()
            if not value or value.startswith(("event:", "id:", "retry:")):
                continue
            if value.startswith("data:"):
                value = value[5:].strip()
            if not value or value == "[DONE]":
                continue
            decoded = cls._decode_json(value)
            if decoded is None:
                fragments.append(value)
            else:
                parsed_events.append(decoded)

        for event in parsed_events:
            criteria_object = cls._find_criteria_object(event)
            if criteria_object is not None:
                return SearchCriteria.model_validate(criteria_object)

        token_text = "".join(
            event["content"]
            for event in parsed_events
            if (
                isinstance(event, dict)
                and event.get("type") == "token"
                and isinstance(event.get("content"), str)
            )
        ).strip()
        criteria_object = cls._find_criteria_in_text(token_text)
        if criteria_object is not None:
            return SearchCriteria.model_validate(criteria_object)

        text_fragments = fragments[:]
        for event in parsed_events:
            text_fragments.extend(cls._text_values(event))
        combined = "".join(text_fragments).strip()
        criteria_object = cls._find_criteria_in_text(combined)
        if criteria_object is None:
            event_shapes = ", ".join(cls._event_shape(event) for event in parsed_events[:5])
            preview = ""
            if debug and token_text:
                preview = f", token preview={token_text[:800]!r}"
            raise ValueError(
                "iaedu did not return an intent JSON object "
                f"(lines={len(lines)}, JSON event keys={event_shapes or 'none'}{preview})"
            )
        return SearchCriteria.model_validate(criteria_object)

    @classmethod
    def _find_criteria_in_text(cls, value: str) -> dict[str, Any] | None:
        """Find a valid criteria object even if stream metadata precedes it."""
        for index, character in enumerate(value):
            if character != "{":
                continue
            try:
                decoded, _ = json.JSONDecoder().raw_decode(value[index:])
            except json.JSONDecodeError:
                continue
            found = cls._find_criteria_object(decoded)
            if found is not None:
                return found
        return None

    @staticmethod
    def _event_shape(event: Any) -> str:
        if isinstance(event, dict):
            keys = "+".join(sorted(str(key) for key in event.keys())[:8]) or "object"
            event_type = event.get("type")
            type_part = f", type={event_type}" if isinstance(event_type, str) else ""
            if "content" in event:
                return f"{keys}{type_part} (content={IntentExtractor._value_shape(event['content'])})"
            return f"{keys}{type_part}"
        if isinstance(event, list):
            return "array"
        return type(event).__name__

    @staticmethod
    def _value_shape(value: Any) -> str:
        if isinstance(value, dict):
            return "object:" + "+".join(sorted(str(key) for key in value.keys())[:8])
        if isinstance(value, list):
            return f"array:{len(value)}"
        if isinstance(value, str):
            return f"string:{len(value)}"
        return type(value).__name__

    @staticmethod
    def _decode_json(value: str) -> Any | None:
        candidate = value.strip()
        if candidate.startswith("```"):
            candidate = re.sub(r"^```(?:json)?\\s*|\\s*```$", "", candidate).strip()
        try:
            return json.loads(candidate)
        except json.JSONDecodeError:
            start = candidate.find("{")
            if start < 0:
                return None
            try:
                parsed, _ = json.JSONDecoder().raw_decode(candidate[start:])
                return parsed
            except json.JSONDecodeError:
                return None

    @classmethod
    def _find_criteria_object(cls, value: Any) -> dict[str, Any] | None:
        if isinstance(value, dict):
            if "intent" in value:
                return value
            for child in value.values():
                found = cls._find_criteria_object(child)
                if found is not None:
                    return found
        elif isinstance(value, list):
            for child in value:
                found = cls._find_criteria_object(child)
                if found is not None:
                    return found
        elif isinstance(value, str):
            return cls._find_criteria_in_text(value)
        return None

    @classmethod
    def _text_values(cls, value: Any) -> Iterator[str]:
        if isinstance(value, dict):
            for key, child in value.items():
                if key.lower() in {"content", "text", "message", "response", "output", "delta", "token"} and isinstance(child, str):
                    yield child
                yield from cls._text_values(child)
        elif isinstance(value, list):
            for child in value:
                yield from cls._text_values(child)

    def _extract_locally(
        self,
        message: str,
        language_preference: Language | None,
        conversation_language: Language | None,
        known_product_names: list[str],
    ) -> SearchCriteria:
        text = normalise(message)
        language = (
            language_preference
            or self._detect_language(text)
            or conversation_language
            or "en"
        )

        intent = "product_search"
        if any(term in text for term in ["hello", "hi ", "bonjour", "salut", "ola", "bom dia"]):
            intent = "greeting"
        if any(term in text for term in ["compare", "comparar", "comparaison", "versus", " vs "]):
            intent = "compare"
        elif (
            any(term in text for term in ["why", "pourquoi", "porque", "por que"])
            and any(term in text for term in ["sustain", "durable", "sustent"])
        ):
            intent = "sustainability_followup"
        elif any(term in text for term in ["details", "detail", "tell me more", "en savoir", "mais informacao"]):
            intent = "product_details"
        elif any(term in text for term in ["what can you do", "help", "aide", "ajuda"]):
            intent = "help"

        category = next(
            (
                category_name
                for category_name, terms in CATEGORY_TERMS.items()
                if any(term in text for term in terms)
            ),
            None,
        )
        max_price = self._extract_max_price(text)
        compact = any(
            term in text
            for term in ["small", "compact", "limited space", "petit", "pequeno", "pouco espaco"]
        )
        sustainable = any(term in text for term in ["sustain", "durable", "sustent", "fsc", "recycled"])
        colors = [
            color
            for color, terms in COLOR_TERMS.items()
            if any(term in text for term in terms)
        ]
        product_names = [
            name for name in known_product_names if normalise(name).split()[0] in text
        ]
        materials = [
            material
            for material in ["oak", "carvalho", "chene", "metal", "cotton", "algodao", "velvet", "velours"]
            if material in text
        ]
        return SearchCriteria(
            intent=intent,
            language=language,
            category=category,
            max_price=max_price,
            compact=compact,
            sustainable=sustainable,
            colors=colors,
            materials=materials,
            product_names=product_names,
        )

    @staticmethod
    def _detect_language(text: str) -> Language | None:
        scores = {
            language: sum(hint in text for hint in hints)
            for language, hints in LANGUAGE_HINTS.items()
        }
        if scores["pt"] > scores["fr"] and scores["pt"] > 0:
            return "pt"
        if scores["fr"] > 0:
            return "fr"
        english_hints = ["i need", "show me", "why", "under", "desk", "sofa", "compare", "hello"]
        if any(hint in text for hint in english_hints):
            return "en"
        return None

    @staticmethod
    def _extract_max_price(text: str) -> float | None:
        patterns = [
            r"(?:under|below|up to|max(?:imum)?|menos de|ate|abaixo de|moins de|jusqu.?a)\s*\u20ac?\s*([\d\s.,]+)",
            r"\u20ac\s*([\d\s.,]+)",
            r"([\d\s.,]+)\s*(?:\u20ac|euros?)",
        ]
        for pattern in patterns:
            match = re.search(pattern, text)
            if match:
                raw_value = re.sub(r"\s", "", match.group(1)).strip(".,")
                if re.fullmatch(r"\d{1,3}(?:[.,]\d{3})+", raw_value):
                    raw_value = raw_value.replace(",", "").replace(".", "")
                else:
                    raw_value = raw_value.replace(",", ".")
                try:
                    return float(raw_value)
                except ValueError:
                    continue
        return None
