# ==============================================================
# Modelação Bayesiana
# ESTRUTURA: Mediadores Paralelos (Ordinal e Não-Métrico)
# Motor: RStan | Dataset: Dataset.csv | País: LU - Luxembourg
# Grupo 01
# ==============================================================


# Configurações iniciais
# --------------------------------------------------------------
packages <- c(
  "dplyr", "ggplot2", "tidyr", "tibble", "dagitty", "ggdag",
  "rstan", "bayesplot", "posterior"
)

installed <- packages %in% rownames(installed.packages())
if (any(!installed)) install.packages(packages[!installed])
invisible(lapply(packages, library, character.only = TRUE))

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)
set.seed(42)


# 1. Carregar dataset e filtrar os dados de LU

data_raw <- read.csv("Dataset.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
PAIS_SELECIONADO <- "LU - Luxembourg"
COD_PAIS <- "lu"
data_pais <- data_raw %>% filter(country == PAIS_SELECIONADO)

if (nrow(data_pais) == 0) stop("Não existem observações para o país selecionado.")


# 2. Selecioar os dados necessários + limpeza de missing values

col_regiao <- paste0("d12", COD_PAIS)
data_sel <- data_pais %>%
  select(
    uniqid, regiao = all_of(col_regiao), adota_ia = q14.1, setor = d1b, 
    dimensao = dx3a, turnover = dx5, prop_solo = dx6.1, prop_multi = dx6.2, 
    prop_grupo = dx6.3, prop_publico = dx6.4, obstaculo = q1a
  )

clean_invalid <- function(x) {
  if (!is.character(x)) return(x)
  x <- trimws(x)
  invalid <- grepl("^Inap\\.|Not applicable|Don['’]t know|^998$|^9999998$|^NA$", x, ignore.case = TRUE)
  x[invalid] <- NA_character_
  x
}

data_clean <- data_sel %>% mutate(across(where(is.character), clean_invalid))
data_clean <- data_clean %>% filter(!is.na(adota_ia), !is.na(dimensao), !is.na(turnover))


# 3. Turnover ordinal e obstáculo binário

cod_dx6 <- function(x, valor) { case_when(x == valor ~ 1L, x == "Not mentioned" ~ 0L, TRUE ~ NA_integer_) }
normalize_01 <- function(x) { (x - min(x, na.rm=TRUE)) / (max(x, na.rm=TRUE) - min(x, na.rm=TRUE)) }

data_model <- data_clean %>%
  mutate(
    Y_adota_ia = case_when(adota_ia == "Artificial intelligence, e.g. machine learning, Large Language Models" ~ 1L, adota_ia == "Not mentioned" ~ 0L, TRUE ~ NA_integer_),
    X_dimensao = case_when(dimensao == "1 to 9 employees" ~ 1L, dimensao == "10 to 49 employees" ~ 2L, dimensao == "50 to 249 employees" ~ 3L, dimensao == "250 to 499 employees" ~ 4L, dimensao == "500 employees or more" ~ 5L, TRUE ~ NA_integer_),
    
    M_turnover_ord = case_when(turnover == "100,000 euros or less" ~ 1L, turnover == "More than 100,000 and up to 500,000 euros" ~ 2L, turnover == "More than 500,000 and up to 1 million euros" ~ 3L, turnover == "More than 1 million and up to 2 million euros" ~ 4L, turnover == "More than 2 million and up to 5 million euros" ~ 5L, turnover == "More than 5 million and up to 10 million euros" ~ 6L, turnover == "More than 10 million and up to 50 million euros" ~ 7L, turnover == "More than 50 million euros" ~ 8L, TRUE ~ NA_integer_),
    
    X_setor_digital = case_when(setor %in% c("Digital", "Health", "Electronics") ~ 1L, is.na(setor) ~ NA_integer_, TRUE ~ 0L),
    X_prop_grupo = cod_dx6(prop_grupo, "Part of a national or international enterprise group"),
    X_prop_solo = case_when(prop_solo == "Not mentioned" ~ 0L, !is.na(prop_solo) ~ 1L, TRUE ~ NA_integer_),
    X_prop_publico = case_when(prop_publico == "Not mentioned" ~ 0L, !is.na(prop_publico) ~ 1L, TRUE ~ NA_integer_),
    
    M_dig_obstaculo = case_when(obstaculo == "Difficulties with digitalisation" ~ 1L, is.na(obstaculo) ~ NA_integer_, TRUE ~ 0L),
    
    X_dimensao_n = normalize_01(X_dimensao),
    M_turnover_n = normalize_01(M_turnover_ord) 
  )

data_final <- data_model %>%
  select(uniqid, Y_adota_ia, X_dimensao_n, M_turnover_ord, M_turnover_n, X_setor_digital, 
         X_prop_grupo, X_prop_solo, X_prop_publico, M_dig_obstaculo) %>%
  drop_na()


# 4. Gráfico DAG

dag_modelo <- dagitty('dag {
  X_dimensao      [pos="0.0,3.0"]
  X_setor_digital [pos="0.0,1.5"]
  X_prop_grupo    [pos="0.0,0.5"]
  X_prop_solo     [pos="0.0,-0.5"]
  X_prop_publico  [pos="0.0,-1.5"]
  M_turnover      [pos="2.0,3.5"]
  M_dig_obstaculo [pos="2.0,2.0"]
  Y_adota_ia      [pos="4.5,1.0", outcome]
  
  X_dimensao -> M_turnover
  X_dimensao -> M_dig_obstaculo
  X_dimensao -> Y_adota_ia
  
  M_turnover -> M_dig_obstaculo
  M_turnover -> Y_adota_ia
  M_dig_obstaculo -> Y_adota_ia
  
  X_setor_digital -> Y_adota_ia
  X_prop_grupo -> Y_adota_ia
  X_prop_solo -> Y_adota_ia
  X_prop_publico -> Y_adota_ia
}')

dag_tidy <- tidy_dagitty(dag_modelo) %>%
  mutate(
    tipo = case_when(
      name == "Y_adota_ia" ~ "Variável dependente", 
      name %in% c("M_dig_obstaculo", "M_turnover") ~ "Variável mediadora", 
      TRUE ~ "Variáveis explicativas"
    ),
    rotulo = case_when(
      name == "X_dimensao" ~ "Dimensão", 
      name == "M_turnover" ~ "Turnover\n(Ordinal)", 
      name == "X_setor_digital" ~ "Setor\ndigital", 
      name == "X_prop_grupo" ~ "Grupo\nempresarial", 
      name == "X_prop_solo" ~ "Empresa\nIndependente", 
      name == "X_prop_publico" ~ "Entidade\nPública", 
      name == "M_dig_obstaculo" ~ "Obstáculo\n(Binário)", 
      name == "Y_adota_ia" ~ "Adoção\nde IA", 
      TRUE ~ name
    )
  )

p_dag <- ggplot(dag_tidy, aes(x = x, y = y, xend = xend, yend = yend)) +
  geom_dag_edges(edge_width = 0.9, edge_colour = "grey35", arrow_directed = grid::arrow(length = grid::unit(10, "pt"), type = "closed")) +
  geom_dag_point(aes(fill = tipo), shape = 21, size = 18, stroke = 1.15, colour = "grey15") +
  geom_dag_text(aes(label = rotulo), colour = "white", size = 2.8, fontface = "bold", lineheight = 0.95) +
  scale_fill_manual(values = c("Variável dependente" = "#8E1B1B", "Variável mediadora" = "#C76A11", "Variáveis explicativas" = "#1F5E99")) +
  coord_equal() + theme_dag() + theme(legend.position = "bottom", legend.title = element_blank())

ggsave("01_DAG_paralelo.png", p_dag, width = 12, height = 8, bg = "white")


# 5. Utilização de STAN (Mediação Paralela)

stan_code <- "
data {
  int<lower=1> N;
  array[N] int<lower=0, upper=1> Y;       
  array[N] int<lower=0, upper=1> M_obs;   
  array[N] int<lower=1, upper=8> M_turn_ord; 
  vector[N] M_turn_n;                        
  vector[N] X_dim;
  vector[N] X_setor;
  vector[N] X_grupo;
  vector[N] X_solo;         
  vector[N] X_publico;      
  real prior_sd;            
}
transformed data {
  vector[N] M_obs_vec;
  for (n in 1:N) {
    M_obs_vec[n] = M_obs[n];
  }
}
parameters {
  real beta_T_dim;
  ordered[7] c_turn; 
  real alpha_O;
  real beta_O_dim;
  real beta_O_turn;
  real alpha_Y;
  real beta_Y_dim;
  real beta_Y_turn;
  real beta_Y_setor;
  real beta_Y_grupo;
  real beta_Y_solo;         
  real beta_Y_publico;      
  real beta_Y_obs;
}
model {
  beta_T_dim ~ normal(0, prior_sd);
  c_turn ~ normal(0, 5);
  alpha_O ~ normal(0, prior_sd);
  beta_O_dim ~ normal(0, prior_sd);
  beta_O_turn ~ normal(0, prior_sd);
  alpha_Y ~ normal(0, prior_sd);
  beta_Y_dim ~ normal(0, prior_sd);
  beta_Y_turn ~ normal(0, prior_sd);
  beta_Y_setor ~ normal(0, prior_sd);
  beta_Y_grupo ~ normal(0, prior_sd);
  beta_Y_solo ~ normal(0, prior_sd);      
  beta_Y_publico ~ normal(0, prior_sd);   
  beta_Y_obs ~ normal(0, prior_sd);

  for (n in 1:N) {
    M_turn_ord[n] ~ ordered_logistic(beta_T_dim * X_dim[n], c_turn);
  }
  M_obs ~ bernoulli_logit(alpha_O + beta_O_dim * X_dim + beta_O_turn * M_turn_n);
  Y ~ bernoulli_logit(alpha_Y + beta_Y_dim * X_dim + beta_Y_turn * M_turn_n + 
                      beta_Y_setor * X_setor + beta_Y_grupo * X_grupo + 
                      beta_Y_solo * X_solo + beta_Y_publico * X_publico + 
                      beta_Y_obs * M_obs_vec); 
}
"
cat("\nA compilar modelo em Stan (Mediação Paralela)...\n")
modelo_compilado <- stan_model(model_code = stan_code)


# 6. Configuração de dados para RSTAN

stan_data_base <- list(
  N = nrow(data_final), Y = data_final$Y_adota_ia, M_obs = data_final$M_dig_obstaculo,
  M_turn_ord = data_final$M_turnover_ord, M_turn_n = data_final$M_turnover_n, 
  X_dim = data_final$X_dimensao_n, X_setor = data_final$X_setor_digital, 
  X_grupo = data_final$X_prop_grupo, X_solo = data_final$X_prop_solo, 
  X_publico = data_final$X_prop_publico
)

data_fraca <- modifyList(stan_data_base, list(prior_sd = 10.0))
data_moderada <- modifyList(stan_data_base, list(prior_sd = 1.5))
data_informativa <- modifyList(stan_data_base, list(prior_sd = 0.5))


# 7. Estimação MCMC

run_stan <- function(data_list, seed=42) {
  sampling(modelo_compilado, data = data_list, chains=4, iter=4000, warmup=1000, thin=2, seed=seed, control=list(adapt_delta=0.95, max_treedepth=12))
}

cat("\n=== ESTIMANDO CENÁRIO 1: Prior Fraca ===\n"); fit_fraca <- run_stan(data_fraca)
cat("\n=== ESTIMANDO CENÁRIO 2: Prior Moderada ===\n"); fit_moderada <- run_stan(data_moderada)
cat("\n=== ESTIMANDO CENÁRIO 3: Prior Informativa ===\n"); fit_informativa <- run_stan(data_informativa)


# 8. Diagnósticos MCMC + novo gráfico

pars_main <- c("beta_O_turn", "beta_Y_dim", "beta_Y_turn", "beta_Y_setor", "beta_Y_grupo", 
               "beta_Y_solo", "beta_Y_publico", "beta_Y_obs")

cat("\n========================================\nDIAGNÓSTICOS — Prior Moderada\n========================================\n")
sm_mod <- summary(fit_moderada, pars=pars_main)$summary
print(round(sm_mod[, c("mean", "2.5%", "97.5%", "n_eff", "Rhat")], 3))

# Trace Plots (Convergência)
# Mostramos o alpha_Y e três betas principais para recriar o visual do teu exemplo
p_trace <- mcmc_trace(as.array(fit_moderada), pars = c("alpha_Y", "beta_O_turn", "beta_Y_dim", "beta_Y_turn", "beta_Y_obs")) +
  theme_minimal() + labs(title = "Trace plots — Cenário base (Prior Moderada)")
ggsave("02_trace_plots.png", p_trace, width = 12, height = 8, bg = "white")


p_post <- mcmc_areas(as.array(fit_moderada), pars = pars_main, prob = 0.89, prob_outer = 0.95) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "red") +
  labs(title = "Distribuições posteriores — Equação de Adoção", x = "Coeficiente (log-odds)") + theme_minimal()
