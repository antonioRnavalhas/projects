import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from sklearn.metrics import mean_squared_error


def plot_series(dataframe, title="Séries Temporais"):
    """Plota cada coluna do dataframe num subplot separado."""
    fig, axes = plt.subplots(len(dataframe.columns), 1, figsize=(12, 10), sharex=True)
    for i, col in enumerate(dataframe.columns):
        dataframe[col].plot(ax=axes[i], title=col)
    plt.suptitle(title, fontsize=14)
    plt.tight_layout()
    plt.show()


def plot_comparison(y_test, forecasts_dict, title='Previsão Out-of-Sample: Série Real vs Top 3 Modelos'):
    """
    Plota série real vs previsões de múltiplos modelos.
    forecasts_dict: {nome_modelo: (series_previsão, rmse)}
    """
    fig, ax = plt.subplots(figsize=(14, 6))
    ax.plot(y_test.index, y_test.values, 'k-o', linewidth=2, markersize=4, label='Real', alpha=0.9)

    styles = [('b--s', 3), ('r--^', 3), ('g--D', 3)]
    for i, (name, (forecast, rmse)) in enumerate(forecasts_dict.items()):
        style, ms = styles[i % len(styles)]
        ax.plot(forecast.index, forecast.values, style, linewidth=1.5, markersize=ms,
                label=f'{name} (RMSE={rmse:.3f})')

    ax.axhline(0, color='gray', alpha=0.3)
    ax.set_title(title, fontsize=14)
    ax.set_xlabel('Data')
    ax.set_ylabel('Variação Mensal (%) - Stocks França')
    ax.legend(loc='best', fontsize=10)
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()


def plot_individual_models(models_forecasts):
    """
    Plota previsão individual de cada modelo.
    models_forecasts: lista de (nome, forecast_series, y_real, cor)
    """
    fig, axes = plt.subplots(len(models_forecasts), 1, figsize=(14, 12), sharex=True)

    for i, (name, forecast, y_real, color) in enumerate(models_forecasts):
        axes[i].plot(y_real.index, y_real.values, 'k-o', linewidth=1.5, markersize=3, label='Real')
        axes[i].plot(forecast.index, forecast.values, '--', color=color, linewidth=1.5,
                     marker='s', markersize=3, label=f'Previsto ({name})')
        common_idx = y_real.index.intersection(forecast.index)
        rmse_i = np.sqrt(mean_squared_error(y_real.loc[common_idx], forecast.loc[common_idx]))
        axes[i].set_title(f'Modelo {i+1}: {name} (RMSE = {rmse_i:.3f})', fontsize=12)
        axes[i].axhline(0, color='gray', alpha=0.3)
        axes[i].legend(loc='best')
        axes[i].grid(True, alpha=0.3)
        axes[i].set_ylabel('Variação Mensal (%)')

    axes[-1].set_xlabel('Data')
    plt.suptitle('Previsões Individuais dos Top 3 Modelos', fontsize=14)
    plt.tight_layout()
    plt.show()


def plot_forecast_10(full_diff_all, target_col, future_index,
                     forecast_10_sarimax, forecast_10_var, forecast_10_mlp_series,
                     cum_sarimax, cum_var, cum_mlp):
    """Plota o forecast 10 passos à frente com painel de retorno acumulado."""
    fig, axes = plt.subplots(2, 1, figsize=(13, 9))

    last_obs = full_diff_all[target_col].iloc[-24:]
    axes[0].plot(last_obs.index, last_obs.values, 'k-', linewidth=2, label='Observado')
    axes[0].plot(forecast_10_sarimax.index, forecast_10_sarimax.values, 'b--o', markersize=5, label='SARIMAX')
    axes[0].plot(forecast_10_var.index, forecast_10_var.values, 'r--s', markersize=5, label='VAR')
    axes[0].plot(forecast_10_mlp_series.index, forecast_10_mlp_series.values, 'g--^', markersize=5, label='MLP')
    axes[0].axvline(full_diff_all.index[-1], color='gray', linestyle=':', alpha=0.7, label='Início Forecast')
    axes[0].axhline(0, color='gray', alpha=0.3)
    axes[0].set_title('Forecast 10 Meses à Frente - Variação Mensal (%) Ações França', fontsize=13)
    axes[0].set_ylabel('Variação Mensal (%)')
    axes[0].legend(loc='best')
    axes[0].grid(True, alpha=0.3)

    axes[1].plot(future_index, cum_sarimax, 'b--o', markersize=5, label='SARIMAX')
    axes[1].plot(future_index, cum_var, 'r--s', markersize=5, label='VAR')
    axes[1].plot(future_index, cum_mlp, 'g--^', markersize=5, label='MLP')
    axes[1].axhline(0, color='gray', alpha=0.3)
    axes[1].set_title('Retorno Acumulado Previsto (10 meses)', fontsize=13)
    axes[1].set_xlabel('Data')
    axes[1].set_ylabel('Retorno Acumulado (%)')
    axes[1].legend(loc='best')
    axes[1].grid(True, alpha=0.3)

    plt.tight_layout()
    plt.show()
