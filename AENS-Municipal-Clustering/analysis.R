#install.packages("mclust")

library(tidyverse)
library(psych)
library(stringr)
library(corrplot)
library(psych)
library(openxlsx)




ler_ficheiro_ine <- function(f) {
  # Ler linhas do ficheiro
  linhas <- readLines(f, encoding = "Latin1")
  
  # 1) Tentar encontrar a linha do cabeçalho
  header_line <- grep("Localização geográfica", linhas)[1]
  
  if (is.na(header_line)) {
    header_line <- grep("Localização", linhas)[1]
  }
  if (is.na(header_line)) {
    header_line <- grep("Período", linhas)[1]
  }
  if (is.na(header_line)) {
    # último recurso: primeira linha que tenha ";"
    header_line <- grep(";", linhas)[1]
  }
  if (is.na(header_line)) {
    stop("Não encontrei cabeçalho no ficheiro: ", f)
  }
  
  skip_n <- header_line - 1
  
  # 2) Ler tabela a partir do cabeçalho
  dados <- read.csv(
    f,
    sep = ";",
    header = TRUE,
    skip = skip_n,
    fileEncoding = "Latin1",
    na.strings = c("", "-", "..", "…", "? ?"),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fill = TRUE
  )
  
  # Remover colunas totalmente vazias
  dados <- dados[, colSums(!is.na(dados)) > 0, drop = FALSE]
  
  # 3) Coluna dos municípios: aquela onde aparecem códigos "1111601:"
  col_mun <- which(sapply(dados, function(x) any(grepl("^[0-9]{7}: ", x))))
  if (length(col_mun) == 0) {
    stop("Não encontrei coluna de municípios no ficheiro: ", f)
  }
  col_mun <- col_mun[1]  # se houver mais de uma, fica a primeira
  
  # 4) Coluna do valor: última coluna com números
  col_val <- which(sapply(dados, function(x) sum(grepl("[0-9]", x)) > 0))
  col_val <- max(col_val)
  
  out <- dados[, c(col_mun, col_val), drop = FALSE]
  names(out) <- c("municipio", "valor")
  
  # Manter só linhas de municípios
  out <- out[grepl("^[0-9]{7}: ", out$municipio), ]
  
  # Limpar valor
  out$valor <- gsub("\\s", "", out$valor)          # remove espaços
  out$valor <- gsub("[^0-9,.-]", "", out$valor)    # remove ? e outros símbolos
  out$valor <- gsub(",", ".", out$valor)           # vírgula → ponto
  out$valor <- as.numeric(out$valor)
  
  # Nome da variável = nome do ficheiro
  varname <- tools::file_path_sans_ext(basename(f))
  varname <- gsub("[^A-Za-z0-9]", "_", varname)
  names(out)[2] <- varname
  
  return(out)
}


# Caminho da pasta
pasta <- "variaveis input"

# Lista de ficheiros .csv nessa pasta
ficheiros <- list.files(pasta, pattern = "\\.csv$", full.names = TRUE)

# Ler e limpar todos
lista_dados <- lapply(ficheiros, ler_ficheiro_ine)

# Juntar tudo por município
base_final <- Reduce(function(x, y) merge(x, y, by = "municipio", all = TRUE),
                     lista_dados)

base_final$municipio <- sub("^[0-9]{7}:\\s*", "", base_final$municipio)

# Mantém a coluna de identificação
novos_nomes <- names(base_final)
novos_nomes[1] <- "municipio"


# Espreitar o resultado
head(base_final)
dim(base_final)  # número de municípios x número de variáveis


# Guardar nomes dos municípios (para referência futura)
municipios <- base_final$municipio

# Seleccionar apenas as variáveis numéricas
dados_pca <- base_final[, -1]

# imputação por mediana, variável a variável - Tratamento de Missings
dados_imputados <- dados_pca
for (j in 1:ncol(dados_imputados)) {
  missing <- is.na(dados_imputados[, j])
  if (any(missing)) {
    dados_imputados[missing, j] <- median(dados_imputados[, j], na.rm = TRUE)
  }
}


#Sumario
summary(dados_imputados)

round(var(dados_imputados),2)

# filtragem de variáveis constantes
variancias <- apply(dados_imputados, 2, var, na.rm = TRUE)
col_validas <- which(!is.na(variancias) & variancias > 0)
dados_filtrados <- dados_imputados[, col_validas]

