import numpy as np
from sklearn.metrics import mean_absolute_error, mean_squared_error


def compute_forecast_metrics(y_true, y_pred):
    """
    Calcula MAE, RMSE e MAPE (com filtro para evitar divisão por zero).
    Retorna dict com as 3 métricas.
    """
    mae = mean_absolute_error(y_true, y_pred)
    rmse = np.sqrt(mean_squared_error(y_true, y_pred))
    mask = np.abs(y_true) > 1e-8
    mape = np.mean(np.abs((y_true[mask] - y_pred[mask]) / y_true[mask])) * 100
    return {'MAE': mae, 'RMSE': rmse, 'MAPE': mape}
