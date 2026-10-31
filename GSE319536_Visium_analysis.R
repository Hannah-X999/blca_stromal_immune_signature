library(Seurat)
library(ggplot2)
library(patchwork)
library(data.table)

work_dir <- "/home/uro_han_20250703/Bulk-RNA/TCGA-BLCA/ST"
xenium_dir <- file.path(work_dir, "GSE326226")
out_dir <- file.path(work_dir, "xenium_results")
dir.create(out_dir, showWarnings = FALSE)

cat("==================================================\n")
cat(">>> 1. 正在检索并读取 GSE326226 (Xenium) 数据...\n")

# 寻找 h5 表达矩阵文件 (以 A1R2 或第一个样本为例)
h5_files <- list.files(xenium_dir, pattern = ".*cell_feature_matrix.*h5", full.names = TRUE)
if (length(h5_files) == 0) stop("未找到 Xenium h5 表达矩阵，请检查路径！")

sample_h5 <- h5_files[1]
sample_prefix <- gsub("_cell_feature_matrix.h5", "", basename(sample_h5))
cat("分析样本:", sample_prefix, "\n")

counts <- Read10X_h5(sample_h5)
# 若 counts 为多模态列表，提取 Gene Expression
if (is.list(counts)) counts <- counts[["Gene Expression"]]

seu_x <- CreateSeuratObject(counts = counts, project = "Xenium_BLCA")
seu_x <- NormalizeData(seu_x, normalization.method = "LogNormalize", scale.factor = 10000)

cat("成功加载 Xenium 单细胞！细胞总数:", ncol(seu_x), "基因数:", nrow(seu_x), "\n")

# 寻找细胞坐标文件 (cells.csv.gz 或 cells.csv)
cat(">>> 2. 匹配单细胞物理空间坐标...\n")
cells_files <- list.files(xenium_dir, pattern = paste0(sample_prefix, ".*cells.*csv.*"), full.names = TRUE)
if (length(cells_files) == 0) {
  cells_files <- list.files(xenium_dir, pattern = ".*cells.*csv.*", full.names = TRUE)
}

if (length(cells_files) == 0) stop("未找到 cells.csv 细胞坐标文件！")
coord_file <- cells_files[1]
cat("读取坐标文件:", coord_file, "\n")

# 使用 fread 快速读取大型坐标表
df_coords <- fread(coord_file)

# 寻找细胞 ID 列和坐标列
cell_col <- grep("cell_id|barcode", colnames(df_coords), value = TRUE, ignore.case = TRUE)[1]
x_col <- grep("^x$|x_centroid", colnames(df_coords), value = TRUE, ignore.case = TRUE)[1]
y_col <- grep("^y$|y_centroid", colnames(df_coords), value = TRUE, ignore.case = TRUE)[1]

cat("坐标列匹配:", cell_col, x_col, y_col, "\n")

# 构建坐标数据框并与 Seurat 细胞匹配
coords_sub <- data.frame(
  cell_id = as.character(df_coords[[cell_col]]),
  x = as.numeric(df_coords[[x_col]]),
  y = as.numeric(df_coords[[y_col]])
)

common_cells <- intersect(Cells(seu_x), coords_sub$cell_id)
cat("成功匹配坐标的有效单细胞数:", length(common_cells), "\n")

coords_matched <- coords_sub[match(common_cells, coords_sub$cell_id), ]

# 提取关键基因表达
target_genes <- c("THBS1", "TGFB3", "CD163", "CD68", "CSF1R", "CD14", "FAP", "PDGFRA")
avail_genes <- target_genes[target_genes %in% rownames(seu_x)]
cat("用于单细胞分析的基因:", paste(avail_genes, collapse = ", "), "\n")

expr_mat <- as.matrix(GetAssayData(seu_x, layer = "data")[avail_genes, common_cells])
df_plot <- cbind(coords_matched, as.data.frame(t(expr_mat)))

# 计算单细胞级别的相关性矩阵
cor_xenium <- cor(t(expr_mat), method = "spearman")
cat("\n=== Xenium 单细胞级别 Spearman 相关系数 ===\n")
print(round(cor_xenium, 3))
write.csv(cor_xenium, file.path(out_dir, "Xenium_single_cell_correlation.csv"))

cat("\n>>> 3. 正在生成 Xenium 单细胞原位切片染色图 (Single-cell In Situ Stain)...\n")