#### Fim de Processo de ETL

# Resumo estatístico e matriz de covariâncias
summary(dados_filtrados)              # mínimos, quartis, médios, máximos, etc.
matriz_cov <- var(dados_filtrados)    # covariâncias entre indicadores
print(round(matriz_cov, 2))          

### Calculo KMO

# Scatterplot matrix para visualizar relações entre todas as variáveis - vai exportar uma imagem
png("scatter_matrix_completa.png",
    width = 6000, height = 6000, res = 300)

pairs(dados_filtrados,
      pch = 16,
      cex = 0.25,              # pontos pequenos
      lower.panel = NULL,
      main = "Scatterplot matrix – todas as variáveis")

dev.off()


# Criação de correlações
correlacoes <- cor(dados_filtrados)


# Heatmap com corrplot - vai exportar uma imagem
png("heatmap_correlacoes.png", width = 4000, height = 4000, res = 300)
par(mar = c(6, 6, 6, 6))  # margens internas maiores
corrplot(
  correlacoes,
  method = "ellipse",      # ou "color"
  type = "upper",
  order = "hclust",
  tl.cex = 0.8,            # nomes das variáveis
  number.cex = 0.5,        # ← números MAIS PEQUENOS
  addCoef.col = "black"
)
dev.off()


#Bartlett test and KMO
#Input is the correlation matrix
cortest.bartlett(correlacoes)
KMO(correlacoes)


# Dataset base (com município + variáveis)
dataset <- data.frame(municipio = municipios, dados_filtrados, check.names = FALSE)

# Escalar (standardizar) as variáveis numéricas (como no exemplo)
dataZ <- scale(dataset[, -1])  # excluindo a coluna 'municipio'

# Número de variáveis (D)
D <- ncol(dataZ)

# Extração com D componentes (sem rotação, com scores) – equivalente ao pc10
pcD <- principal(dataZ, nfactors = D, rotate = "none", scores = TRUE)

# aplicar critério de Kaiser
# Valores próprios (eigenvalues)
cat("\n=== Eigenvalues (valores próprios) ===\n")
print(round(pcD$values, 3))

# ver a variância explicada
# Loadings (vetores próprios / pesos das variáveis nas PCs)
cat("\n=== Loadings (vetores próprios) ===\n")
print(pcD$loadings)

# Screeplot (cotovelo)
plot(pcD$values, type = "b",
     main = "Scree plot (Municípios)",
     xlab = "Número de Componentes (PC)",
     ylab = "Eigenvalue (valor próprio)")
abline(h = 1, col = "red", lty = 2)  

# Communalities (na PCA “pura”, tendem a ~1 quando usas todas as PCs)
cat("\n=== Communalities ===\n")
print(round(pcD$communality, 3))

# PC4 com e sem rotação
# --- Solução 4 PCs sem rotação
pc4 <- principal(dataZ, nfactors = 4, rotate = "none", scores = TRUE)

cat("\n=== Solução 4 PCs (sem rotação) ===\n")

cat("\nLoadings 4 PCs (sem rotação):\n")
print(pc4$loadings)

cat("\nCommunalities (4 PCs):\n")
print(round(pc4$communality, 2))


# --- Solução 4 PCs com rotação varimax
pc4r <- principal(dataZ, nfactors = 4, rotate = "varimax", scores = TRUE)

cat("\n=== Solução 4 PCs (varimax) ===\n")

cat("\nLoadings 4 PCs (varimax):\n")
print(pc4r$loadings)

cat("\nCommunalities (4 PCs varimax):\n")
print(round(pc4r$communality, 2))


# --- Remover variáveis com MSA baixo ou indesejadas ---
# Criar um novo objeto sem as duas variáveis específicas
colnames(dados_filtrados)
dados_reduzidos <- dados_filtrados %>% 
  select(-Dissolucao_PC_EE, -Taxa_de_credito_a_habitacao)

# Verificar se foram removidas (confirmar o novo número de colunas)
dim(dados_reduzidos)
names(dados_reduzidos)






# Aplicação do Novo DataSet
### Calculo KMO

# Scatterplot matrix para visualizar relações entre todas as variáveis - vai exportar uma imagem
png("scatter_matrix_completa.png",
    width = 6000, height = 6000, res = 300)

