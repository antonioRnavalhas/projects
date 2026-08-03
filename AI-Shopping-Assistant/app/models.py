from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

Language = Literal["en", "fr", "pt"]
IntentName = Literal[
    "product_search",
    "compare",
    "sustainability_followup",
    "product_details",
    "greeting",
    "help",
]


class LocalisedText(BaseModel):
    en: str
    fr: str
    pt: str

    def for_language(self, language: Language) -> str:
        return getattr(self, language)


class SustainabilityEvidence(BaseModel):
    label: LocalisedText
    detail: LocalisedText


class Product(BaseModel):
    id: str
    name: str
    category: Literal["sofa", "desk", "table", "chair", "lighting", "textile"]
    price: float = Field(gt=0)
    rating: float = Field(ge=0, le=5)
    width_cm: int = Field(gt=0)
    height_cm: int = Field(gt=0)
    depth_cm: int = Field(gt=0)
    colors: list[str]
    material: LocalisedText
    description: LocalisedText
    tags: list[str]
    sustainability: list[SustainabilityEvidence] = Field(default_factory=list)
    image: str

    def public_dict(self, language: Language) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "category": self.category,
            "price": self.price,
            "rating": self.rating,
            "width_cm": self.width_cm,
            "height_cm": self.height_cm,
            "depth_cm": self.depth_cm,
            "colors": self.colors,
            "material": self.material.for_language(language),
            "description": self.description.for_language(language),
            "sustainability": [
                {
                    "label": evidence.label.for_language(language),
                    "detail": evidence.detail.for_language(language),
                }
                for evidence in self.sustainability
            ],
            "image": self.image,
            "illustrative_image": True,
        }


class SearchCriteria(BaseModel):
    intent: IntentName = "product_search"
    language: Language = "en"
    category: Literal["sofa", "desk", "table", "chair", "dining", "lighting", "textile"] | None = None
    max_price: float | None = Field(default=None, gt=0)
    min_price: float | None = Field(default=None, ge=0)
    compact: bool = False
    sustainable: bool = False
    colors: list[str] = Field(default_factory=list)
    materials: list[str] = Field(default_factory=list)
    product_names: list[str] = Field(default_factory=list)


class ChatRequest(BaseModel):
    session_id: str | None = Field(default=None, max_length=80)
    message: str = Field(min_length=1, max_length=1000)
    language: Language | None = None
    selected_product_ids: list[str] = Field(default_factory=list, max_length=3)


class ChatResponse(BaseModel):
    session_id: str
    language: Language
    mode: Literal["demo", "ai"]
    intent: IntentName
    message: str
    products: list[dict] = Field(default_factory=list)
    comparison: list[dict] = Field(default_factory=list)
    suggestions: list[str] = Field(default_factory=list)


class HealthResponse(BaseModel):
    status: Literal["ok"]
    mode: Literal["demo", "ai"]
    provider: str | None