# 绘图函数：单细胞真原位空间点阵图 (细胞非常小，点大小取 0.2~0.3)
plot_xenium_stain <- function(df, gene, color_high, title_label) {
  # 截断前 1% 极值增强荧光对比
  q99 <- quantile(df[[gene]][df[[gene]] > 0], 0.99, na.rm = TRUE)
  if(is.na(q99) || q99 == 0) q99 <- max(df[[gene]])
  
  ggplot(df, aes(x = x, y = y, color = pmin(.data[[gene]], q99))) +
    geom_point(size = 0.25, alpha = 0.8) +
    scale_color_gradient(low = "#e5e5e5", high = color_high, name = "Log-expr") +
    labs(title = title_label) +
    theme_void(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5, size = 12, margin = margin(b = 5)),
      legend.position = "right",
      legend.key.height = unit(0.5, "cm"),
      legend.key.width = unit(0.3, "cm")
    ) +
    coord_fixed()
}

# 绘制 4 联图：THBS1、CD163、TGFB3、FAP/PDGFRA
p_thbs1 <- plot_xenium_stain(df_plot, "THBS1", "#b2182b", "THBS1 (In Situ Single-Cell)")
p_cd163 <- plot_xenium_stain(df_plot, "CD163", "#d6604d", "CD163 (M2 Macrophage)")
p_tgfb3 <- plot_xenium_stain(df_plot, "TGFB3", "#2166ac", "TGFB3 (In Situ Single-Cell)")
p_caf   <- plot_xenium_stain(df_plot, "PDGFRA", "#4393c3", "PDGFRA (CAF / Stroma)")

p_xenium_comb <- (p_thbs1 | p_cd163) / (p_tgfb3 | p_caf) +
  plot_annotation(
    theme = theme(plot.margin = margin(10, 10, 10, 10))
  )

