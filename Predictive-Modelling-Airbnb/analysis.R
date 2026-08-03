library(tidyverse)
library(corrplot)
library(randomForest)
library(rpart)
library(rpart.plot)
library(caret)
library(dplyr)
library(readr)
library(lsr)
library(car)
library(reshape2)
library(lmtest) 
library(rpart)
library(rpart.plot)
library(caret)
library(ranger)
library(gbm)
library(psych)			  


df <- read_delim(
  "listings_Prague_cleaned_3.csv",
  delim = ";",
  locale = locale(decimal_mark = ",")
)


summary(df)


# Remover observações sem preço
df <- df %>% 
  filter(!is.na(price))

# Histograma do preço (limitando ao 99º percentil para ver melhor a distribuição)
ggplot(df, aes(x = price)) +
  geom_histogram(
    bins = 40,
    fill = "orange",
    color = "black",
    alpha = 0.8
  ) +
  scale_x_continuous(
    limits = c(1, quantile(df$price, 0.99, na.rm = TRUE))
  ) +
  labs(
    title = "Distribuição do Preço (cortada no 99º percentil)",
    x = "Preço (€)",
    y = "Frequência"
  ) +
  theme_minimal(base_size = 13)


# Uniformização dos outliers
Q1 <- quantile(df$price, 0.25, na.rm = TRUE)
Q3 <- quantile(df$price, 0.75, na.rm = TRUE)
IQR_price <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR_price
upper_bound <- Q3 + 1.5 * IQR_price
# Winsorização
df$price <- ifelse(df$price < lower_bound, lower_bound,
                   ifelse(df$price > upper_bound, upper_bound, df$price))

# Histograma do preço após uniformização de outliers
ggplot(df, aes(x = price)) +
  geom_histogram(
    bins = 40,
    fill = "orange",
    color = "black",
    alpha = 0.8
  ) +
  scale_x_continuous(
    limits = c(0, quantile(df$price, 0.99, na.rm = TRUE))
  ) +
  labs(
    title = "Distribuição do Preço (cortada no 99º percentil)",
    x = "Preço (€)",
    y = "Frequência"
  ) +
  theme_minimal(base_size = 13)

# Verificar Kurtosis e Skewness do price
describe(df$price)										



# Garantir tipos corretos
df$room_type <- as.factor(df$room_type)
df$price <- as.numeric(df$price)

# Coeficiente de associação ETA para room type vs price
anova_model <- aov(price ~ room_type, data = df)
summary(anova_model)
(Eta_<- sqrt(etaSquared(anova_model)[,1]))


# Violino do price por room_type
ggplot(df, aes(x = room_type, y = price)) +
  geom_violin(trim = FALSE) +
  geom_boxplot(width = 0.1, outlier.shape = NA) +
  scale_y_continuous(limits = c(0, quantile(df$price, 0.99, na.rm = TRUE))) +
  theme_minimal()


# Coeficiente de associação ETA para neighbourhood vs price
anova_model <- aov(price ~ neighbourhood, data = df)
(Eta_<- sqrt(etaSquared(anova_model)[,1]))


# price vs latitude
# Modelo linear simples
lm_latitude <- lm(price ~ latitude, data = df)

plot(
  df$latitude,
  df$price,
  pch = 20,
  main = "Preço vs Latitude",
  xlab = "Latitude",
  ylab = "Preço"
)

# Reta de regressão
abline(lm_latitude, lwd = 2, col = "blue")

# Correlação de Pearson
cor(df$price, df$latitude, use = "complete.obs")
#############

# price vs longitude
# Modelo linear simples
lm_longitude <- lm(price ~ longitude, data = df)

plot(
  df$longitude,
  df$price,
  pch = 20,
  main = "Preço vs Longitude",
  xlab = "Longitude",
  ylab = "Preço"
)

# Reta de regressão
abline(lm_longitude, lwd = 2, col = "blue")

# Correlação de Pearson
cor(df$price, df$longitude, use = "complete.obs")
#############

# price vs minimum_nights
# Modelo linear simples
lm_min_nights <- lm(price ~ minimum_nights, data = df)

