import pandas as pd
from statsmodels.tsa.stattools import grangercausalitytests


def run_granger_tests(df, max_lags=6):
    """
    Executa testes de causalidade de Granger para todos os pares de variáveis.
    Retorna DataFrame com os resultados formatados.
    """
    variables = df.columns.tolist()
    rows = []

    for target in variables:
        for predictor in variables:
            if target != predictor:
                pair_name = f"{predictor} → {target}"
                test_data = df[[target, predictor]].dropna()
                try:
                    result = grangercausalitytests(test_data, maxlag=max_lags, verbose=False)
                    min_p = min([result[lag][0]['ssr_ftest'][1] for lag in range(1, max_lags + 1)])
                    sig = "***" if min_p < 0.01 else "**" if min_p < 0.05 else "*" if min_p < 0.10 else ""
                    conclusao = "Rejeita H0 (Granger-causa)" if min_p < 0.05 else "Não rejeita H0"
                    rows.append({
                        'Preditor → Alvo': pair_name,
                        'Min p-value': round(min_p, 4),
                        'Significância': sig,
                        'Conclusão': conclusao
                    })
                except Exception as e:
                    rows.append({
                        'Preditor → Alvo': pair_name,
                        'Min p-value': None,
                        'Significância': 'Erro',
                        'Conclusão': str(e)
                    })

    return pd.DataFrame(rows)