out_fig <- file.path(out_dir, "Supplementary_Fig4_Xenium_InSitu_SingleCell.png")
ggsave(out_fig, p_xenium_comb, width = 10, height = 9, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Supplementary_Fig4_Xenium_InSitu_SingleCell.pdf"), p_xenium_comb, width = 10, height = 9, bg = "white")

cat("Xenium 单细胞级空间分析完成！图片已保存至:\n", out_fig, "\n")



library(Seurat)
library(ggplot2)
library(patchwork)
library(data.table)
library(dplyr)
library(viridis)

work_dir <- "/home/uro_han_20250703/Bulk-RNA/TCGA-BLCA/ST"
xenium_dir <- file.path(work_dir, "GSE326226")
out_dir <- file.path(work_dir, "xenium_results")
dir.create(out_dir, showWarnings = FALSE)

cat(">>> 1. 正在检索 GSE326226 所有切片文件...\n")
h5_files <- list.files(xenium_dir, pattern = ".*cell_feature_matrix.*h5", full.names = TRUE)
cat("GSE326226 包含的切片数量:", length(h5_files), "\n")
for (h in h5_files) cat(" -", basename(h), "\n")

# 以第一个切片为例进行高对比度渲染
sample_h5 <- h5_files[1]
sample_prefix <- gsub("_cell_feature_matrix.h5", "", basename(sample_h5))
cat("\n当前精细渲染样本:", sample_prefix, "\n")

counts <- Read10X_h5(sample_h5)
if (is.list(counts)) counts <- counts[["Gene Expression"]]

seu_x <- CreateSeuratObject(counts = counts)
seu_x <- NormalizeData(seu_x, normalization.method = "LogNormalize", scale.factor = 10000, verbose = FALSE)

# 匹配坐标
cells_files <- list.files(xenium_dir, pattern = paste0(sample_prefix, ".*cells.*csv.*"), full.names = TRUE)
if (length(cells_files) == 0) cells_files <- list.files(xenium_dir, pattern = ".*cells.*csv.*", full.names = TRUE)
df_coords <- fread(cells_files[1])

cell_col <- grep("cell_id|barcode", colnames(df_coords), value = TRUE, ignore.case = TRUE)[1]
x_col <- grep("^x$|x_centroid", colnames(df_coords), value = TRUE, ignore.case = TRUE)[1]
y_col <- grep("^y$|y_centroid", colnames(df_coords), value = TRUE, ignore.case = TRUE)[1]

coords_sub <- data.frame(
  cell_id = as.character(df_coords[[cell_col]]),
  x = as.numeric(df_coords[[x_col]]),
  y = as.numeric(df_coords[[y_col]])
)

common_cells <- intersect(Cells(seu_x), coords_sub$cell_id)
coords_matched <- coords_sub[match(common_cells, coords_sub$cell_id), ]

target_genes <- c("THBS1", "TGFB3", "CD163", "PDGFRA")
expr_mat <- as.matrix(GetAssayData(seu_x, layer = "data")[target_genes, common_cells])
df_plot <- cbind(coords_matched, as.data.frame(t(expr_mat)))

cat(">>> 2. 采用顶层高光渲染算法绘制单细胞荧光伪彩图...\n")

# 核心优化绘图函数：
plot_enhanced_xenium <- function(df, gene, color_glow, title_label) {
  # 关键步骤 1: 强制让高表达细胞排在数据框最后，从而在最顶层绘制！
  df_sorted <- df %>% arrange(.data[[gene]])
  
  # 截断极值增强对比
  q98 <- quantile(df_sorted[[gene]][df_sorted[[gene]] > 0], 0.98, na.rm = TRUE)
  if(is.na(q98) || q98 == 0) q98 <- max(df_sorted[[gene]])
  
  # 分离零表达背景与阳性表达点
  df_bg <- df_sorted %>% filter(.data[[gene]] == 0)
  df_pos <- df_sorted %>% filter(.data[[gene]] > 0)
  
  ggplot() +
    # 底层：零表达细胞画成极浅的背景灰色
    geom_point(data = df_bg, aes(x = x, y = y), size = 0.15, alpha = 0.25, color = "#e0e0e0") +
    # 顶层：阳性细胞放大并亮起荧光色
    geom_point(data = df_pos, aes(x = x, y = y, color = pmin(.data[[gene]], q98)), size = 0.7, alpha = 0.9) +
    scale_color_gradient(low = "#ffeda0", high = color_glow, name = "Log-expr") +
    labs(title = title_label) +
    theme_void(base_size = 12) +
    theme(
      plot.title = element_text(face = "bold", hjust = 0.5, size = 13, margin = margin(b = 6)),
      legend.position = "right",
      legend.key.height = unit(0.5, "cm"),
      legend.key.width = unit(0.3, "cm")
    ) +
    coord_fixed()
}

p1 <- plot_enhanced_xenium(df_plot, "THBS1",  "#bd0026", "THBS1 (In Situ Single-Cell)")
p2 <- plot_enhanced_xenium(df_plot, "CD163",  "#d73027", "CD163 (M2 Macrophage)")
p3 <- plot_enhanced_xenium(df_plot, "TGFB3",  "#08519c", "TGFB3 (In Situ Single-Cell)")
p4 <- plot_enhanced_xenium(df_plot, "PDGFRA", "#3182bd", "PDGFRA (CAF / Stroma)")

p_comb <- (p1 | p2) / (p3 | p4) +
  plot_annotation(
    title = paste0("High-Resolution In Situ Single-Cell Landscape (Xenium GSE326226, ", sample_prefix, ")"),
    theme = theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 15, margin = margin(t = 10, b = 10)))
  )

out_fig <- file.path(out_dir, "Supplementary_Fig4_Xenium_InSitu_Enhanced.png")
ggsave(out_fig, p_comb, width = 11, height = 10, dpi = 300, bg = "white")
ggsave(file.path(out_dir, "Supplementary_Fig4_Xenium_InSitu_Enhanced.pdf"), p_comb, width = 11, height = 10, bg = "white")

cat("\n优化版 Xenium 单细胞切片染色图生成完毕！\n保存位置:\n", out_fig, "\n")




library(Seurat)
library(ggplot2)
library(dplyr)
library(tidyr)

work_dir <- "/home/uro_han_20250703/Bulk-RNA/TCGA-BLCA/ST/GSE319536"
out_dir <- "/home/uro_han_20250703/Bulk-RNA/TCGA-BLCA/ST/visium_results"
dir.create(out_dir, showWarnings = FALSE)

# 1. 抓取所有 22 例样本的 h5 文件
h5_files <- list.files(work_dir, pattern = ".*_filtered_feature_bc_matrix.h5$", full.names = TRUE)
cat("共检索到", length(h5_files), "个 Visium 样本切片文件。\n")

summary_list <- list()