# Scatterplot + reta de regressão
plot(
  df$minimum_nights,
  df$price,
  pch = 20,
  main = "Preço vs Número mínimo de noites",
  xlab = "Número mínimo de noites",
  ylab = "Preço"
)

# Reta de regressão
abline(lm_min_nights, lwd = 2, col = "blue")

# Correlação linear de Pearson
cor(df$price, df$minimum_nights, use = "complete.obs")

#############

### price vs number_of_reviews
# Modelo linear simples
lm_reviews <- lm(price ~ number_of_reviews, data = df)

plot(
  df$number_of_reviews,
  df$price,
  pch = 20,
  main = "Preço vs Número de reviews",
  xlab = "Número de reviews",
  ylab = "Preço"
)

# Reta de regressão
abline(lm_reviews, lwd = 2, col = "blue")

cor(df$price, df$number_of_reviews, use = "complete.obs")
#############


### price vs reviews_per_month
# Modelo linear simples
df$reviews_per_month <- as.numeric(df$reviews_per_month)
lm_reviews_month <- lm(price ~ reviews_per_month, data = df)

plot(
  df$reviews_per_month,
  df$price,
  pch = 20,
  main = "Preço vs Reviews por mês",
  xlab = "Reviews por mês",
  ylab = "Preço"
)

# Reta de regressão
abline(lm_reviews_month, lwd = 2, col = "blue")


cor(df$price, df$reviews_per_month, use = "complete.obs")
#############

### price vs calculated_host_listings_count
# Modelo linear simples
lm_host_count <- lm(price ~ calculated_host_listings_count, data = df)

plot(
  df$calculated_host_listings_count,
  df$price,
  pch = 20,
  main = "Preço vs Nº de alojamentos do host",
  xlab = "Nº de alojamentos do host",
  ylab = "Preço"
)

# Reta de regressão
abline(lm_host_count, lwd = 2, col = "blue")

cor(df$price, df$calculated_host_listings_count, use = "complete.obs")
#############

### price vs availability_365
# Modelo linear simples
lm_availability <- lm(price ~ availability_365, data = df)

plot(
  df$availability_365,
  df$price,
  pch = 20,
  main = "Preço vs Disponibilidade anual",
  xlab = "Dias disponíveis por ano",
  ylab = "Preço"
)

# Reta de regressão
abline(lm_availability, lwd = 2, col = "blue")

cor(df$price, df$availability_365, use = "complete.obs")
#############

# Selecionar apenas variáveis numéricas relevantes
num_vars <- df %>%
  select(
    price,
    minimum_nights,
    number_of_reviews,
    reviews_per_month,
    calculated_host_listings_count,
    availability_365,
    latitude,
    longitude
  )

# Matriz de correlação de Spearman
corr_mat <- cor(
  num_vars,
  method = "spearman",
  use = "complete.obs"
)

# Mapa de calor
corrplot(
  corr_mat,
  method = "color",
  type = "upper",
  order = "hclust",     
  addCoef.col = "black",
  number.cex = 0.85,
  tl.col = "black",
  tl.cex = 0.9,
  tl.srt = 35,
  mar = c(0, 0, 1, 0)    
)


# Divisão de dados de treino e teste

set.seed(123)

train_index <- createDataPartition(
  df$price,
  p = 0.7,
  list = FALSE
)

train <- df[train_index, ]
test  <- df[-train_index, ]

vars_modelo <- c(
  "price",
  "reviews_per_month",
  "latitude",
  "longitude",
  "availability_365"
)

train <- train %>%
  dplyr::filter(if_all(all_of(vars_modelo), ~ !is.na(.)))

test <- test %>%
  dplyr::filter(if_all(all_of(vars_modelo), ~ !is.na(.)))



## Verificar homogenidade de dados de treino e teste
# Histograma de treino
ggplot(train, aes(x = price)) +
  geom_histogram(bins = 30, fill = "orange", color = "black") +
  scale_x_continuous(
    limits = c(0, quantile(train$price, 0.99, na.rm = TRUE))
  ) +
  labs(
    title = "Distribuição da variável Price - Treino",
    x = "Preço",
    y = "Frequência"
  ) +
  theme_minimal()


