import pandas as pd
import numpy as np


def load_and_align_data(file_stocks, file_epu, file_fx):
    """
    Carrega as 3 séries temporais, trata as datas, reamostra frequências
    e faz um inner join para garantir o mesmo número de observações.
    """
    df_stocks = pd.read_csv(file_stocks)
    df_epu = pd.read_csv(file_epu)
    df_fx = pd.read_csv(file_fx)

    df_stocks['observation_date'] = pd.to_datetime(df_stocks['observation_date'])
    df_stocks.set_index('observation_date', inplace=True)
    df_stocks.rename(columns={'SPASTT01FRM657N': 'Stocks'}, inplace=True)

    df_epu['observation_date'] = pd.to_datetime(df_epu['observation_date'])
    df_epu.set_index('observation_date', inplace=True)
    df_epu.rename(columns={'FREUINDXM': 'EPU'}, inplace=True)

    df_fx['observation_date'] = pd.to_datetime(df_fx['observation_date'])
    df_fx.set_index('observation_date', inplace=True)
    df_fx.rename(columns={'DEXUSEU': 'EUR_USD'}, inplace=True)

    df_fx['EUR_USD'] = pd.to_numeric(df_fx['EUR_USD'], errors='coerce')
    df_fx_monthly = df_fx.resample('MS').mean()

    df_final = pd.concat([df_stocks, df_epu, df_fx_monthly], axis=1, join='inner')
    assert df_final.isnull().sum().sum() == 0, "Aviso: Ainda existem valores nulos no dataset final."

    return df_final


def transform_series(df_orig):
    """
    Aplica transformação adequada a cada variável.
    - Stocks: mantida sem transformação (já é taxa de variação mensal)
    - EPU e EUR_USD: diff(log) para tornar estacionárias
    """
    df_t = pd.DataFrame(index=df_orig.index)
    df_t['Stocks'] = df_orig['Stocks']
    df_t['EPU'] = np.log(df_orig['EPU']).diff()
    df_t['EUR_USD'] = np.log(df_orig['EUR_USD']).diff()
    return df_t.dropna()
