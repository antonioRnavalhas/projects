from app.models import SearchCriteria


def test_sustainable_dining_returns_only_evidenced_products(repository):
    products = repository.search(
        SearchCriteria(category="dining", sustainable=True, language="en")
    )

    assert [product.id for product in products] == ["table-extend", "chair-cane"]
    assert all(product.sustainability for product in products)


def test_compact_sofa_budget_is_a_hard_constraint(repository):
    products = repository.search(
        SearchCriteria(
            category="sofa",
            compact=True,
            max_price=1000,
            language="en",
        )
    )

    assert products
    assert all(product.width_cm <= 175 for product in products)
    assert all(product.price <= 1000 for product in products)
    assert "sofa-harbor" not in [product.id for product in products]


def test_unknown_product_ids_are_ignored(repository):
    products = repository.get_many(["desk-nordic", "does-not-exist"])
    assert [product.id for product in products] == ["desk-nordic"]