# ALTERAÇÃO AQUI: dados_filtrados -> dados_reduzidos
pairs(dados_reduzidos,
      pch = 16,
      cex = 0.25,              # pontos pequenos
      lower.panel = NULL,
      main = "Scatterplot matrix – todas as variáveis")

dev.off()


# Criação de correlações
# ALTERAÇÃO AQUI: dados_filtrados -> dados_reduzidos
correlacoes <- cor(dados_reduzidos)


# Heatmap com corrplot - vai exportar uma imagem
png("heatmap_correlacoes.png", width = 4000, height = 4000, res = 300)
par(mar = c(6, 6, 6, 6))  # margens internas maiores
corrplot(
  correlacoes,
  method = "ellipse",      # ou "color"
  type = "upper",
  order = "hclust",
  tl.cex = 0.8,            # nomes das variáveis
  number.cex = 0.5,        # ← números MAIS PEQUENOS
  addCoef.col = "black"
)
dev.off()


#Bartlett test and KMO
#Input is the correlation matrix
cortest.bartlett(correlacoes)
KMO(correlacoes)


# Dataset base (com município + variáveis)
# ALTERAÇÃO AQUI: dados_filtrados -> dados_reduzidos
dataset <- data.frame(municipio = municipios, dados_reduzidos, check.names = FALSE)

# Escalar (standardizar) as variáveis numéricas (como no exemplo)
dataZ <- scale(dataset[, -1])  # exclui 'municipio'

# Número de variáveis (D)
D <- ncol(dataZ)

# Extração com D componentes (sem rotação, com scores) – equivalente ao pc10
pcD <- principal(dataZ, nfactors = D, rotate = "none", scores = TRUE)

# aplicar critério de Kaiser
# Valores próprios (eigenvalues)
cat("\n=== Eigenvalues (valores próprios) ===\n")
print(round(pcD$values, 3))

# ver a variância explicada
# Loadings (vetores próprios / pesos das variáveis nas PCs)
cat("\n=== Loadings (vetores próprios) ===\n")
print(pcD$loadings)

# Screeplot (cotovelo)
plot(pcD$values, type = "b",
     main = "Scree plot (Municípios)",
     xlab = "Número de Componentes (PC)",
     ylab = "Eigenvalue (valor próprio)")
abline(h = 1, col = "red", lty = 2)  

# Communalities (na PCA “pura”, tendem a ~1 quando usas todas as PCs)
cat("\n=== Communalities ===\n")
print(round(pcD$communality, 3))

# PC4 com e sem rotação
# --- Solução 4 PCs sem rotação
pc4 <- principal(dataZ, nfactors = 4, rotate = "none", scores = TRUE)

cat("\n=== Solução 4 PCs (sem rotação) ===\n")

cat("\nLoadings 4 PCs (sem rotação):\n")
print(pc4$loadings)

cat("\nCommunalities (4 PCs):\n")
print(round(pc4$communality, 2))



# --- Solução 4 PCs com rotação varimax
pc4r <- principal(dataZ, nfactors = 4, rotate = "varimax", scores = TRUE)

cat("\n=== Solução 4 PCs (varimax) ===\n")

cat("\nLoadings 4 PCs (varimax):\n")
print(pc4r$loadings)

cat("\nCommunalities (4 PCs varimax):\n")
print(round(pc4r$communality, 2))


# PC3 com e sem rotação

# --- Solução 3 PCs sem rotação
pc3 <- principal(dataZ, nfactors = 3, rotate = "none", scores = TRUE)

cat("\n=== Solução 3 PCs (sem rotação) ===\n")

cat("\nLoadings 3 PCs (sem rotação):\n")
print(pc3$loadings) # Sem cutoff e sem sort

cat("\nCommunalities (3 PCs):\n")
print(round(pc3$communality, 2))


# --- Solução 3 PCs com rotação varimax
pc3r <- principal(dataZ, nfactors = 3, rotate = "varimax", scores = TRUE)

cat("\n=== Solução 3 PCs (varimax) ===\n")

cat("\nLoadings 3 PCs (varimax):\n")
print(pc3r$loadings) # Sem cutoff e sem sort

cat("\nCommunalities (3 PCs varimax):\n")
print(round(pc3r$communality, 2))