# Histograma de teste
ggplot(test, aes(x = price)) +
  geom_histogram(bins = 30, fill = "skyblue", color = "black") +
  scale_x_continuous(
    limits = c(0, quantile(test$price, 0.99, na.rm = TRUE))
  ) +
  labs(
    title = "Distribuição da variável Price - Teste",
    x = "Preço",
    y = "Frequência"
  ) +
  theme_minimal()


# Método de reamostragem: Validação Cruzada (com k=5)
ctrl<-trainControl(method="cv",number=5)

# Validação Cruzada (com k=5) e apresentação do melhor modelo criado com 
# os dados do Treino
model_fit <- train(
  price ~ reviews_per_month + latitude + longitude + availability_365,
  data = train,
  method = "lm",
  trControl = ctrl
)

summary(df[, c("price", "reviews_per_month", "latitude", "longitude", "availability_365")])


# Previsões do preço para os dados de treino
pred_train <- predict(model_fit, newdata = train)

# Erros (real - previsto)
error_train <- train$price - pred_train

# Definir métricas de treino
RMSE_train <- sqrt(mean(error_train^2))
MSE_train  <- mean(error_train^2)
MAE_train  <- mean(abs(Ferror_train))

# Coeficiente de Determinação R^2 (com os dados de treino)
R_Square_train <- 1 - (sum(error_train^2) /
                         sum((train$price - mean(train$price))^2))

# Executar as métricas de treino
RMSE_train
MSE_train
MAE_train
R_Square_train


# Previsões do preço para os dados de teste
estimativas <- predict(model_fit, newdata = test)

# Tabela com valores reais vs previstos
tabela <- data.frame(
  VReais     = test$price,
  VPrevistos = estimativas
)

# Erros (real - previsto)
tabela$error <- with(tabela, VReais - VPrevistos)


# Métricas de teste
MSE_teste  <- with(tabela, mean(error^2))
RMSE_teste <- sqrt(MSE_teste)
MAE_teste  <- with(tabela, mean(abs(error)))
R2_teste <- 1 - (sum((tabela$VReais - tabela$VPrevistos)^2) / sum((tabela$VReais - mean(tabela$VReais))^2))


MSE_teste
RMSE_teste
MAE_teste
R2_teste

# Verificar que nenhum dos 3 apresenta relação linear
plot(
  x = df$reviews_per_month,
  y = df$price,
  main = "Preço vs Número de Reviews",
  xlab = "Número de reviews",
  ylab = "Preço"
)

plot(
  x = df$latitude,
  y = df$price,
  main = "Preço vs Latitude",
  xlab = "Latitude",
  ylab = "Preço"
)

plot(
  x = df$longitude,
  y = df$price,
  main = "Preço vs Longitude",
  xlab = "Longitude",
  ylab = "Preço"
)

plot(
  x = df$availability_365,
  y = df$price,
  main = "Preço vs availability",
  xlab = "Availability",
  ylab = "Preço"
)


# Criação do Modelo e Equação (Output Visível)

modelo_linear <- lm(price ~ reviews_per_month + latitude + longitude + availability_365, data=train)

# RESUMO ESTATÍSTICO DO MODELO (Summary) - rejeitamos a hipotese nula porque p-value bem abaixo de 0.01, todos os B^ são # diferentes de 0
print(summary(modelo_linear))

# IMPRIMIR A EQUAÇÃO linear do nosso modelo, vemos novamente todos os betas diferentes de 0
coefs <- coef(modelo_linear)
b0 <- coefs[1]; b1 <- coefs[2]; b2 <- coefs[3]; b3 <- coefs[4]; b4 <- coefs[5]

cat(sprintf("Preço = %.4f \n      + (%.4f * Reviews) \n      + (%.4f * Latitude) \n      + (%.4f * Longitude)\n  +  (%.4f * availability)\n", 
            b0, b1, b2, b3, b4))


# Testes Práticos da Equação

