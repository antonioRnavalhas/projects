import pandas as pd


def create_lagged_features(df, target_col, n_lags=6):
    """
    Cria features baseadas em lags para alimentar o MLP.
    Inclui lags da variável alvo e das exógenas.
    Retorna (X, y, index).
    """
    data = df.copy()
    features = []

    for col in data.columns:
        for lag in range(1, n_lags + 1):
            col_name = f"{col}_lag{lag}"
            data[col_name] = data[col].shift(lag)
            features.append(col_name)

    data = data.dropna()
    X = data[features]
    y = data[target_col]
    return X, y, data.index
