# E-commerce Conversion Propensity

Portfolio case study for predicting purchase propensity during an active e-commerce session.

## Objective

Rank sessions by their probability of conversion so that marketing and on-site interventions can focus on visitors with the strongest purchase intent.

## Contents

- `conversion_propensity_analysis.ipynb` - complete exploratory analysis, feature engineering, modelling and evaluation.
- `presentation.html` - concise business presentation.
- `notebook_export.html` - browser-friendly rendering of the technical analysis.
- `ecommerce_sessions.csv` - fully synthetic session-level sample with the same schema.
- `generate_synthetic_data.py` - deterministic generator for the public sample.

## Methods

The project covers rare-event classification, temporal and behavioural feature engineering, interpretable model comparison, ranking metrics, propensity deciles and practical activation recommendations.

## Privacy note

Company references and data-source identifiers were removed or generalized for this public portfolio version. The included CSV is fully synthetic and contains no rows or identifiers from the original data. Aggregate results displayed in the saved notebook and HTML export belong to the original analysis and may differ when the notebook is rerun with the synthetic sample.

## Run locally

Install the Python packages imported by the notebook, open `conversion_propensity_analysis.ipynb`, and run the cells from top to bottom with `ecommerce_sessions.csv` in the same directory.