#Guardar os scores
pc4sc <- principal(dataZ, nfactors=4, rotate="none", scores=TRUE)  

round(pc4sc$scores,4)

mean(pc4sc$scores[,1])

sd(pc4sc$scores[,1])

#Add scores to the data set as new variables

dataset$Empresas <- pc4sc$scores[,1]

dataset$Subsidios <- pc4sc$scores[,2]

dataset$Trabalhadores <- pc4sc$scores[,3]

dataset$Rendimento_Habitacao <- pc4sc$scores[,4]


# Guardar os dados num ficheiro excel
write.xlsx(dataset, file = "Componentes.xlsx", sheetName = "PCAdesemprego", 
           
           colnames = TRUE, rownames = TRUE, append = FALSE)



# Usar apenas scores das PCs
dados_cluster <- dataset %>%
  dplyr::select(Empresas, Subsidios, Trabalhadores, Rendimento_Habitacao)

# (Recomendado) Standardizar antes do clustering (PCs já são scores, mas ajuda)
dados_cluster <- as.data.frame(scale(dados_cluster))


# Matriz de distâncias (serve para Ward e silhouette)
dist_mat <- dist(dados_cluster, method = "euclidean")

################################################################################
# Método Hierárquico (Ward, K = 3)
################################################################################

# Clustering Hierárquico – Ward
hc_ward <- hclust(dist_mat, method = "ward.D2")

# Dendrograma
plot(hc_ward,
     labels = FALSE,
     hang = -1,
     main = "Dendrograma – Método de Ward (scores PCs)")

# Cortar em K = 3
rect.hclust(hc_ward, k = 3, border = "red")

# Guardar clusters hierárquicos
dataset$cluster_hier <- factor(cutree(hc_ward, k = 3))

# Visualização PC1 vs PC2 (Empresas vs Subsidios)
plot(dataset$Empresas, dataset$Subsidios,
     col = dataset$cluster_hier,
     pch = 19,
     xlab = "PC1 – Empresas",
     ylab = "PC2 – Subsídios",
     main = "Clustering Hierárquico (Ward, K = 3)")

legend("topright",
       legend = levels(dataset$cluster_hier),
       col = 1:3,
       pch = 19,
       cex = 0.9)

################################################################################
# Método de Partição (K-means, K = 3)
################################################################################

# Método do cotovelo (WSS) — para justificar K
wss <- sapply(1:10, function(k) {
  kmeans(dados_cluster, centers = k, nstart = 50)$tot.withinss
})

plot(1:10, wss, type = "b",
     xlab = "Número de clusters (K)",
     ylab = "Within-cluster sum of squares (WSS)",
     main = "Método do Cotovelo – K-means")

# Ajuste do K-means (K = 3)
set.seed(123)
km3 <- kmeans(dados_cluster, centers = 3, nstart = 100)

dataset$cluster_km <- factor(km3$cluster)

# Visualização PC1 vs PC2
plot(dataset$Empresas, dataset$Subsidios,
     col = dataset$cluster_km,
     pch = 19,
     xlab = "PC1 – Empresas",
     ylab = "PC2 – Subsídios",
     main = "K-means (K = 3)")

legend("topright",
       legend = levels(dataset$cluster_km),
       col = 1:3,
       pch = 19,
       cex = 0.9)

# Validação — Silhouette (K-means)
sil_km <- silhouette(km3$cluster, dist_mat)

plot(sil_km,
     main = "Silhouette plot – K-means (K = 3)")

# Média do silhouette (quanto maior melhor)
mean_sil_km <- mean(sil_km[, 3])
print(mean_sil_km)

################################################################################
# Método Probabilístico (GMM — seleciona K por BIC)
################################################################################

# Ajuste do modelo GMM (Mclust escolhe automaticamente o nº de clusters via BIC)
gmm <- Mclust(dados_cluster)

summary(gmm)

# BIC do modelo escolhido e comparação
plot(gmm, what = "BIC")

# Guardar clusters (classificação final)
dataset$cluster_gmm <- factor(gmm$classification)

# Visualização PC1 vs PC2
plot(dataset$Empresas, dataset$Subsidios,
     col = dataset$cluster_gmm,
     pch = 19,
     xlab = "PC1 – Empresas",
     ylab = "PC2 – Subsídios",
     main = "Gaussian Mixture Model (clusters por BIC)")