# Escolher a primeira linha do teste para validar e vermos um exemplo
exemplo <- test[1, ]
valor_real <- exemplo$price

# Cálculo manual usando os coeficientes
previsao_manual <- b0 + (b1 * exemplo$reviews_per_month) + (b2 * exemplo$latitude) + (b3 * exemplo$longitude) + (b4 * exemplo$availability_365)
erro_manual <- valor_real - previsao_manual

print(paste("--> Dados usados: Reviews:", exemplo$number_of_reviews, "| Lat:", exemplo$latitude))
print(paste("--> Valor Real da Casa:   ", round(valor_real, 2)))
print(paste("--> Valor Previsto (Eq.): ", round(previsao_manual, 2)))
print(paste("--> Diferença (Erro):     ", round(erro_manual, 2)))



# TABELA COMPARATIVA (TOP 5)
head_test <- head(test, 5)
preds <- predict(modelo_linear, head_test)

comparacao <- data.frame(
  Real = head_test$price,
  Previsto = round(preds, 2),
  Erro = round(head_test$price - preds, 2)
)
print(comparacao)


# Métricas de Erro  do modelo
estimativas <- predict(modelo_linear, test)
residuos <- test$price - estimativas

# Cálculos e Impressão Imediata
MSE_test <- mean(residuos^2)
cat("MSE (Mean Squared Error): ", MSE_test, "\n")

RMSE_test <- sqrt(MSE_test)
cat("RMSE (Erro Médio, mesma unidade do preço): ", RMSE_test, "\n")

MAE_test <- mean(abs(residuos))
cat("MAE (Erro Absoluto Médio): ", MAE_test, "\n")

R2_test <- 1 - (sum(residuos^2) / sum((test$price - mean(test$price))^2))
cat("R² (Qualidade do ajuste 0-1): ", R2_test, "\n")


# Análise de Resíduos e Hipóteses
# Gera os gráficos na janela de plots
par(mfrow=c(1,2)) 
plot(modelo_linear, which=1, main="1. Homocedasticidade")
plot(modelo_linear, which=2, main="2. Normalidade (Q-Q)")
par(mfrow=c(1,1))


# TESTE DE HIPÓTESES (BREUSCH-PAGAN)
cat("H0: Variância constante (Homocedasticidade) -> O que queremos.\n")
cat("H1: Variância muda (Heterocedasticidade) -> Problema.\n")
cat("Se p-value < 0.05, temos Heterocedasticidade.\n\n")

teste_bp <- bptest(modelo_linear)
print(teste_bp)


# coliniariedadeF e Correlação
print(vif(modelo_linear))

# Gráfico Heatmap
matriz_cor <- round(cor(train[, c("price","reviews_per_month", "latitude", "longitude", "availability_365")]), 3)
melted_cor <- melt(matriz_cor)