ggsave("03_posteriores_paralelos.png", p_post, width = 10, height = 8, bg = "white")

# Preparar dados para comparação de cenários e CSV
extract_coefs <- function(fit, cenario) {
  sm <- summary(fit, pars = pars_main)$summary
  data.frame(parametro = rownames(sm), Estimate = sm[, "mean"], Q2.5 = sm[, "2.5%"], Q97.5 = sm[, "97.5%"], cenario = cenario)
}

comp_cenarios <- bind_rows(
  extract_coefs(fit_fraca, "Prior fraca"), 
  extract_coefs(fit_moderada, "Prior moderada"), 
  extract_coefs(fit_informativa, "Prior informativa")
)

# Gráfico de comparação de cenários (Forest Plot)
# Ordenar o fator para garantir a ordem correta das cores
comp_cenarios$cenario <- factor(comp_cenarios$cenario, levels = c("Prior fraca", "Prior informativa", "Prior moderada"))

p_comp <- ggplot(comp_cenarios, aes(x = Estimate, y = parametro, color = cenario, shape = cenario)) +
  geom_point(position = position_dodge(width = 0.6), size = 3.5) +
  geom_errorbarh(aes(xmin = Q2.5, xmax = Q97.5), position = position_dodge(width = 0.6), height = 0.3, linewidth = 0.8) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey40", linewidth = 0.8) +
  scale_color_manual(values = c("Prior fraca" = "#2D82B7", "Prior informativa" = "#429E53", "Prior moderada" = "#D0312D")) +
  scale_shape_manual(values = c("Prior fraca" = 16, "Prior informativa" = 17, "Prior moderada" = 15)) +
  theme_minimal(base_size = 14) +
  labs(title = "Robustez dos resultados face a diferentes prioris", x = "Coeficiente (log-odds)", y = "") +
  theme(legend.position = "bottom", legend.title = element_blank(),
        panel.grid.minor = element_blank(), panel.grid.major.y = element_line(color = "grey90"))

ggsave("04_comparacao_cenarios.png", p_comp, width = 12, height = 7, bg = "white")

# Exportar Tabela
tabela_coefs <- comp_cenarios %>%
  mutate(across(where(is.numeric), ~ round(., 3)), IC_95 = paste0("[", Q2.5, "; ", Q97.5, "]")) %>%
  select(parametro, cenario, Estimate, IC_95)
write.csv(tabela_coefs, "05_tabela_coeficientes.csv", row.names = FALSE)

cat("\nScript totalmente concluído! Todos os gráficos gerados com sucesso.\n")
