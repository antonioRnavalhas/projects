from __future__ import annotations

import json
import unicodedata
from pathlib import Path

from app.models import Product, SearchCriteria


def normalise(value: str) -> str:
    return "".join(
        character
        for character in unicodedata.normalize("NFKD", value.lower())
        if not unicodedata.combining(character)
    )


class ProductRepository:
    def __init__(self, data_path: Path):
        raw_products = json.loads(data_path.read_text(encoding="utf-8"))
        self._products = [Product.model_validate(item) for item in raw_products]
        self._by_id = {product.id: product for product in self._products}

    def all(self) -> list[Product]:
        return list(self._products)

    def get(self, product_id: str) -> Product | None:
        return self._by_id.get(product_id)

    def get_many(self, product_ids: list[str]) -> list[Product]:
        return [self._by_id[item] for item in product_ids if item in self._by_id]

    def find_by_names(self, names: list[str]) -> list[Product]:
        matches: list[Product] = []
        for requested_name in names:
            needle = normalise(requested_name)
            candidate = next(
                (
                    product
                    for product in self._products
                    if needle in normalise(product.name) or normalise(product.name) in needle
                ),
                None,
            )
            if candidate and candidate not in matches:
                matches.append(candidate)
        return matches

    def search(self, criteria: SearchCriteria, limit: int = 4) -> list[Product]:
        candidates: list[tuple[float, Product]] = []
        compact_limits = {
            "sofa": 175,
            "desk": 120,
            "table": 140,
            "chair": 55,
            "lighting": 40,
            "textile": 250,
        }

        for product in self._products:
            if criteria.category:
                if criteria.category == "dining" and product.category not in {"table", "chair"}:
                    continue
                if criteria.category != "dining" and product.category != criteria.category:
                    continue
            if criteria.max_price is not None and product.price > criteria.max_price:
                continue
            if criteria.min_price is not None and product.price < criteria.min_price:
                continue
            if criteria.compact and product.width_cm > compact_limits[product.category]:
                continue
            if criteria.sustainable and not product.sustainability:
                continue
            if criteria.colors and not set(criteria.colors).intersection(product.colors):
                continue

            haystack = normalise(
                " ".join(
                    [
                        product.name,
                        product.category,
                        *product.tags,
                        product.material.en,
                        product.material.fr,
                        product.material.pt,
                    ]
                )
            )
            if criteria.materials and not any(
                normalise(material) in haystack for material in criteria.materials
            ):
                continue

            score = product.rating
            score += 1.5 if criteria.category == product.category else 0
            score += 1.0 if criteria.sustainable and product.sustainability else 0
            score += 0.5 if criteria.compact else 0
            if criteria.max_price:
                score += max(0, (criteria.max_price - product.price) / criteria.max_price)
            candidates.append((score, product))

        candidates.sort(key=lambda item: (-item[0], item[1].price))
        return [product for _, product in candidates[:limit]]
