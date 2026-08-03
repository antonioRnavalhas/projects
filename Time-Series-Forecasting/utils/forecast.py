import numpy as np
import pandas as pd


def mlp_iterative_forecast(best_mlp, scaler_X, scaler_y, full_diff_all,
                           target_col, n_lags, future_index):
    """
    Forecast iterativo com MLP: prevê um passo de cada vez,
    usando a previsão anterior como input para o próximo passo.
    Retorna pd.Series com as previsões.
    """
    last_values = full_diff_all.iloc[-n_lags:].copy()
    predictions = []

    for step in range(len(future_index)):
        features = []
        for col in full_diff_all.columns:
            for lag in range(1, n_lags + 1):
                features.append(last_values[col].iloc[-lag])

        features_scaled = scaler_X.transform(np.array(features).reshape(1, -1))
        pred_scaled = best_mlp.predict(features_scaled)
        pred = scaler_y.inverse_transform(pred_scaled.reshape(-1, 1)).ravel()[0]
        predictions.append(pred)

        new_row = pd.DataFrame(
            {target_col: pred,
             'EPU': full_diff_all['EPU'].mean(),
             'EUR_USD': full_diff_all['EUR_USD'].mean()},
            index=[future_index[step]]
        )
        last_values = pd.concat([last_values, new_row]).iloc[-n_lags:]

    return pd.Series(predictions, index=future_index)