legend("topright",
       legend = levels(dataset$cluster_gmm),
       col = 1:length(levels(dataset$cluster_gmm)),
       pch = 19,
       cex = 0.8)

# (Opcional) Outras combinações de PCs
plot(dataset$Empresas, dataset$Trabalhadores,
     col = dataset$cluster_gmm,
     pch = 19,
     xlab = "PC1 – Empresa",
     ylab = "PC3 – Trabalhador",
     main = "GMM: PC1 vs PC3")

plot(dataset$Subsidios, dataset$Rendimento_Habitacao,
     col = dataset$cluster_gmm,
     pch = 19,
     xlab = "PC2 – Subsídios",
     ylab = "PC4 – Rendimento_Habitação",
     main = "GMM: PC2 vs PC4")




### Variaveis profile
# Função de leitura
ler_profile_ine <- function(f) {
  
  # --- Ler linhas para detetar cabeçalho
  linhas <- readLines(f, encoding = "Latin1")
  
  # Cabeçalho costuma conter "Localização geográfica" ou "Place of residence"
  header_line <- grep("Localização geográfica", linhas)[1]
  if (is.na(header_line)) header_line <- grep("Localização", linhas)[1]
  if (is.na(header_line)) header_line <- grep("Place of residence", linhas)[1]
  if (is.na(header_line)) header_line <- grep("Período", linhas)[1]
  if (is.na(header_line)) header_line <- grep("Data reference period", linhas)[1]
  if (is.na(header_line)) header_line <- grep(";", linhas)[1]
  
  if (is.na(header_line)) stop("Não encontrei cabeçalho no ficheiro: ", f)
  
  skip_n <- header_line - 1
  
  # --- Ler CSV
  dados <- read.csv(
    f,
    sep = ";",
    header = TRUE,
    skip = skip_n,
    fileEncoding = "Latin1",
    na.strings = c("", "-", "..", "…", "…", "NA", "N/A", "? ?"),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    fill = TRUE
  )
  
  # remover colunas completamente vazias
  dados <- dados[, colSums(!is.na(dados)) > 0, drop = FALSE]
  
  # proteger contra colunas list (às vezes acontece em merges anteriores)
  dados <- as.data.frame(lapply(dados, function(x) {
    if (is.list(x)) sapply(x, function(y) as.character(y)[1]) else x
  }), check.names = FALSE, stringsAsFactors = FALSE)
  
  # --- Identificar coluna de município (7 dígitos + ": ")
  col_mun <- which(sapply(dados, function(x) 
    any(grepl("^[A-Za-z0-9]+:\\s*", as.character(x)))))
  if (length(col_mun) == 0) stop("Não encontrei coluna de municípios no ficheiro: ", f)
  col_mun <- col_mun[1]
  
  # --- Identificar colunas de valor (todas menos a de município)
  # Nota: alguns ficheiros podem ter mais que uma coluna numérica -> somamos (se for o caso)
  valor_cols <- setdiff(seq_len(ncol(dados)), col_mun)
  
  # ficar só com municipio + colunas candidatas a valor
  subdados <- dados[, c(col_mun, valor_cols), drop = FALSE]
  names(subdados)[1] <- "municipio"
  
  # manter só linhas que são municípios
  subdados <- subdados[grepl("^[A-Za-z0-9]+:\\s*", subdados$municipio), ]
  
  # limpar município: remover o código
  subdados$municipio <- sub("^[A-Za-z0-9]+:\\s*", "", subdados$municipio)
  subdados$municipio <- trimws(subdados$municipio)
  
  # transformar colunas de valor em numéricas (limpa símbolos)
  for (j in 2:ncol(subdados)) {
    subdados[[j]] <- as.character(subdados[[j]])
    subdados[[j]] <- gsub("\\s", "", subdados[[j]])
    subdados[[j]] <- gsub("[^0-9,.-]", "", subdados[[j]])  # remove letras, ?, etc.
    subdados[[j]] <- gsub(",", ".", subdados[[j]])
    suppressWarnings(subdados[[j]] <- as.numeric(subdados[[j]]))
  }
  
  # --- Criar 1 coluna final de valor:
  # Se houver várias colunas de valor -> soma por linha (ex: meses / várias medidas)
  if (ncol(subdados) > 2) {
    subdados$valor <- rowSums(subdados[, 2:ncol(subdados)], na.rm = TRUE)
  } else {
    subdados$valor <- subdados[[2]]
  }
  
  subdados <- subdados[, c("municipio", "valor"), drop = FALSE]
  
  # --- Se o ficheiro tiver múltiplas linhas por município (por sexo/grupo etário/etc.)
  # agregamos para 1 valor por município (média; podes trocar por sum se fizer sentido)
  subdados <- subdados %>%
    group_by(municipio) %>%
    summarise(valor = mean(valor, na.rm = TRUE), .groups = "drop")
  
  # --- Nome da variável (nome do ficheiro)
  varname <- tools::file_path_sans_ext(basename(f))
  varname <- gsub("[^A-Za-z0-9]", "_", varname)
  names(subdados)[2] <- varname
  
  return(subdados)
}