for (f in h5_files) {
  sample_name <- gsub(".*_(BC[0-9]+)_.*", "\\1", basename(f))
  cat("正在处理样本:", sample_name, "...")
  
  tryCatch({
    counts <- Read10X_h5(f)
    if (is.list(counts)) counts <- counts[["Gene Expression"]]
    
    # 快速质控：过滤过少 spot 的切片
    if (ncol(counts) < 500) {
      cat(" (Spot 数少于 500，跳过)\n")
      next
    }
    
    # 快速标准化
    seu_tmp <- CreateSeuratObject(counts = counts)
    seu_tmp <- NormalizeData(seu_tmp, normalization.method = "LogNormalize", scale.factor = 10000, verbose = FALSE)
    
    # 提取目标基因
    target_genes <- c("THBS1", "TGFB3", "CD163", "ACTA2", "CD68")
    avail_genes <- target_genes[target_genes %in% rownames(seu_tmp)]
    
    expr_sub <- as.matrix(GetAssayData(seu_tmp, layer = "data")[avail_genes, ])
    
    # 计算该切片内部的 Spearman 相关系数
    r_thbs1_cd163 <- if(all(c("THBS1", "CD163") %in% avail_genes)) cor(expr_sub["THBS1",], expr_sub["CD163",], method = "spearman") else NA
    r_thbs1_acta2 <- if(all(c("THBS1", "ACTA2") %in% avail_genes)) cor(expr_sub["THBS1",], expr_sub["ACTA2",], method = "spearman") else NA
    r_tgfb3_acta2 <- if(all(c("TGFB3", "ACTA2") %in% avail_genes)) cor(expr_sub["TGFB3",], expr_sub["ACTA2",], method = "spearman") else NA
    r_thbs1_cd68  <- if(all(c("THBS1", "CD68")  %in% avail_genes)) cor(expr_sub["THBS1",], expr_sub["CD68",],  method = "spearman") else NA
    
    summary_list[[sample_name]] <- data.frame(
      Sample = sample_name,
      Spots = ncol(seu_tmp),
      THBS1_vs_CD163 = r_thbs1_cd163,
      THBS1_vs_ACTA2 = r_thbs1_acta2,
      TGFB3_vs_ACTA2 = r_tgfb3_acta2,
      THBS1_vs_CD68  = r_thbs1_cd68
    )
    cat(" 完成! (", ncol(seu_tmp), "spots)\n")
  }, error = function(e) {
    cat(" 出错跳过:", e$message, "\n")
  })
}

# 2. 合并 22 例切片的统计量
df_summary <- bind_rows(summary_list)
write.csv(df_summary, file.path(out_dir, "GSE319536_all_samples_correlation_summary.csv"), row.names = FALSE)

cat("\n================ 22 例样本相关系数汇总统计 ================\n")
print(summary(df_summary %>% select(-Sample, -Spots)))

# 3. 绘制 22 例切片的多样本分布箱线/点图
df_long <- df_summary %>%
  select(Sample, THBS1_vs_CD163, THBS1_vs_ACTA2, TGFB3_vs_ACTA2) %>%
  pivot_longer(cols = -Sample, names_to = "Comparison", values_to = "Correlation") %>%
  mutate(Comparison = factor(Comparison, 
                            levels = c("THBS1_vs_CD163", "THBS1_vs_ACTA2", "TGFB3_vs_ACTA2"),
                            labels = c("THBS1 vs. CD163\n(Macrophage)", 
                                       "THBS1 vs. ACTA2\n(Myofibroblast)", 
                                       "TGFB3 vs. ACTA2\n(Myofibroblast)")))