grafico_correlacao <- ggplot(data = melted_cor, aes(x = Var1, y = Var2, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, limit = c(-1, 1), name="Correlation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
  geom_text(aes(label=round(value,2)), color="black", size=3) +
  ggtitle("Mapa de Correlação")

print(grafico_correlacao)


# ÁRVORE DE DECISÃO SIMPLES

# Criar o Modelo (Algoritmo CART)
# method="anova" é OBRIGATÓRIO para problemas de Regressão (prever preço)
# minsplit=20: O nó tem de ter 20 casas para dividir (evita árvores gigantes)
modelo_tree <- rpart(formula = price ~ reviews_per_month + latitude + longitude + availability_365,
                     data = train,
                     method = "anova",
                     control = rpart.control(minsplit = 20, cp = 0.005))

# Desenhar a Árvore (O GRÁFICO PARA O TEU RELATÓRIO)
rpart.plot(modelo_tree, 
           type = 3, 
           digits = 3, 
           fallen.leaves = TRUE, 
           box.palette = "RdBu",
           main = "Árvore de Decisão: Regras de Preço Airbnb")

# Avaliar a Performance da Árvore Simples
pred_tree <- predict(modelo_tree, test)
rmse_tree <- RMSE(pred_tree, test$price)
r2_tree <- R2(pred_tree, test$price)

cat("Resultados da Árvore Simples:\n")
cat("RMSE (Erro Médio):", round(rmse_tree, 2), "€\n")
cat("R² (Explicação):  ", round(r2_tree, 4)*100, "%\n")



# RANDOM FOREST OTIMIZADO

# Configurar a Validação Cruzada (Cross-Validation)
# O modelo vai treinar 5 vezes em fatias diferentes para garantir robustez.
cv.control <- trainControl(method = "cv", 
                           number = 5, 
                           savePredictions = "final")

# Grelha de Ajustamento (Hyperparameter Tuning)
tune_grid <- expand.grid(mtry = c(2, 3), 
                         splitrule = "variance", 
                         min.node.size = c(5, 10, 20))



# Treinar o Modelo (Usando 'ranger' via 'caret')
modelo_rf_otimizado <- train(price ~ reviews_per_month + latitude + longitude + availability_365,
                             data = train,
                             method = "ranger",
                             metric = "RMSE",       # O objetivo é minimizar o erro
                             num.trees = 500,       # 500 árvores (standard)
                             tuneGrid = tune_grid,
                             importance = "impurity", # Para vermos qual variável manda mais
                             trControl = cv.control)


# Ver qual foi a melhor configuração escolhida pelo computador
print(modelo_rf_otimizado)




# AVALIAÇÃO FINAL E COMPARAÇÃO


#  Previsões Finais com o Modelo Otimizado
pred_rf <- predict(modelo_rf_otimizado, test)

# Calcular Erros
rmse_rf <- RMSE(pred_rf, test$price)
mae_rf <- MAE(pred_rf, test$price)
r2_rf <- R2(pred_rf, test$price)

# RESULTADOS FINAIS (RANDOM FOREST)
cat("RMSE (Erro Médio):    ", round(rmse_rf, 2), "€\n")
cat("MAE (Erro Absoluto):  ", round(mae_rf, 2), "€\n")
cat("R² (Explicação):      ", round(r2_rf, 4)*100, "%\n")

# Gráfico: Previstos vs Reais (Como no exemplo da prof)
# Se os pontos seguirem a linha vermelha, o modelo está ótimo.
plot(test$price, pred_rf,
     main = "Random Forest: Previstos vs Reais",
     xlab = "Preço Real",
     ylab = "Preço Previsto",
     pch = 19, col = rgb(0,0,1,0.5)) # Azul transparente
abline(0, 1, col = "red", lwd = 2)

# Importância das Variáveis
# Qual variável influencia mais o preço?
plot(varImp(modelo_rf_otimizado), main = "Importância das Variáveis (Random Forest)")

# Comparação Final (Para a Conclusão do Relatório)
melhoria <- rmse_tree - rmse_rf
cat("\n--- CONCLUSÃO ---\n")
if(melhoria > 0) {
  cat("O Random Forest melhorou o erro em", round(melhoria, 2), "€ face à árvore simples.\n")
  cat("Isto justifica o uso deste método mais complexo.\n")
} else {
  cat("O Random Forest não melhorou significativamente o modelo simples.\n")
}


# -------------------- Modelo Bagging --------------------

# Criação de um modelo com o método Bagging (considerando 50 árvores: nbagg=50)
cv.control<-trainControl(method="cv",number=5,savePredictions="final")
model_bag<-train(price ~ reviews_per_month + latitude + longitude + availability_365,data=train,method="treebag",nbagg=50,metric="RMSE",tuneLength=5,trControl=cv.control)
model_bag

# Teste ao Modelo criado (model_bag) com base nos dados não vistos do conjunto teste (test)
#
# Cálculo das previsões recorrendo ao modelo criado (model_bag)
model_bag_previsao<-predict(model_bag,test)
plot(test$price,model_bag_previsao,main="Modelo obtido com o Método Bagging: Previstos vs Reais",xlab="Preço Real",ylab="Preço Previsto")
abline(0,1)

# Cálculo do RMSE
model_bag_rmse<-RMSE(pred=model_bag_previsao,obs=test$price)
model_bag_rmse

# Cálculo do MAE
model_bag_mae<-MAE(pred=model_bag_previsao,obs=test$price)
model_bag_mae

# Cálculo do R^2
model_bag_r2 <- R2(pred=model_bag_previsao, obs= test$price)
model_bag_r2

#Importância das variáveis
plot(varImp(model_bag),main="Importância das Variáveis para o modelo obtido com o método Bagging")


# -------------------- Modelo Boosting --------------------~


# Configuração da Validação Cruzada
cv.control <- trainControl(method = "cv", number = 5, savePredictions = "final")

#GBM com ajustamento de parâmetros

tune_gbm<-expand.grid(interaction.depth = c(3,5), n.trees = c(1000,2000,3000),shrinkage = 0.01 ,n.minobsinnode = 10)


# Treino do Modelo
model_boosting_tune<-train(price ~ reviews_per_month + latitude + longitude + availability_365,data=train,method="gbm",tuneGrid=tune_gbm,trControl=cv.control, metric = "RMSE", verbose = FALSE)
model_boosting_tune

# Teste ao Modelo criado (model_boosting_tune) com base nos dados não vistos do conjunto test (test)

# Cálculo das previsões recorrendo ao modelo criado (model_boosting)

model_boosting_tune_previsao<-predict(model_boosting_tune,test)
#Gráfico
plot(test$price,model_boosting_tune_previsao,main="GBM Otimizado: Previstos vs Reais",xlab="Preço Real",ylab="Preço Previsto")
abline(0,1)

# Cálculo do RMSE
(model_boosting_tune_rmse<-RMSE(pred=model_boosting_tune_previsao,obs=test$price))

# Cálculo do MAE
(model_boosting_tune_mae<-MAE(pred=model_boosting_tune_previsao,obs=test$price))

# Cálculo R^2
r2_gbm <- R2(pred = model_boosting_tune_previsao, obs = test$price)
cat("R²", round(r2_gbm, 4) * 100, "%\n")

#Importância das variáveis
varImp(model_boosting_tune)
plot(varImp(model_boosting_tune),main="Importância das Variáveis para o modelo GBM com Ajustamento")






















# ===============================
# MÉTRICAS DE ERRO – COMPARAÇÃO FINAL
# ===============================

# Regressão Linear
pred_lm <- predict(model_fit, test)
rmse_lm <- RMSE(pred_lm, test$price)
mae_lm  <- MAE(pred_lm, test$price)
r2_lm   <- R2(pred_lm, test$price)

# Árvore de Decisão
pred_tree <- predict(modelo_tree, test)
rmse_tree <- RMSE(pred_tree, test$price)
mae_tree  <- MAE(pred_tree, test$price)
r2_tree   <- R2(pred_tree, test$price)

# Bagging
pred_bag <- predict(model_bag, test)
rmse_bag <- RMSE(pred_bag, test$price)
mae_bag  <- MAE(pred_bag, test$price)
r2_bag   <- R2(pred_bag, test$price)

# Random Forest
pred_rf <- predict(modelo_rf_otimizado, test)
rmse_rf <- RMSE(pred_rf, test$price)
mae_rf  <- MAE(pred_rf, test$price)
r2_rf   <- R2(pred_rf, test$price)

# Boosting (GBM)
pred_gbm <- predict(model_boosting_tune, test)
rmse_gbm <- RMSE(pred_gbm, test$price)
mae_gbm  <- MAE(pred_gbm, test$price)
r2_gbm   <- R2(pred_gbm, test$price)

# ===============================
# TABELA FINAL DE RESULTADOS
# ===============================

resultados_finais <- data.frame(
  Modelo = c("Regressão Linear", "Árvore", "Bagging", "Random Forest", "Boosting (GBM)"),
  RMSE   = round(c(rmse_lm, rmse_tree, rmse_bag, rmse_rf, rmse_gbm), 2),
  MAE    = round(c(mae_lm, mae_tree, mae_bag, mae_rf, mae_gbm), 2),
  R2     = round(c(r2_lm, r2_tree, r2_bag, r2_rf, r2_gbm), 4)
)

print(resultados_finais)