# LER OS CSVs DE PROFILE (PASTA)
pasta_profile <- "variaveis profile"

ficheiros_profile <- list.files(
  pasta_profile,
  pattern = "\\.csv$",
  full.names = TRUE
)

# Ler todos
lista_profile <- lapply(ficheiros_profile, ler_profile_ine)


# JUNTAR PROFILE NUMA TABELA ÚNICA
profile_final <- Reduce(function(x, y) merge(x, y, by = "municipio", all = TRUE),
                        lista_profile)

# Garantir 1 linha por município (proteção extra contra duplicados)
profile_final <- profile_final %>%
  group_by(municipio) %>%
  summarise(across(where(is.numeric), ~mean(.x, na.rm = TRUE)), .groups = "drop")

dim(profile_final)
head(profile_final)

# FAZER JOIN COM O DATASET FINAL (COM CLUSTERS)

dataset$municipio <- trimws(as.character(dataset$municipio))
profile_final$municipio <- trimws(as.character(profile_final$municipio))

dataset_prof <- dataset %>%
  left_join(profile_final, by = "municipio")

dim(dataset_prof)

################################################################################
# PERFIL DOS CLUSTERS
################################################################################
# (Segurança) garantir que municipio é character e sem espaços
dataset$municipio <- trimws(as.character(dataset$municipio))
# Se profile_final existir, normaliza também:
# profile_final$municipio <- trimws(as.character(profile_final$municipio))

# Juntar profiles ao dataset com clusters
# (Se der many-to-many, é porque existe município repetido num dos lados)
dataset_prof <- dataset %>%
  left_join(profile_final, by = "municipio")

# Verificação rápida
print(dim(dataset_prof))
print(head(dataset_prof[, 1:min(10, ncol(dataset_prof))]))

# --- Profiling (médias) por cluster ---
# Escolher qual cluster usar como "principal" no relatório
# cluster_hier (K=3), cluster_km (K=3), cluster_gmm (BIC)

# Exemplo: perfil por K-means
perfil_km <- dataset_prof %>%
  group_by(cluster_km) %>%
  summarise(
    across(
      c(
        Crescimento_Efetivo,
        Dependencia_de_Jovens,
        Envelhecimento,
        Indice_dependencia,
        Mudanca_de_Populacao,
        Populacao_Estrangeira,
        Populacao_Residente
      ),
      ~ mean(.x, na.rm = TRUE)
    ),
    n = n()
  )

print(perfil_km, width = Inf)

# Exemplo: perfil por Ward
perfil_hier <- dataset_prof %>%
  group_by(cluster_hier) %>%
  summarise(
    across( c(
      Crescimento_Efetivo,
      Dependencia_de_Jovens,
      Envelhecimento,
      Indice_dependencia,
      Mudanca_de_Populacao,
      Populacao_Estrangeira,
      Populacao_Residente
    ), ~mean(.x, na.rm = TRUE)),
    n = n()
  )

print(perfil_hier, width = Inf)

# Exemplo: perfil por GMM
perfil_gmm <- dataset_prof %>%
  group_by(cluster_gmm) %>%
  summarise(
    across( c(
      Crescimento_Efetivo,
      Dependencia_de_Jovens,
      Envelhecimento,
      Indice_dependencia,
      Mudanca_de_Populacao,
      Populacao_Estrangeira,
      Populacao_Residente
    ), ~mean(.x, na.rm = TRUE)),
    n = n()
  )

print(perfil_gmm, width = Inf)

