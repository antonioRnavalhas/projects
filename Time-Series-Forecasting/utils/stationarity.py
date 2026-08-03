import pandas as pd
from statsmodels.tsa.stattools import adfuller, kpss
from arch.unitroot import PhillipsPerron


def get_stationarity_table(df_to_test):
    """
    Executa os testes ADF, PP e KPSS para todas as colunas de um dataframe.
    Retorna um DataFrame com os resultados.
    """
    results = []
    for col in df_to_test.columns:
        series = df_to_test[col].dropna()

        adf_p = adfuller(series)[1]
        adf_res = 'Estacionária' if adf_p < 0.05 else 'Não-Estacionária'

        pp_p = PhillipsPerron(series).pvalue
        pp_res = 'Estacionária' if pp_p < 0.05 else 'Não-Estacionária'

        kpss_p = kpss(series, regression='c', nlags="auto")[1]
        kpss_res = 'Estacionária' if kpss_p > 0.05 else 'Não-Estacionária'

        results.append({
            'Variável': col,
            'ADF (p-value)': f"{adf_p:.4f}",
            'ADF Res.': adf_res,
            'PP (p-value)': f"{pp_p:.4f}",
            'PP Res.': pp_res,
            'KPSS (p-value)': f"{kpss_p:.4f}",
            'KPSS Res.': kpss_res
        })

    return pd.DataFrame(results)