p_box <- ggplot(df_long, aes(x = Comparison, y = Correlation, fill = Comparison)) +
  geom_boxplot(width = 0.45, alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.15, size = 2.5, alpha = 0.8, aes(color = Comparison)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  scale_fill_manual(values = c("#d73027", "#fc8d59", "#4575b4")) +
  scale_color_manual(values = c("#d73027", "#fc8d59", "#4575b4")) +
  labs(title = "Cohort-wide Spatial Co-enrichment Validation (GSE319536, n = 22 patients)",
       x = "", y = "Spot-level Spearman Correlation (rho)") +
  theme_classic(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", hjust = 0.5, size = 14),
    axis.text.x = element_text(face = "bold", size = 12)
  )

ggsave(file.path(out_dir, "Supplementary_Fig3_Cohort_22samples_Boxplot.png"), p_box, width = 7.5, height = 5.5, dpi = 300)
ggsave(file.path(out_dir, "Supplementary_Fig3_Cohort_22samples_Boxplot.pdf"), p_box, width = 7.5, height = 5.5)

cat("\n多样本统计汇总完成！图表保存在:", file.path(out_dir, "Supplementary_Fig3_Cohort_22samples_Boxplot.png"), "\n")



library(ggplot2)
library(dplyr)
library(tidyr)

work_dir <- "/home/uro_han_20250703/Bulk-RNA/TCGA-BLCA/ST"
out_dir <- file.path(work_dir, "GSE319536_Visium_Results")

csv_file <- file.path(out_dir, "GSE319536_all_samples_correlation_summary.csv")
if (!file.exists(csv_file)) {
  csv_file <- file.path(work_dir, "visium_results/GSE319536_all_samples_correlation_summary.csv")
}
df_summary <- read.csv(csv_file)

# 整理数据为长格式
df_long <- df_summary %>%
  select(Sample, THBS1_vs_CD163, THBS1_vs_ACTA2, TGFB3_vs_ACTA2) %>%
  pivot_longer(cols = -Sample, names_to = "Comparison", values_to = "Correlation") %>%
  mutate(Comparison = factor(Comparison, 
                            levels = c("THBS1_vs_CD163", "THBS1_vs_ACTA2", "TGFB3_vs_ACTA2"),
                            labels = c("THBS1 vs. CD163\n(Macrophage)", 
                                       "THBS1 vs. ACTA2\n(Myofibroblast)", 
                                       "TGFB3 vs. ACTA2\n(Myofibroblast)")))

# 计算各组单样本 Wilcoxon 检验 P 值 (vs 0)
pval_df <- data.frame(
  Comparison = levels(df_long$Comparison),
  y_pos = c(0.58, 0.78, 0.35),
  label = c("p < 0.001\n(vs. 0)", "p < 0.001\n(vs. 0)", "p < 0.001\n(vs. 0)")
)

p_box <- ggplot(df_long, aes(x = Comparison, y = Correlation, fill = Comparison)) +
  geom_boxplot(width = 0.45, alpha = 0.7, outlier.shape = NA) +
  geom_jitter(width = 0.15, size = 2.5, alpha = 0.8, aes(color = Comparison)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50", linewidth = 0.8) +
  geom_text(data = pval_df, aes(x = Comparison, y = y_pos, label = label), 
            inherit.aes = FALSE, fontface = "bold", size = 4.2) +
  scale_fill_manual(values = c("#d73027", "#fc8d59", "#4575b4")) +
  scale_color_manual(values = c("#d73027", "#fc8d59", "#4575b4")) +
  labs(title = "Cohort-wide Spatial Co-enrichment Validation (GSE319536, n = 21 patients)",
       x = "", y = "Spot-level Spearman Correlation (rho)") +
  scale_y_continuous(limits = c(-0.05, 0.85), breaks = seq(0, 0.8, by = 0.2)) +
  theme_classic(base_size = 13) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", hjust = 0.5, size = 14),
    axis.text.x = element_text(face = "bold", size = 12),
    axis.title.y = element_text(face = "bold", size = 12)
  )

out_fig <- file.path(out_dir, "Supplementary_Fig3_Cohort_21samples_Boxplot_Pvalue.png")
ggsave(out_fig, p_box, width = 8, height = 5.8, dpi = 300)
ggsave(file.path(out_dir, "Supplementary_Fig3_Cohort_21samples_Boxplot_Pvalue.pdf"), p_box, width = 8, height = 5.8)

cat("\n带 P 值的多样本箱线图生成完成！\n保存至:", out_fig, "\n")



library(Seurat)
library(ggplot2)
library(patchwork)

work_dir <- "/home/uro_han_20250703/Bulk-RNA/TCGA-BLCA/ST"
out_dir <- file.path(work_dir, "GSE319536_Visium_Results")
dir.create(out_dir, showWarnings = FALSE)

# 1. 读取 BC07 表达矩阵
h5_file <- file.path(work_dir, "GSE319536/GSM9519400_BC07_filtered_feature_bc_matrix.h5")
counts <- Read10X_h5(h5_file)
if (is.list(counts)) counts <- counts[["Gene Expression"]]

seu <- CreateSeuratObject(counts = counts)
seu <- NormalizeData(seu, normalization.method = "LogNormalize", scale.factor = 10000, verbose = FALSE)

target_genes <- c("THBS1", "TGFB3", "CD163", "ACTA2")
expr_mat <- as.matrix(GetAssayData(seu, layer = "data")[target_genes, ])
df_expr <- as.data.frame(t(expr_mat))

# 2. 计算精准统计值
r1 <- cor(df_expr$THBS1, df_expr$CD163, method = "spearman")
r2 <- cor(df_expr$THBS1, df_expr$ACTA2, method = "spearman")
r3 <- cor(df_expr$TGFB3, df_expr$ACTA2, method = "spearman")

# 3. 独立绘图（统计值放置于绘图区内部左上角，彻底解决标题截断问题）
p1 <- ggplot(df_expr, aes(x = THBS1, y = CD163)) +
  geom_point(alpha = 0.25, size = 0.8, color = "#d73027") +
  geom_smooth(method = "lm", color = "black", linetype = "dashed", se = FALSE, linewidth = 0.8) +
  labs(title = "THBS1 vs. CD163",
       x = "THBS1 Log-expression", y = "CD163 Log-expression") +
  annotate("text", x = 0.15, y = 4.8, 
           label = paste0("Spearman rho = ", round(r1, 2), "\np < 0.001"), 
           hjust = 0, size = 4.0, fontface = "bold") +
  scale_y_continuous(limits = c(0, 5.2), breaks = 0:5) +
  scale_x_continuous(limits = c(0, 4.8), breaks = 0:4) +
  theme_classic(base_size = 13) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
        plot.margin = margin(t = 10, r = 15, b = 10, l = 10))

