"""
Exporta as figuras do trabalho para o relatório LaTeX.
Uso:
    from utils.export_figures import export_report_figures
    export_report_figures(results, fig_dir='relatorio/figures')
"""
import os
import matplotlib.pyplot as plt


def export_report_figures(results: dict, fig_dir: str = 'relatorio/figures') -> None:
    """
    Gera e guarda as três figuras do relatório.

    Parâmetros
    ----------
    results : dict com as chaves:
        y_test              -- pd.Series, valores reais no teste (SARIMAX/VAR)
        y_test_mlp          -- pd.Series, valores reais no teste (MLP — pode ter menos obs.)
        forecast_sarimax    -- pd.Series
        forecast_var        -- pd.Series
        forecast_mlp        -- pd.Series
        metrics_sarimax     -- dict com 'RMSE'
        metrics_var         -- dict com 'RMSE'
        metrics_mlp         -- dict com 'RMSE'
        future_index        -- pd.DatetimeIndex (10 períodos)
        forecast_10_sarimax -- pd.Series
        forecast_10_var     -- pd.Series
        forecast_10_mlp     -- pd.Series
        cum_sarimax         -- array-like (retorno acumulado %)
        cum_var             -- array-like
        cum_mlp             -- array-like
    fig_dir : str
        Directório de destino (criado se não existir).
    """
    os.makedirs(fig_dir, exist_ok=True)

    y_test          = results['y_test']
    y_test_mlp      = results['y_test_mlp']
    fc_sar          = results['forecast_sarimax']
    fc_var          = results['forecast_var']
    fc_mlp          = results['forecast_mlp']
    m_sar           = results['metrics_sarimax']
    m_var           = results['metrics_var']
    m_mlp           = results['metrics_mlp']
    future_index    = results['future_index']
    fc10_sar        = results['forecast_10_sarimax']
    fc10_var        = results['forecast_10_var']
    fc10_mlp        = results['forecast_10_mlp']
    cum_sar         = results['cum_sarimax']
    cum_var         = results['cum_var']
    cum_mlp         = results['cum_mlp']

    # ------------------------------------------------------------------
    # Figura A1 — comparação dos 3 modelos vs. série real
    # ------------------------------------------------------------------
    fig, ax = plt.subplots(figsize=(10, 4))
    ax.plot(y_test.index, y_test.values, 'k-', linewidth=1.5, label='Real')
    ax.plot(fc_sar.index, fc_sar.values, 'b--', linewidth=1.2,
            label=f'SARIMAX (RMSE={m_sar["RMSE"]:.2f})')
    ax.plot(fc_var.index, fc_var.values, 'r--', linewidth=1.2,
            label=f'VAR (RMSE={m_var["RMSE"]:.2f})')
    ax.plot(fc_mlp.index, fc_mlp.values, 'g--', linewidth=1.2,
            label=f'MLP (RMSE={m_mlp["RMSE"]:.2f})')
    ax.set_ylabel('Variação mensal (%)')
    ax.set_title('Previsão fora da amostra — série real vs. modelos (ago./2023–abr./2026)')
    ax.legend(loc='upper left', fontsize=9)
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    fig.savefig(os.path.join(fig_dir, 'comparison.png'), dpi=150, bbox_inches='tight')
    plt.close(fig)

    # ------------------------------------------------------------------
    # Figura — painéis individuais por modelo
    # ------------------------------------------------------------------
    fig, axes = plt.subplots(1, 3, figsize=(13, 4), sharey=True)
    configs = [
        ('SARIMAX', fc_sar, y_test,     'steelblue'),
        ('VAR',     fc_var, y_test,     'firebrick'),
        ('MLP',     fc_mlp, y_test_mlp, 'seagreen'),
    ]
    for ax_i, (name, fc, yt, color) in zip(axes, configs):
        ax_i.plot(yt.index, yt.values, 'k-', linewidth=1.5, label='Real')
        ax_i.plot(fc.index, fc.values, color=color, linestyle='--', linewidth=1.2, label=name)
        ax_i.set_title(name)
        ax_i.set_ylabel('Var. mensal (%)')
        ax_i.legend(fontsize=9)
        ax_i.grid(True, alpha=0.3)
    plt.suptitle('Previsões individuais no conjunto de teste', y=1.01)
    plt.tight_layout()
    fig.savefig(os.path.join(fig_dir, 'individual.png'), dpi=150, bbox_inches='tight')
    plt.close(fig)

    # ------------------------------------------------------------------
    # Figura A2 — forecast a 10 meses
    # ------------------------------------------------------------------
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))

    for vals, fmt, lbl in [
        (fc10_sar.values, 'b-o', 'SARIMAX'),
        (fc10_var.values, 'r-s', 'VAR'),
        (fc10_mlp.values, 'g-^', 'MLP'),
    ]:
        ax1.plot(future_index, vals, fmt, markersize=4, label=lbl)
    ax1.axhline(0, color='gray', linewidth=0.8, linestyle='--')
    ax1.set_title('Variação mensal prevista (%)')
    ax1.set_ylabel('%')
    ax1.legend(fontsize=9)
    ax1.grid(True, alpha=0.3)
    ax1.tick_params(axis='x', rotation=45)

    for vals, fmt, lbl in [
        (cum_sar, 'b-o', 'SARIMAX'),
        (cum_var, 'r-s', 'VAR'),
        (cum_mlp, 'g-^', 'MLP'),
    ]:
        ax2.plot(future_index, vals, fmt, markersize=4, label=lbl)
    ax2.axhline(0, color='gray', linewidth=0.8, linestyle='--')
    ax2.set_title('Retorno acumulado previsto (%)')
    ax2.set_ylabel('%')
    ax2.legend(fontsize=9)
    ax2.grid(True, alpha=0.3)
    ax2.tick_params(axis='x', rotation=45)

    plt.suptitle('Forecast a 10 meses (mai./2026–fev./2027)', y=1.01)
    plt.tight_layout()
    fig.savefig(os.path.join(fig_dir, 'forecast10.png'), dpi=150, bbox_inches='tight')
    plt.close(fig)

    print(f'Figuras guardadas em {fig_dir}/: comparison.png, individual.png, forecast10.png')
