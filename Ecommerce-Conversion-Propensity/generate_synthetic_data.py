"""Generate a deterministic synthetic dataset for the portfolio case study."""

import csv
import random
from datetime import datetime, timedelta, timezone
from pathlib import Path


SEED = 42
ROWS = 5_000
OUTPUT = Path(__file__).with_name("ecommerce_sessions.csv")

COUNTRIES = [
    ("Portugal", "Lisbon"),
    ("Spain", "Madrid"),
    ("France", "Ile-de-France"),
    ("Germany", "Berlin"),
    ("United Kingdom", "England"),
]
DEVICES = ["desktop", "mobile", "tablet"]
BROWSERS = ["Chrome", "Safari", "Firefox", "Edge"]
CHANNELS = [
    ("organic", "search-engine"),
    ("referral", "partner.example"),
    ("email", "newsletter"),
    ("cpc", "paid-media"),
    ("(none)", "(direct)"),
]
PAGES = [
    "/home",
    "/catalog/apparel",
    "/catalog/accessories",
    "/catalog/electronics",
    "/product/featured-item",
    "/basket",
    "/checkout",
]
FIELDS = [
    "userId", "sessId", "newVisitor", "visitStartTime", "weekday", "hour",
    "medium", "source", "device", "browser", "country", "region",
    "transaction", "sessionNumber", "landingPage", "hitTimeLP", "secondPage",
    "hitsTimeSecondPage", "thirdPage", "hitsTimeThirdPage",
]


def main() -> None:
    rng = random.Random(SEED)
    start = datetime(2025, 1, 1, tzinfo=timezone.utc)
    users = [str(8_000_000_000 + i) for i in range(1, 3_501)]

    with OUTPUT.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS)
        writer.writeheader()

        for index in range(1, ROWS + 1):
            user_id = rng.choice(users)
            timestamp = start + timedelta(minutes=rng.randrange(31 * 24 * 60))
            medium, source = rng.choice(CHANNELS)
            device = rng.choices(DEVICES, weights=[55, 40, 5])[0]
            country, region = rng.choice(COUNTRIES)
            second_page = rng.choice(PAGES[1:]) if rng.random() < 0.62 else ""
            third_page = rng.choice(PAGES[2:]) if second_page and rng.random() < 0.48 else ""

            purchase_score = 0.004
            purchase_score += 0.025 if third_page else 0
            purchase_score += 0.035 if third_page in {"/basket", "/checkout"} else 0
            purchase_score += 0.012 if medium in {"email", "cpc"} else 0
            transaction = int(rng.random() < purchase_score)

            second_time = rng.randint(2_000, 90_000) if second_page else ""
            third_time = second_time + rng.randint(2_000, 120_000) if third_page else ""
            writer.writerow({
                "userId": user_id,
                "sessId": str(9_000_000_000_000_000 + index),
                "newVisitor": int(rng.random() < 0.72),
                "visitStartTime": int(timestamp.timestamp()),
                "weekday": timestamp.isoweekday(),
                "hour": timestamp.hour,
                "medium": medium,
                "source": source,
                "device": device,
                "browser": rng.choice(BROWSERS),
                "country": country,
                "region": region,
                "transaction": transaction,
                "sessionNumber": rng.choices([1, 2, 3, 4], weights=[72, 18, 7, 3])[0],
                "landingPage": rng.choice(PAGES[:5]),
                "hitTimeLP": 0,
                "secondPage": second_page,
                "hitsTimeSecondPage": second_time,
                "thirdPage": third_page,
                "hitsTimeThirdPage": third_time,
            })

    print(f"Generated {ROWS:,} synthetic sessions in {OUTPUT.name}")


if __name__ == "__main__":
    main()