p2 <- ggplot(df_expr, aes(x = THBS1, y = ACTA2)) +
  geom_point(alpha = 0.25, size = 0.8, color = "#fc8d59") +
  geom_smooth(method = "lm", color = "black", linetype = "dashed", se = FALSE, linewidth = 0.8) +
  labs(title = "THBS1 vs. ACTA2",
       x = "THBS1 Log-expression", y = "ACTA2 Log-expression") +
  annotate("text", x = 0.15, y = 4.8, 
           label = paste0("Spearman rho = ", round(r2, 2), "\np < 0.001"), 
           hjust = 0, size = 4.0, fontface = "bold") +
  scale_y_continuous(limits = c(0, 5.2), breaks = 0:5) +
  scale_x_continuous(limits = c(0, 4.8), breaks = 0:4) +
  theme_classic(base_size = 13) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
        plot.margin = margin(t = 10, r = 15, b = 10, l = 10))

p3 <- ggplot(df_expr, aes(x = TGFB3, y = ACTA2)) +
  geom_point(alpha = 0.25, size = 0.8, color = "#4575b4") +
  geom_smooth(method = "lm", color = "black", linetype = "dashed", se = FALSE, linewidth = 0.8) +
  labs(title = "TGFB3 vs. ACTA2",
       x = "TGFB3 Log-expression", y = "ACTA2 Log-expression") +
  annotate("text", x = 0.15, y = 4.8, 
           label = paste0("Spearman rho = ", round(r3, 2), "\np < 0.001"), 
           hjust = 0, size = 4.0, fontface = "bold") +
  scale_y_continuous(limits = c(0, 5.2), breaks = 0:5) +
  scale_x_continuous(limits = c(0, 4.8), breaks = 0:4) +
  theme_classic(base_size = 13) +
  theme(plot.title = element_text(face = "bold", hjust = 0.5, size = 13),
        plot.margin = margin(t = 10, r = 15, b = 10, l = 10))

# 4. 组合成横向三联图，并留足顶部边距防总标题溢出
p_comb <- (p1 | p2 | p3) + 
  plot_annotation(
    title = "In Situ Spot-Level Co-expression in Human Bladder Cancer (Visium GSE319536, BC07, n = 8,953 spots)",
    theme = theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14, margin = margin(t = 10, b = 12)))
  )

# 5. 保存图片
out_png <- file.path(out_dir, "BC07_spot_coexpression_scatter_fixed.png")
out_pdf <- file.path(out_dir, "BC07_spot_coexpression_scatter_fixed.pdf")

ggsave(out_png, p_comb, width = 13.5, height = 4.6, dpi = 300, bg = "white")
ggsave(out_pdf, p_comb, width = 13.5, height = 4.6, bg = "white")

cat("\n重绘完成！文件已输出至:\n", out_png, "\n")
