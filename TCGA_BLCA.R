####TCGA数据下载####
library(tidyverse)#加载

#R镜像 快速选择
#chooseBioCmirror() #这样下载会更快
getwd()

#往上跳
#setwd("..")

####数据下载,这块吃内存####
#setwd("TCGAdata")
# setwd("data")
# library(tidyverse)#加载包
# #安装TCGAbiolinks包
# #install.packages("BiocManager")
# library(BiocManager)
# chooseBioCmirror()#选个中国区的镜像，方便链接
# #BiocManager::install("TCGAbiolinks")
# library(TCGAbiolinks)#加载包
# cancer_type = "TCGA-BLCA"   #肿瘤类型，这里可修改癌症类型，BLCA是膀胱尿路上皮癌
# #TCGA 肿瘤缩写：https://www.jianshu.com/p/3c0f74e85825
# expquery <- GDCquery(project = cancer_type,
#                      data.category = "Transcriptome Profiling",#下载转录谱
#                      data.type = "Gene Expression Quantification",#下载转录谱目录的基因表达定量
#                      workflow.type = "STAR - Counts"#下载转录谱目录的COUNTs数据
# )
# GDCdownload(expquery,directory = "GDCdata")#正式下载，会自动新建 GDCdata文件夹
# expquery2 <- GDCprepare(expquery,directory = "GDCdata",summarizedExperiment = T)#处理成想要的样式
# # save(expquery2,file = "BLCA.gdc_2022.rda") # 保存 rda格式
# 
# 
# 

# ####TCGA counts/tpms提取及整理####
# #退出Rstudio
# setwd('TCGA-BLCA')
# setwd("TCGAdata")
# library(tidyverse)#加载包
# load("BLCA.gdc_2022.rda")#导入文件，rda格式文件也可直接从文件夹双击导入
# load("gene_annotation_2022.rda")#导入gene注释文件
# table(gene_annotation_2022$type)#table 分组计数
# #基因名称symbol ENSEMBL
# #提取counts ，TCGA里面做差异分析用counts(整数)，其他全用 tpms
# counts <- expquery2@assays@data@listData[["unstranded"]]##unstranded项就是counts
# colnames(counts) <- expquery2@colData@rownames
# rownames(counts) <- expquery2@rowRanges@ranges@NAMES
# #基因ID转换
# counts <- counts %>% 
#   as.data.frame() %>% 
#   rownames_to_column("ENSEMBL") %>% 
#   inner_join(gene_annotation_2022,"ENSEMBL") %>% 
#   .[!duplicated(.$symbol),]
# # #拆解以上代码
# counts1 <- expquery2@assays@data@listData[["unstranded"]]
# colnames(counts1) <- expquery2@colData@rownames
# rownames(counts1) <- expquery2@rowRanges@ranges@NAMES
# counts1 <- as.data.frame(counts1)
# counts1 <- rownames_to_column(counts1,var = 'ENSEMBL')
# counts1 <- inner_join(counts1,gene_annotation_2022,"ENSEMBL")
# counts1 <- counts1[!duplicated(counts1$symbol),]#美元符号
# # 拆解完毕 大致判断counts和counts1是否相同
# identical(colnames(counts),colnames(counts1))
# identical(rownames(counts),rownames(counts1))
# #继续跑
# rownames(counts) <- NULL
# counts <- counts %>% column_to_rownames("symbol") #symbol（基因名称）列变成行名
# #拆解
# rownames(counts1) <- NULL #无
# counts1 <- column_to_rownames(counts1,var = 'symbol')
# #继续跑
# # 保留mRNA 
# #table
# table(counts$type)#（注：可通过table(counts$type)查看基因类型）#lncRNA
# counts <- counts[counts$type == "protein_coding",]
# #counts <- counts[counts$type == "lncRNA",]
# counts <- counts[,-c(1,ncol(counts))]
# #counts <- counts[,-c(1,602)]
# #ncol是末列
# ncol(counts)
# nrow(counts)
# # 把TCGA barcode切割为16位字符,并去除重复样本
# colnames(counts) <- substring(colnames(counts),1,16)
# counts <- counts[,!duplicated(colnames(counts))]
# table(substring(colnames(counts),14,16))
# # 保留01A（01A是肿瘤样本，11A是正常样本）  （注：可通过table(substring(colnames(counts),14,16))查看样本类型）
# counts01A <- counts[,substring(colnames(counts),14,16) == c("01A")]
# # 保留11A
# counts11A <- counts[,substring(colnames(counts),14,16) == c("11A")]
# table(substring(colnames(counts01A),14,16))
# table(substring(colnames(counts11A),14,16))
# 
# ####tpms####
# #和counts基本一模一样
# tpms <- expquery2@assays@data@listData[["tpm_unstrand"]]##tpm_unstrand项就是tpms
# colnames(tpms) <- expquery2@colData@rownames
# rownames(tpms) <- expquery2@rowRanges@ranges@NAMES
# tpms <- tpms %>% 
#   as.data.frame() %>% 
#   rownames_to_column("ENSEMBL") %>% 
#   inner_join(gene_annotation_2022,"ENSEMBL") %>% 
#   .[!duplicated(.$symbol),]
# rownames(tpms) <- NULL
# tpms <- tpms %>% column_to_rownames("symbol") 
# # 保留mRNA （注：可通过table(tpms$type)查看基因类型）
# tpms <- tpms[tpms$type == "protein_coding",]
# tpms <- tpms[,-c(1,ncol(tpms))]
# # 把TCGA barcode切割为16位字符,并去除重复样本
# colnames(tpms) <- substring(colnames(tpms),1,16)
# tpms <- tpms[,!duplicated(colnames(tpms))]
# # 保留01A  （注：可通过table(substring(colnames(tpms),14,16))查看样本类型）
# tpms01A <- tpms[,substring(colnames(tpms),14,16) == c("01A")]
# # 保留11A
# tpms11A <- tpms[,substring(colnames(tpms),14,16) == c("11A")]
# 
# #判断counts和tpms的行列名是否一致
# identical(rownames(counts01A),rownames(counts11A))
# identical(rownames(tpms01A),rownames(tpms11A))
# identical(rownames(counts01A),rownames(tpms01A))
# identical(colnames(counts01A),colnames(tpms01A))
# identical(colnames(counts11A),colnames(tpms11A))
# #保存counts和tpms数据
# write.table(counts01A,"counts01A.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# write.table(counts11A,"counts11A.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# write.table(tpms01A,"tpms01A.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# write.table(tpms11A,"tpms11A.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# #cbind和rbind 合并 col row
# #cbind之前需要确认两个数据框的行名
# counts <- cbind(counts01A,counts11A)
# tpms <- cbind(tpms01A,tpms11A)
# write.table(counts,"counts.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# write.table(tpms,"tpms.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# 
# ####tpms_log2####
# range(tpms)#查看数据范围
# range(tpms01A)
# range(tpms11A)
# tpms_log2 <- log2(tpms+1)#log2转换 为什么要加1
# range(tpms_log2)
# tpms01A_log2 <- log2(tpms01A+1)
# range(tpms01A_log2)
# tpms11A_log2 <- log2(tpms11A+1)
# range(tpms11A_log2)
# #保存log2转换后的数据
# write.table(tpms_log2,"tpms_log2.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# write.table(tpms01A_log2,"tpms01A_log2.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# write.table(tpms11A_log2,"tpms11A_log2.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# #表达谱整理完毕
####整理TCGA临床信息####

setwd("..")
setwd("clinical")
library(tidyverse)
load("BLCA.gdc_2022.rda")
#提取临床信息
clinical <- as.data.frame(expquery2@colData) %>%   
  .[!duplicated(.$sample),]
colnames(clinical)#查看一下有哪些列
#提取需要的临床信息数据
clinical <-clinical[,c("gender","age_at_index","ajcc_pathologic_stage","ajcc_clinical_t",
                       "ajcc_pathologic_t","ajcc_pathologic_n","ajcc_pathologic_m","vital_status")]
# 查看 ajcc_pathologic_t 的所有唯一值（推荐使用这个，因为病理T分期更准确）
table(clinical$ajcc_pathologic_t)
#T0  T1  T2 T2a T2b  T3 T3a T3b  T4 T4a T4b  TX 
#1   4  39  24  60  45  78  83  12  44   5   1 
# 如果你想也看看临床T分期（有时病理分期缺失，用临床分期替代）
table(clinical$ajcc_clinical_t)
# T1  T2 T2a T2b  T3 T3a T3b  T4 T4a  TX 
# 9  94  17  10  12  16   9   2   9   7 
# # 转为字符型，避免因子型干扰
clinical$ajcc_pathologic_n <- as.character(clinical$ajcc_pathologic_n)
clinical$ajcc_pathologic_m <- as.character(clinical$ajcc_pathologic_m)

# 只保留 N 不是 NX 且 M 不是 MX 的样本
clinical_clean <- clinical[
  clinical$ajcc_pathologic_n != "NX" & 
    clinical$ajcc_pathologic_m != "MX",
]

# 查看剔除后剩余样本数
nrow(clinical_clean)  # 清晰分期样本数
nrow(clinical)        # 原始总样本数

# 确保 N 和 M 为字符
clinical_clean$ajcc_pathologic_n <- as.character(clinical_clean$ajcc_pathologic_n)
clinical_clean$ajcc_pathologic_m <- as.character(clinical_clean$ajcc_pathologic_m)

# 新增 group 列，初始化为 No_Metastasis
clinical_clean$group <- "No_Metastasis"

# 判定为 Metastasis 的条件：N1/N2/N3 或 M1
clinical_clean$group[
  clinical_clean$ajcc_pathologic_n %in% c("N1", "N2", "N3") | 
    clinical_clean$ajcc_pathologic_m == "M1"
] <- "Metastasis"

# 查看分组情况统计
table(clinical_clean$group)

# 如需查看各组 N 和 M 的分布，可运行：
table(clinical_clean$ajcc_pathologic_n[clinical_clean$group == "Metastasis"])
table(clinical_clean$ajcc_pathologic_m[clinical_clean$group == "Metastasis"])

table(clinical_clean$ajcc_pathologic_n[clinical_clean$group == "No_Metastasis"])
table(clinical_clean$ajcc_pathologic_m[clinical_clean$group == "No_Metastasis"])

# 保存为 txt 文件（制表符分隔，适合后续 R/Excel 分析）
write.table(clinical_clean, 
            file = "clinical_clean_with_group.txt", 
            sep = "\t", 
            row.names = TRUE, 
            col.names = NA, 
            quote = FALSE)

# 如果你还需要保存为 csv（比如给其他软件用）
write.csv(clinical_clean, 
          file = "clinical_clean_with_group.csv", 
          row.names = TRUE)



# 把筛选后的clinical_clean也用在表达谱里筛一下，并且合并
# <- tpms01A_log2
tpms01A<-read.table("~/Bulk-RNA/TCGA-BLCA/data/tpms01A_log2.txt",sep = "\t",row.names = 1,check.names = F,stringsAsFactors = F,header = T)
counts01A <- read.table("~/Bulk-RNA/TCGA-BLCA/data/counts01A.txt", header = TRUE, row.names = 1, sep = "\t")


# TCGA数据处理：临床数据与表达谱数据的整合分析


# 查看临床数据行名(样本ID)格式
head(row.names(clinical_clean))  # 应类似 TCGA-XX-XXXX-01A-11D-A123-01

# 从行名提取前16位作为标准barcode
clinical_clean$tcga_barcode_16 <- substring(row.names(clinical_clean), 1, 16)
head(clinical_clean$tcga_barcode_16)  # 应显示 TCGA-XX-XXXX-01A 格式

# 确保N和M分期为字符型
clinical_clean$ajcc_pathologic_n <- as.character(clinical_clean$ajcc_pathologic_n)
clinical_clean$ajcc_pathologic_m <- as.character(clinical_clean$ajcc_pathologic_m)

# 筛选N和M分期明确的样本(排除NX和MX)
clinical_clean <- clinical_clean[
  clinical_clean$ajcc_pathologic_n != "NX" & 
    clinical_clean$ajcc_pathologic_m != "MX",
]

# 获取有效样本的16位barcode
valid_barcodes <- unique(clinical_clean$tcga_barcode_16)
cat("临床数据筛选后有效样本数:", length(valid_barcodes), "\n")


# 2.1 筛选与临床样本匹配的表达谱数据
# 取临床有效样本与tpms01A_log2样本的交集
valid_barcodes_matched <- intersect(valid_barcodes, colnames(tpms01A_log2))
cat("临床样本与表达谱匹配的样本数:", length(valid_barcodes_matched), "\n")

# 2.2 筛选各类型表达谱数据

tpms01A_filtered <- tpms01A[, colnames(tpms01A) %in% valid_barcodes_matched, drop = FALSE]

tpms_merged <- tpms01A_filtered

# 4.1 筛选临床数据，只保留有表达数据的样本
clinical_matched <- clinical_clean[clinical_clean$tcga_barcode_16 %in% valid_barcodes_matched, ]



tpms_t <- as.data.frame(t(tpms_merged)) %>%
  rownames_to_column("tcga_barcode_16") %>%
  inner_join(clinical_matched, by = "tcga_barcode_16")
###count数据样本名是“.
valid_barcodes_matched_dotted <- gsub("-", ".", valid_barcodes_matched)
# 分肿瘤/正常样本筛选
counts01A_filtered <- counts01A[, colnames(counts01A) %in% valid_barcodes_matched_dotted, drop = FALSE]

# 3.1 合并肿瘤和正常样本数据
counts_merged <- counts01A_filtered


colnames(clinical_matched)  <- gsub("-", ".", colnames(clinical_matched))
rownames(clinical_matched)  <- gsub("-", ".", rownames(clinical_matched))
# # 1. 处理表达谱转置后的数据（counts_merged 转置）
# counts_t <- as.data.frame(t(counts_merged)) %>%
#   rownames_to_column("tcga_barcode_16") %>%
#   # 将 "-" 替换为 "."，匹配临床数据格式
#   mutate(tcga_barcode_16 = gsub("-", ".", tcga_barcode_16))
# 

# 2. 处理临床数据（clinical_matched）的格式（确保与上述一致）
clinical_matched <- clinical_matched %>%
  mutate(tcga_barcode_16 = gsub("-", ".", tcga_barcode_16))  # 若临床原本是 "-"，则替换为 "."；反之则调整

# 4.2 转置表达谱数据并与临床数据合并(样本为行，基因为列)
counts_t <- as.data.frame(t(counts_merged)) %>%
  rownames_to_column("tcga_barcode_16") %>%
  inner_join(clinical_matched, by = "tcga_barcode_16")

counts_filtered<-counts_merged
# 5.1 保存筛选后的表达谱数据
write.table(counts_filtered, "counts_clinical_filtered.txt", 
            sep = "\t", row.names = T, col.names = NA, quote = F)
write.table(tpms_filtered, "tpms_clinical_filtered.txt", 
            sep = "\t", row.names = T, col.names = NA, quote = F)

# 5.3 保存表达谱与临床数据整合结果
write.table(counts_t, "counts_with_clinical.txt", 
            sep = "\t", row.names = F, quote = F)
write.table(tpms_t, "tpms_with_clinical.txt", 
            sep = "\t", row.names = F, quote = F)

# 5.4 保存筛选后的临床数据
save(clinical_matched, file = "clinical_matched.rda")







#解螺旋：https://www.helixlife.cn/class
#加入OS OS.time
surv_01A <- read.table("surv_01A.txt",sep = "\t",row.names = 1,check.names = F,stringsAsFactors = F,header = T)

# clinical.expr01A <- read.table("clinical.expr01A.txt",sep = "\t",row.names = 1,check.names = F,stringsAsFactors = F,header = T)
# rownames(clinical.expr01A) <- gsub("-", ".", rownames(clinical.expr01A))
# 
# identical(rownames(clinical.expr01A),rownames(surv_01A))
# 
# exp_surv_clinical_01A <- cbind(surv_01A,clinical.expr01A)
# 
# write.table(exp_surv_clinical_01A,"exp_surv_clinical_01A.txt",sep = "\t",row.names = T,col.names = NA,quote = F)
# 

#exp_surv_clinical_01A <- read.table("exp_surv_clinical_01A.txt",sep = "\t",row.names = 1,check.names = F,stringsAsFactors = F,header = T)
# 步骤2：将第一列（样本条码列，假设列名为 tcga_barcode_16）设为行名
rownames(tpms_t) <- tpms_t$tcga_barcode_16  # 提取第一列作为行名
tpms_t <- tpms_t[, -which(names(tpms_t) == "tcga_barcode_16")]  # 移除样本条码列（避免重复）

# 步骤3：转置 tpms_t → 让「样本为行，基因为列」（与生存信息的“样本行”结构对齐）
tpms_transposed <- as.data.frame(t(tpms_t))

# 步骤4：统一「样本名格式」（将行名中的 `-` 替换为 `.`，匹配 surv_01A 的行名）
colnames(tpms_transposed) <- gsub("-", ".", colnames(tpms_transposed))
tpms_transposed <- as.data.frame(t(tpms_transposed))

# 步骤5：读取生存信息数据
surv_01A <- read.table("surv_01A.txt", 
                       sep = "\t", 
                       row.names = 1,  # 第一列为行名（样本名）
                       check.names = FALSE, 
                       stringsAsFactors = FALSE, 
                       header = TRUE)


# 步骤6：筛选「共有样本」（同时存在于 tpms 和生存信息中的样本）
common_samples <- intersect(rownames(tpms_transposed), rownames(surv_01A))
cat("共有样本数量：", length(common_samples), "\n")  # 打印匹配的样本数


# 步骤7：分别筛选 tpms 和生存信息 → 仅保留共有样本
tpms_common <- tpms_transposed[common_samples, , drop = FALSE]
surv_common <- surv_01A[common_samples, , drop = FALSE]


# 步骤8：强制样本顺序一致（确保 cbind 时“样本-生存信息-表达量”一一对应）
if (!identical(rownames(tpms_common), rownames(surv_common))) {
  surv_common <- surv_common[rownames(tpms_common), ]
}


# 步骤9：合并「生存信息 + tpms 表达谱」
exp_surv_clinical_tpms <- cbind(surv_common, tpms_common)


# 步骤10：保存最终结果
write.table(exp_surv_clinical_tpms, 
            "exp_surv_clinical_tpms.txt", 
            sep = "\t", 
            row.names = TRUE,   # 保留样本名（行名）
            col.names = NA,    # 列名格式与原始表达谱一致（首行含“行名占位”）
            quote = FALSE)     # 避免字符型数据被引号包裹

########基线数据######
# Load required packages
library(tidyverse)
library(ggpubr)
library(survival)
library(survminer)
library(tableone)
library(patchwork)
setwd("baseline")
# Read data
tpms_with_clinical <- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_with_clinical.txt", row.names = 1)

# 1. Data preprocessing
clinical_vars <- c("gender", "age_at_index", "ajcc_pathologic_stage", 
                   "ajcc_pathologic_t", "ajcc_pathologic_n", "ajcc_pathologic_m", 
                   "vital_status")

clinical_data <- tpms_with_clinical[, clinical_vars]

# Clean and transform variables
clinical_data <- clinical_data %>%
  mutate(
    gender = factor(gender, levels = c("male", "female")),
    age_group = cut(age_at_index, 
                    breaks = c(0, 50, 60, 70, 80, 100),
                    labels = c("<50", "50-59", "60-69", "70-79", "≥80")),
    metastasis_status = ifelse(
      ajcc_pathologic_n %in% c("N1", "N2", "N3") | ajcc_pathologic_m == "M1",
      "Metastatic",
      "No-Metastatic"
    ),
    metastasis_status = factor(metastasis_status, 
                               levels = c("No-Metastatic", "Metastatic")),
    vital_status = factor(vital_status, levels = c("Alive", "Dead")),
    ajcc_pathologic_t = factor(ajcc_pathologic_t, 
                               levels = c("T1", "T2", "T3", "T4")),
    ajcc_pathologic_n = factor(ajcc_pathologic_n,
                               levels = c("N0", "N1", "N2", "N3"))
  )

# 2. Descriptive statistics table
table_vars <- c("gender", "age_at_index", "age_group", 
                "ajcc_pathologic_t", "ajcc_pathologic_n", "ajcc_pathologic_m",
                "ajcc_pathologic_stage")

cat("==================== Baseline Characteristics ====================\n")
table1 <- CreateTableOne(vars = table_vars, 
                         strata = "metastasis_status", 
                         data = clinical_data,
                         addOverall = TRUE)

# Print table
print(table1, smd = TRUE, catDigits = 1, contDigits = 1)

# 3. Statistical tests
gender_test <- chisq.test(table(clinical_data$metastasis_status, 
                                clinical_data$gender))
cat("\nGender distribution chi-square test:\n")
print(gender_test)

age_test <- wilcox.test(age_at_index ~ metastasis_status, 
                        data = clinical_data)
cat("\nAge distribution Wilcoxon test:\n")
print(age_test)

# 4. Visualization with English labels only
theme_set(theme_minimal(base_size = 12) +
            theme(plot.title = element_text(hjust = 0.5, face = "bold"),
                  legend.position = "bottom"))

# 4.1 Patient distribution by metastasis status and gender
p1 <- clinical_data %>%
  ggplot(aes(x = metastasis_status, fill = gender)) +
  geom_bar(position = "dodge", alpha = 0.8) +
  geom_text(stat = 'count', aes(label = after_stat(count)), 
            position = position_dodge(width = 0.9), vjust = -0.5) +
  labs(title = "Patient Distribution by Metastasis Status and Gender",
       x = "Metastasis Status", y = "Number of Patients", fill = "Gender") +
  scale_fill_manual(values = c("#1f77b4", "#ff7f0e")) +
  theme(axis.text = element_text(angle = 0))

# 4.2 Age distribution by metastasis status
p2 <- clinical_data %>%
  ggplot(aes(x = metastasis_status, y = age_at_index, fill = metastasis_status)) +
  geom_boxplot(alpha = 0.7) +
  stat_compare_means(method = "wilcox.test", 
                     label = "p.format", label.y = 100) +
  labs(title = "Age Distribution by Metastasis Status",
       x = "Metastasis Status", y = "Age (years)") +
  scale_fill_manual(values = c("#2ca02c", "#d62728")) +
  theme(legend.position = "none")

# 4.3 T-stage distribution by metastasis status
p3 <- clinical_data %>%
  filter(!is.na(ajcc_pathologic_t)) %>%
  ggplot(aes(x = ajcc_pathologic_t, fill = metastasis_status)) +
  geom_bar(position = "fill", alpha = 0.8) +
  labs(title = "T-stage Distribution by Metastasis Status",
       x = "T Stage", y = "Proportion", fill = "Metastasis Status") +
  scale_fill_manual(values = c("#2ca02c", "#d62728")) +
  scale_y_continuous(labels = scales::percent_format())

# 4.4 Survival status by metastasis status
p4 <- clinical_data %>%
  ggplot(aes(x = metastasis_status, fill = vital_status)) +
  geom_bar(position = "fill", alpha = 0.8) +
  labs(title = "Survival Status by Metastasis Status",
       x = "Metastasis Status", y = "Proportion", fill = "Vital Status") +
  scale_fill_manual(values = c("#17becf", "#7f7f7f")) +
  scale_y_continuous(labels = scales::percent_format())

# 4.5 AJCC Stage distribution
p5 <- clinical_data %>%
  filter(!is.na(ajcc_pathologic_stage)) %>%
  count(ajcc_pathologic_stage, metastasis_status) %>%
  ggplot(aes(x = ajcc_pathologic_stage, y = n, fill = metastasis_status)) +
  geom_col(position = "dodge", alpha = 0.8) +
  labs(title = "AJCC Stage Distribution by Metastasis Status",
       x = "AJCC Pathologic Stage", y = "Number of Patients", 
       fill = "Metastasis Status") +
  scale_fill_manual(values = c("#2ca02c", "#d62728")) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Combine plots
combined_plot <- (p1 + p2) / (p3 + p4) / p5 + 
  plot_annotation(title = "TCGA-BLCA Cohort Clinical Characteristics Analysis",
                  theme = theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold")))

# Display combined plot
print(combined_plot)

# 5. Detailed statistical summary
cat("==================== Detailed Statistical Summary ====================\n")
cat("TCGA-BLCA cohort includes", nrow(clinical_data), "patients:\n")

metastasis_summary <- clinical_data %>%
  group_by(metastasis_status) %>%
  summarise(
    n = n(),
    male = sum(gender == "male"),
    female = sum(gender == "female"),
    median_age = median(age_at_index, na.rm = TRUE),
    IQR_age = IQR(age_at_index, na.rm = TRUE)
  )

for(i in 1:nrow(metastasis_summary)) {
  cat("- ", metastasis_summary$metastasis_status[i], ": ", metastasis_summary$n[i], 
      "patients (Male: ", metastasis_summary$male[i], ", Female: ", metastasis_summary$female[i], 
      ", Median age: ", metastasis_summary$median_age[i], "years)\n")
}

cat("\nStatistical test results:\n")
cat("- Gender distribution: P =", round(gender_test$p.value, 3), 
    ifelse(gender_test$p.value > 0.05, "(No significant difference)", "(Significant difference)"), "\n")
cat("- Age distribution: P =", round(age_test$p.value, 3),
    ifelse(age_test$p.value > 0.05, "(No significant difference)", "(Significant difference)"), "\n")

# 6. Save results
write.csv(print(table1, smd = TRUE), "clinical_baseline_table_english.csv", row.names = TRUE)
ggsave("clinical_analysis_plot_english.tiff", combined_plot, 
       width = 14, height = 12, dpi = 300, bg = "white")
















# ==================== 差异分析 ====================
library(SummarizedExperiment)
library(readxl)
library(DESeq2)
library(GenomicFeatures) 
library(GenomicRanges)
library(biomaRt)          
library(edgeR)            
library(ggplot2)
library(pheatmap)
library(clusterProfiler)
library(ggrepel) 
library(AnnotationDbi) 
library(org.Hs.eg.db) 
library(dplyr)
library(tibble) 
library(purrr)
library(tidyr)
library(future.apply)
library(forcats) 
#install.packages("oncoPredict") 
library(oncoPredict)
library(ggpubr)
library(ggsci)
library(limma)
library(pheatmap)
library(harmony)
library(SingleCellExperiment)
library(scater)
library(sva)
setwd("..")
setwd("DEG")
library(DESeq2)
library(dplyr)
library(clusterProfiler)
library(org.Hs.eg.db)

# ========== 1 读取数据 ==========
# count矩阵（金标准：183个样本）
counts_filtered <- read.delim(
  "~/Bulk-RNA/TCGA-BLCA/clinical/counts_clinical_filtered.txt",
  row.names = 1,
  sep = "\t",
  header = TRUE,
  check.names = FALSE
)

# 临床原始表
df_raw <- read.delim(
  "~/Bulk-RNA/TCGA-BLCA/clinical/clinical_clean_with_group.txt",
  sep = "\t",
  header = TRUE
)

# 整理临床表，样本条码设为行名
clinical_clean <- df_raw %>%
  rename(sample_full = 1) %>%
  filter(!is.na(sample_full)) %>%
  column_to_rownames("sample_full")

# ========== 2 样本名格式统一匹配（关键） ==========
# 提取count的样本ID
count_sample_short <- colnames(counts_filtered)

# 把临床全长样本名 → 截取前16位 + 把 "-" 替换为 "."，和count名字完全一致
clinical_clean$sample_short <- substring(rownames(clinical_clean), 1, 16)
clinical_clean$sample_short <- gsub("-", ".", clinical_clean$sample_short)

# 只保留count中存在的183个样本，临床队列自动对齐
clinical_clean_match <- clinical_clean[clinical_clean$sample_short %in% count_sample_short, ]

# 核对：行数必须等于183
nrow(clinical_clean_match)

# ========== 3 重新生成分组（严格AJCC N/M定义，无NA） ==========
clinical_clean_match$group <- "No_Metastasis"
idx_met <- clinical_clean_match$ajcc_pathologic_n %in% c("N1","N2","N3") | clinical_clean_match$ajcc_pathologic_m == "M1"
clinical_clean_match$group[idx_met] <- "Metastasis"

# 校验分组，无缺失
table(clinical_clean_match$group, useNA = "ifany")
sum(is.na(clinical_clean_match$group))

# ========== 4 构建DESeq2分组信息，顺序严格匹配count ==========
# 把临床行名统一为短ID，和count列名一模一样
rownames(clinical_clean_match) <- clinical_clean_match$sample_short

group_info <- data.frame(
  sample_id = rownames(clinical_clean_match),
  group = clinical_clean_match$group
)

expr_samples <- colnames(counts_filtered)
matched_idx <- match(expr_samples, group_info$sample_id)

conditions <- data.frame(
  group = factor(
    group_info$group[matched_idx],
    levels = c("No_Metastasis", "Metastasis")
  ),
  row.names = expr_samples
)

# 再次确认无NA
sum(is.na(conditions$group))
# 4. 创建 DESeq2 数据集对象
dds <- DESeqDataSetFromMatrix(
  countData = counts_matrix,    # 原始count矩阵（行：基因，列：样本）
  colData = conditions,         # 样本信息（包含分组）
  design = ~ group              # 设计公式：以group为分组变量
)
dds <- DESeq(dds)
# resultsNames(dds)
# [1] "Intercept"                         "group_Metastasis_vs_No_Metastasis"
# 6. 提取差异分析结果（比较Metastasis vs No_Metastasis）
res <- results(dds, contrast = c("group", "Metastasis", "No_Metastasis"))

fdr_cutoff <- 0.05
lfc_cutoff <- 0.5
# # 重新处理DEG，同时包含ENTREZID和SYMBOL
DEG <- as.data.frame(res) %>%
  rownames_to_column("SYMBOL") %>%  # 直接用Symbol作为主键
  filter(padj < fdr_cutoff & !is.na(padj)) %>%
  # 从Symbol转换到ENTREZID（富集分析必需）
  left_join(
    bitr(.$SYMBOL, 
         fromType = "SYMBOL",  # 以Symbol为起点转换
         toType = "ENTREZID", 
         OrgDb = org.Hs.eg.db),
    by = "SYMBOL"
  ) %>%
  # 处理一个Symbol对应多个ENTREZID的情况
  group_by(SYMBOL) %>%
  slice_head(n = 1) %>%  # 保留第一个映射结果
  ungroup() %>%
  # 补充可能缺失的ENSEMBL ID（可选，用于交叉验证）
  mutate(
    ENSEMBL = mapIds(
      org.Hs.eg.db,
      keys = SYMBOL,
      column = "ENSEMBL",
      keytype = "SYMBOL",
      multiVals = "first"
    )
  ) %>%
  # 调整列顺序（Symbol放在最前，符合你的分析习惯）
  select(SYMBOL, ENTREZID, ENSEMBL, everything()) %>%
  distinct(SYMBOL, .keep_all = TRUE)  # 确保每个Symbol唯一
save(dds,res,DEG, file="DEG_Metastasis_Rel.Rda")

thbs1_tgfb3_data <- subset(DEG, SYMBOL %in% c("THBS1", "TGFB3"))
# 定义差异基因筛选函数
get_DEG_stats <- function(df, padj_thresh, lfc_thresh) {
  df %>%
    filter(padj < padj_thresh, abs(log2FoldChange) > lfc_thresh) %>%
    summarise(
      n_up = sum(log2FoldChange > 0),
      n_down = sum(log2FoldChange < 0),
      n_total = n()
    ) %>%
    mutate(
      padj_threshold = padj_thresh,
      lfc_threshold = lfc_thresh
    )
}

# 生成两种筛选条件的差异基因结果
DEG_list <- list(
  strict = DEG %>% filter(padj < 0.05, abs(log2FoldChange) > 1),
  middle = DEG %>% filter(padj < 0.05, abs(log2FoldChange) > 0.5),
  Metastasisaxed = DEG %>% filter(padj < 0.1, abs(log2FoldChange) > 0.5)
)

# # 输出差异基因文件
# write.csv(DEG_list$strict, "DESeq2_significant_genes_strict.csv", row.names = FALSE)
# write.csv(DEG_list$middle, "DESeq2_significant_genes_middle.csv", row.names = FALSE)
# write.csv(DEG_list$Metastasisaxed, "DESeq2_significant_genes_Metastasisaxed.csv", row.names = FALSE)

# 生成并输出统计总结表
stats_summary <- bind_rows(
  get_DEG_stats(DEG, 0.05, 1),
  get_DEG_stats(DEG, 0.05, 0.5),
  get_DEG_stats(DEG, 0.1, 0.5)
) %>%
  select(padj_threshold, lfc_threshold, n_up, n_down, n_total)

write.csv(stats_summary, "DEG_summary_statistics.csv", row.names = FALSE)
###选0.5，0.05
##########Wald 检验、Wilcoxon 秩和检验和t 检验#########
setwd("wald_wilcox_t")
getwd()
plan(multisession) # 根据电脑核心数调整
counts_matrix <- as.data.frame(counts_matrix) 
# 修正：从 group_info 构建样本分组信息（关键步骤）
# group_info 结构应为：包含 sample_id（样本名）和 group（分组：Metastasis/No_Metastasis）
col_data <- data.frame(
  group = group_info$group,  # 提取分组信息（Metastasis/No_Metastasis）
  row.names = group_info$sample_id  # 用样本名作为行名（与counts_matrix列名匹配）
)

# 确保 col_data 的样本顺序与 counts_matrix 一致（按counts_matrix列名排序）
col_data <- col_data[colnames(counts_matrix), , drop = FALSE]

# 定义分组名称（转移相关分组）
group1 <- "Metastasis"         # 转移组
group2 <- "No_Metastasis"       # 非转移组

# 提取两组的样本名（基于col_data筛选）
sample1 <- rownames(subset(col_data, group == group1))  # Metastasis组样本名
sample2 <- rownames(subset(col_data, group == group2))  # No_Metastasis组样本名

# 提取两组的计数数据
counts_group1 <- counts_matrix[, sample1, drop = FALSE]  # Metastasis组计数
counts_group2 <- counts_matrix[, sample2, drop = FALSE]  # No_Metastasis组计数

# 定义筛选阈值（可根据需求调整）
fdrFilter <- 0.05
significant_cutoff <- 0.5 # log2FC的绝对值阈值

######### t 检验（参数检验）
# 计算logFC
logFC_t <- log2((rowMeans(counts_group1) + 1) / (rowMeans(counts_group2) + 1))

# 并行计算t检验p值
p_values_t <- future_lapply(1:nrow(counts_matrix), function(i) {
  x <- counts_group2[i, ][!is.na(counts_group2[i, ])] # 对照组
  y <- counts_group1[i, ][!is.na(counts_group1[i, ])] # 处理组
  t.test(x, y)$p.value
})
p_t <- unlist(p_values_t)
p_adj_t <- p.adjust(p_t, method = "fdr")

# 整合结果
result_t <- data.frame(
  logFC = logFC_t,
  p_value = p_t,
  p_adj = p_adj_t,
  SYMBOL = rownames(counts_matrix),
  row.names = rownames(counts_matrix)
)

# 添加差异标记
result_t$Change <- factor(ifelse(
  result_t$p_adj < fdrFilter & abs(result_t$logFC) > significant_cutoff,
  ifelse(result_t$logFC > 0, "Up", "Down"),
  "Non"
))

# 保存结果
saveRDS(result_t, "result_t_test.rds")
write.csv(result_t, "result_t_test.csv", row.names = TRUE)



#######秩和检验
# 计算logFC（与t检验一致）
logFC_wilcox <- log2((rowMeans(counts_group1) + 1) / (rowMeans(counts_group2) + 1))

# 并行计算Wilcoxon检验p值
p_values_wilcox <- future_lapply(1:nrow(counts_matrix), function(i) {
  x <- counts_group2[i, ][!is.na(counts_group2[i, ])]
  y <- counts_group1[i, ][!is.na(counts_group1[i, ])]
  wilcox.test(x, y)$p.value
})
p_wilcox <- unlist(p_values_wilcox)
p_adj_wilcox <- p.adjust(p_wilcox, method = "fdr")

# 整合结果
result_wilcox <- data.frame(
  logFC = logFC_wilcox,
  p_value = p_wilcox,
  p_adj = p_adj_wilcox,
  SYMBOL = rownames(counts_matrix),
  row.names = rownames(counts_matrix)
)

# 添加差异标记
result_wilcox$Change <- factor(ifelse(
  result_wilcox$p_adj < fdrFilter & abs(result_wilcox$logFC) > significant_cutoff,
  ifelse(result_wilcox$logFC > 0, "Up", "Down"),
  "Non"
))

# 保存结果
saveRDS(result_wilcox, "result_wilcox.rds")
write.csv(result_wilcox, "result_wilcox.csv", row.names = TRUE)



############Wald 检验（基于广义线性模型）
# 3. Wald检验（基于广义线性模型，修正版）
if (!require("lmtest")) install.packages("lmtest")
library(lmtest)

# 准备数据转换为数据框（关键修正）
# 转置计数矩阵并转换为数据框，确保样本为行，基因为列
counts_t <- as.data.frame(t(counts_matrix))

# 添加分组信息（1=Metastasis组，0=No_Metastasis组）
counts_t$group <- ifelse(rownames(counts_t) %in% sample1, 1, 0)

# 计算logFC（与前两种方法一致）
logFC_wald <- log2((rowMeans(counts_group1) + 1) / (rowMeans(counts_group2) + 1))

# 并行计算Wald检验p值
# p_values_wald <- future_lapply(colnames(counts_t)[colnames(counts_t) != "group"], function(gene) {
#   # 构建线性模型：表达量 ~ 分组（此时data是数据框，符合lm要求）
#   lm_model <- lm(formula = as.formula(paste(gene, "~ group")), data = counts_t)
#   # 进行Wald检验，检验分组系数是否为0
#   wald_result <- waldtest(lm_model, test = "Chisq")
#   return(wald_result$Pr[2]) # 提取p值
# })
# 检查group变量的水平和样本数
table(counts_t$group)  # 确保至少有2组，且每组样本数≥1

# 检查是否有基因表达量全为0或方差为0
zero_var_genes <- apply(counts_t[, colnames(counts_t) != "group"], 2, function(x) var(x) == 0)
sum(zero_var_genes)  # 统计零方差基因数量
# 过滤零方差基因和全零基因
keep_genes <- !zero_var_genes
counts_t_filtered <- counts_t[, c(keep_genes, TRUE)]  # 保留group列

# # 确保group至少有2个水平
# if(length(unique(counts_t_filtered$group)) < 2) {
#   stop("分组变量必须至少有2个水平！")
# }
p_values_wald <- future_lapply(
  colnames(counts_t_filtered)[colnames(counts_t_filtered) != "group"], 
  function(gene) {
    tryCatch({
      # 构建线性模型
      lm_model <- lm(formula = as.formula(paste(gene, "~ group")), 
                     data = counts_t_filtered)
      # 进行Wald检验
      wald_result <- waldtest(lm_model, test = "Chisq")
      return(wald_result$Pr[2])
    },error = function(e) {
      # 输出错误信息（可选），返回NA表示该基因计算失败
      message(paste("基因", gene, "计算失败：", e$message))
      return(NA)
    })
  }
)
########失败很多，结果不好
#整理结果
filtered_genes <- colnames(counts_t_filtered)[colnames(counts_t_filtered) != "group"]

# 用过滤后的基因名命名结果（确保长度一致）
names(p_values_wald) <- filtered_genes
# names(p_values_wald) <- colnames(counts_t)[colnames(counts_t) != "group"]
p_wald <- unlist(p_values_wald)
p_adj_wald <- p.adjust(p_wald, method = "fdr")

# 整合最终结果
result_wald <- data.frame(
  logFC = logFC_wald,
  p_value = p_wald[rownames(counts_matrix)], # 匹配基因顺序
  p_adj = p_adj_wald[rownames(counts_matrix)],
  SYMBOL = rownames(counts_matrix),
  row.names = rownames(counts_matrix)
)

# 添加差异标记
result_wald$Change <- factor(ifelse(
  result_wald$p_adj < fdrFilter & abs(result_wald$logFC) > significant_cutoff,
  ifelse(result_wald$logFC > 0, "Up", "Down"),
  "Non"
))

# 保存结果
saveRDS(result_wald, "result_wald.rds")
write.csv(result_wald, "result_wald.csv", row.names = TRUE)







# 选择注释数据库（根据物种调整）
organism <- "human" # 或"mouse"
if (organism == "mouse") {
  anno_db <- org.Mm.eg.db
} else {
  anno_db <- org.Hs.eg.db
}

# 为三种结果添加注释（以t检验结果为例，其他同理）
add_annotation <- function(result_df, anno_db) {
  result_df$SYMBOL <- mapIds(
    x = anno_db,
    keys = rownames(result_df),
    keytype = "SYMBOL", # 若基因名是SYMBOL则改为"SYMBOL"
    column = "ENSEMBL",
    multiVals = "first"
  )
  result_df$ENTREZID <- mapIds(
    x = anno_db,
    keys = rownames(result_df),
    keytype = "SYMBOL",
    column = "ENTREZID",
    multiVals = "first"
  )
  return(result_df)
}

# 应用注释函数
result_t <- add_annotation(result_t, anno_db)
result_wilcox <- add_annotation(result_wilcox, anno_db)
result_wald <- add_annotation(result_wald, anno_db)

# 重新保存带注释的结果
saveRDS(result_t, "result_t_test_annotated.rds")
saveRDS(result_wilcox, "result_wilcox_annotated.rds")
saveRDS(result_wald, "result_wald_annotated.rds")
# 定义筛选阈值（与前面分析保持一致）
fdr_cutoff <- 0.05  # 调整后p值阈值
logfc_cutoff <- 0.5  # log2FC绝对值阈值

# 1. Wald检验结果筛选
Metastasis_vs_No_Metastasis_DEGs_wald <- subset(
  result_wald,
  p_adj < fdr_cutoff & abs(logFC) > logfc_cutoff
)
# 统计上调/下调基因数量
cat("Wald检验差异基因统计（Metastasis vs No_Metastasis）：\n")
table(Metastasis_vs_No_Metastasis_DEGs_wald$logFC > logfc_cutoff)  # TRUE=上调，FALSE=下调

# 2. Wilcoxon检验结果筛选
Metastasis_vs_No_Metastasis_DEGs_wilcox <- subset(
  result_wilcox,
  p_adj < fdr_cutoff & abs(logFC) > logfc_cutoff
)
cat("\nWilcoxon检验差异基因统计（Metastasis vs No_Metastasis）：\n")
table(Metastasis_vs_No_Metastasis_DEGs_wilcox$logFC > logfc_cutoff)

# 3. t检验结果筛选
Metastasis_vs_No_Metastasis_DEGs_ttest <- subset(
  result_t,
  p_adj < fdr_cutoff & abs(logFC) > logfc_cutoff
)
cat("\nt检验差异基因统计（Metastasis vs No_Metastasis）：\n")
table(Metastasis_vs_No_Metastasis_DEGs_ttest$logFC > logfc_cutoff)
########全是0

# table(result_wilcox$p_adj < 0.05)  ########是0
# table(abs(result_wilcox$logFC) > 0.5) 








#==== 差异分析后 ====
###以下按照DEG_list$middle来
setwd("..")

####PCA
#log_counts <- rlog(dds)  # 或 vst(dds)
vsd <- vst(dds, blind=FALSE)

#plotPCA(log_counts, intgroup = "group")
pca_plot <- plotPCA(vsd, intgroup="group", returnData=TRUE)
ggplot(pca_plot, aes(PC1, PC2, color=group)) +
  geom_point(size=3) +
  #geom_text_repel(aes(label=name)) +
  theme_minimal()
# 差异基因图
# 按padj排序并取前50
top_genes <- rownames(res)[order(res$padj)[1:50]]
mat <- assay(vsd)[top_genes, ]
# 按分组排序样本（No_Metastasis在前，Metastasis在后）
sample_order <- order(colData(dds)$group)
mat_sorted <- mat[, sample_order]

# 精简版热图代码
pheatmap(
  mat_sorted,
  annotation_col = data.frame(group = colData(dds)$group[sample_order], 
                              row.names = colnames(mat_sorted)),
  scale = "row",
  show_rownames = FALSE,
  cluster_cols = FALSE,  # 关键参数：禁用列聚类
  gaps_col = sum(colData(dds)$group == "No_Metastasis"),  # 添加分组分隔线
  main = "Top 50 DEGs (Grouped)"
)


####火山图
library(ggplot2)
library(ggrepel)


# 设置阈值（用DESeq02的）
fdr_cutoff <- 0.05
lfc_cutoff <- 0.5

# 预处理数据（核心逻辑）
res$Change <- ifelse(
  res$padj < fdr_cutoff & abs(res$log2FoldChange) > lfc_cutoff,
  ifelse(res$log2FoldChange > lfc_cutoff, "Up", "Down"),
  "Non"
)

# 火山图（核心绘图）
# ggplot(as.data.frame(res), aes(x = log2FoldChange, y = -log10(padj))) +
#   geom_point(aes(color = Change), alpha = 0.6, size = 1.5) +
#   scale_color_manual(values = c("Up" = "red", "Down" = "blue", "Non" = "grey")) +
#   geom_vline(xintercept = c(-lfc_cutoff, lfc_cutoff), linetype = "dashed") +
#   geom_hline(yintercept = -log10(fdr_cutoff), linetype = "dashed") +
#   labs(x = "log2(Fold Change)", y = "-log10(FDR)") +
#   theme_minimal()

# MA图（直接使用DESeq2函数）
#plotMA(res, alpha = fdr_cutoff, main = "MA-plot", ylim = c(-5, 5))

res$SYMBOL <- rownames(res)
# 取 padj 最小的 10 个基因
top_genes <- head(res[order(res$padj), ], 10)

ggplot(as.data.frame(res), aes(x = log2FoldChange, y = -log10(padj))) +
  geom_point(aes(color = Change), alpha = 0.6, size = 1.5) +
  scale_color_manual(values = c("Up" = "red", "Down" = "blue", "Non" = "grey")) +
  geom_vline(xintercept = c(-1, 1), linetype = "dashed") +
  geom_hline(yintercept = -log10(0.05), linetype = "dashed") +
  geom_text_repel(
    data = top_genes,
    aes(label = SYMBOL),
    box.padding = 0.5,
    max.overlaps = Inf
  ) +
  labs(x = "log2(Fold Change)", y = "-log10(FDR)") +
  theme_minimal()

# ==================== 富集分析 ====================
####GO#####
setwd("GO")
de_genes <- rownames(subset(res, padj < fdr_cutoff& abs(log2FoldChange) > lfc_cutoff))

ego <- enrichGO(
  gene          = de_genes,       
  OrgDb         = org.Hs.eg.db,   
  keyType       = "SYMBOL",      
  ont           = "BP",
  pvalueCutoff  = 0.05,
  qvalueCutoff  = 0.2,
  pAdjustMethod = "BH",
  readable      = TRUE            
)

# ego_filtered <- ego@result %>%
#   filter(p.adjust < 0.05 )  # 自定义组合& qvalue < 0.5
# 
# write.csv(ego_filtered, "ego_filtered.csv", row.names = FALSE)

# ##合并相似条目试一下
# ego_simplified <- simplify(ego, cutoff=0.7)  # 合并相似GO条目
# dotplot(ego_simplified, showCategory=20, font.size=8) +
#   ggtitle("Simplified GO Enrichment Analysis")

ego_res <- ego@result
write.csv(ego_res, "ego_res.csv", row.names =
            FALSE)
save(ego,ego_res,file = "GO_DEG_02.Rda")

dotplot(ego, 
        showCategory = 15, 
        color = "p.adjust",      # 颜色基于p.adjust
        size = "Count",          # 大小基于基因数
        orderBy = "GeneRatio",   # 按GeneRatio排序
        font.size = 10) +
  scale_color_gradient(low = "red", high = "blue")  # 反转颜色梯度

### 肿瘤/免疫相关
plot_simple <- function(data, keywords, color, title) {
  data %>% 
    filter(str_detect(Description, keywords), p.adjust < 0.05) %>%
    ggplot(aes(as.numeric(sub("/.*", "", GeneRatio)), 
               fct_reorder(Description, GeneRatio))) + 
    geom_col(fill = color, width = 0.7) +
    labs(x = "Gene Count", y = "", title = title)
}
library(ggplot2)
library(dplyr)
library(stringr)  # 提供str_detect()函数
plot_simple(ego_res, "tumor|neoplasm", "#d73027", "Tumor Genes")
plot_simple(ego_res, "immune|interleukin", "#4575b4", "Immune Genes")
####00000000
#CD4+ T（Th1/Th17/Treg），PD-1/CTLA4
#关注TNF-α




####KEGG####
setwd("..")
setwd("KEGG")
# 4. 获取上下调基因
up_genes <- DEG %>% filter(log2FoldChange > lfc_cutoff ) %>% pull(ENTREZID) %>% na.omit()
down_genes <- DEG %>% filter(log2FoldChange < -lfc_cutoff ) %>% pull(ENTREZID) %>% na.omit()

cat("上调基因数量:", length(up_genes), "\n下调基因数量:", length(down_genes))
# 上调基因数量: 2227 
# 下调基因数量: 687


# KEGG分析函数（调参数）
run_kegg <- function(gene_list, direction) {
  enrichKEGG(
    gene = gene_list,
    organism = "hsa",
    keyType = "ncbi-geneid",
    pvalueCutoff = 0.05,
    use_internal_data = FALSE,  # 强制在线访问
    minGSSize = 5
  ) %>% 
    setReadable(OrgDb = org.Hs.eg.db, keyType = "ENTREZID") %>%
    mutate(Direction = direction)
}
# 执行KEGG分析
kegg_up <- run_kegg(up_genes, "Upregulated")
kegg_down <- run_kegg(down_genes, "Downregulated")

# 保存单独结果
write.csv(as.data.frame(kegg_up), "KEGG_upregulated_pathways.csv", row.names = FALSE)
write.csv(as.data.frame(kegg_down), "KEGG_downregulated_pathways.csv", row.names = FALSE)

# 优化的合并可视化
pdf("KEGG_combined_pathways.pdf", width = 10, height = 8)
# 预处理数据
up_order <- kegg_up[order(kegg_up$Count, decreasing = TRUE), ]
down_order <- kegg_down[order(kegg_down$Count, decreasing = TRUE), ]

# 筛选显著通路并限制数量
top_up <- up_order[up_order$p.adjust < 0.05, ][1:min(20, nrow(up_order)), ]
top_down <- down_order[down_order$p.adjust < 0.05, ][1:min(20, nrow(down_order)), ]

# 添加分组信息
top_up$group <- 1
top_down$group <- -1

# 合并数据
combined_data <- rbind(top_up, top_down)
combined_data$log_padj <- -log10(combined_data$p.adjust) * combined_data$group

# 绘图
ggplot(combined_data, 
       aes(x = reorder(Description, log_padj), 
           y = log_padj, 
           fill = group)) +
  geom_bar(stat = "identity") +
  scale_fill_gradient2(low = "blue", mid = "white", high = "red", 
                       midpoint = 0, guide = "none") +
  labs(x = "", y = "-log10(p.adjust) with direction", 
       title = "Top KEGG Pathways") +
  coord_flip() +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 14),
        axis.text.y = element_text(size = 10))
#dev.off()
#关注mTOR，因为PI3K-Akt通路显著激活

# 耐药机制：mTOR反馈激活（联用mTOR抑制剂（如依维莫司）），
# RTK旁路激活（联合EGFR/HER2抑制剂），
# 代谢重编程（联用糖酵解抑制剂（2-DG））


####GSEA####
#GSEA转换不转换ID都可以#
setwd("..")
setwd("GSEA")
DEG_unique <- DEG %>%
  group_by(SYMBOL) %>%             # 按SYMBOL分组
  slice(which.max(abs(log2FoldChange))) %>%  # 保留最大|log2FC|的记录
  ungroup() %>%
  filter(!is.na(SYMBOL))           

geneList <- DEG_unique$log2FoldChange
names(geneList) <- as.character(DEG_unique$SYMBOL)  
geneList <- sort(geneList, decreasing = TRUE)
# geneList <- DEG$log2FoldChange %>% setNames(DEG$SYMBOL) %>% sort(decreasing=TRUE)

set.seed(123) #设置种子 好像不设置也没区别
msigdb_GMTs <- "msigdb_v7.0_GMTs"
#msigdb <- "h.all.v7.0.symbols.gmt" 
##Hallmark基因集（h.all）本身仅含50条通路,
#最后结果只有干扰素相关的两条通路
# 尝试其他基因集（如KEGG或免疫相关）
msigdb <- "c7.all.v7.0.symbols.gmt"  # 免疫基因集

#读取上面指定的gmt文件
kegmt <- read.gmt(file.path(msigdb_GMTs,msigdb))## SYMBOL版本

gsea <- GSEA(geneList, TERM2GENE = kegmt, pvalueCutoff = 0.05)
gsea_result_df <- as.data.frame(gsea)

write.csv(gsea@result, "GSEA_results_c7all.csv")


#单个图绘制
# library(enrichplot)
# gseaplot2(gsea,1,color="red",pvalue_table = T)#####0
#多个结果绘制
# gseaplot2(gsea, geneSetID = c(8,10,12), subplots = 1:3)
# gseaplot2(gsea, geneSetID = 1:3, subplots = 1:3)

#dev.off()


###########整合基因集
# 1. 定义要分析的基因集文件（SYMBOL版本）
msigdb_files <- c(
  "c2.all.v7.0.symbols.gmt",  # 所有C2通路（kegg）
  "c3.all.v7.0.symbols.gmt",  # 调控相关
  "c4.all.v7.0.symbols.gmt",  # 癌症基因模块
  "c5.all.v7.0.symbols.gmt",  # 所有GO术语
  "c7.all.v7.0.symbols.gmt"   # 免疫特征集
)

# 2. 批量运行GSEA（自动跳过缺失文件）
gsea_results <- map(msigdb_files, ~ {
  gmt_path <- file.path("msigdb_v7.0_GMTs", .x)
  if (file.exists(gmt_path)) {
    kegmt <- read.gmt(gmt_path)
    GSEA(geneList, TERM2GENE = kegmt, pvalueCutoff = 0.05)
  } else {
    warning(paste("File not found:", gmt_path))
    NULL
  }
}) %>% setNames(msigdb_files) %>% compact()  # 移除NULL结果

# 3. 整合所有结果（添加来源标记）
combined_results <- imap_dfr(gsea_results, ~ {
  .x@result %>% mutate(GeneSet_Source = .y)  # 添加来源列
})

# 4. 保存结果
write.csv(combined_results, "Combined_GSEA_Results.csv", row.names = FALSE)
save(gsea_results, combined_results, file = "All_GSEA_Results.rda")


#library(enrichplot)
dotplot(gsea_results$c7.all.v7.0.symbols.gmt, 
        showCategory=10, 
        title = "Top Immune Pathways (c7.all)")

dotplot(gsea_results$c3.all.v7.0.symbols.gmt, 
        showCategory=10, 
        title = "Top Regulation Pathways (c3.all)")

dotplot(gsea_results$c4.all.v7.0.symbols.gmt, 
        showCategory=10, 
        title = "Top Cancer Pathways (c4.all)")

#CDK、HDAC，PCNA和HMMR







#=================== ESTIMATE====================
setwd("..")
setwd("ESTIMATE")  #设置工作目录
#安装包
library(utils) 
# rforge <- "http://r-forge.r-project.org"
# install.packages("estimate", repos=rforge, dependencies=TRUE)
library(estimate)
library(tidyverse)

# 加载必要包
library(estimate)
tpm_data <- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_clinical_filtered.txt", row.names=1)
tpms_with_clinical<- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_with_clinical.txt", row.names=1)
# 将行名中的 "-" 替换为 "."
rownames(tpms_with_clinical) <- gsub("-", ".", rownames(tpms_with_clinical))

# 关键步骤：处理负值

# 方法1：对负值进行截断（推荐，保留相对差异）
# 将所有负值设为0（最常用，ESTIMATE包可接受）
tpm_non_negative <- pmax(tpm_data, 0)  # pmax函数将负值替换为0

# # 方法2：如果负值范围不大，可使用平移法（保留更多变异信息）
# shift_value <- min(tpm_data)  # 计算最小负值（如-5）
# tpm_non_negative <- tpm_data - shift_value  # 平移后最小值为0

# 转换为矩阵格式
exp <- as.matrix(tpm_non_negative)


if(!dir.exists("temp")) dir.create("temp")
write.table(exp, "temp/tpm_temp.txt", sep="\t", quote=F, col.names=NA)

# 过滤公共基因
filterCommonGenes(input.f = "temp/tpm_temp.txt", 
                  output.f = "temp/tpm_estimate_input.gct",
                  id = "GeneSymbol")  # 根据实际基因名类型选择

# 计算ESTIMATE评分（注意平台参数需与数据匹配）
estimateScore(input.ds = "temp/tpm_estimate_input.gct",
              output.ds = "tpm_estimate_scores.txt",
              platform = "illumina")  # RNA-seq数据推荐用"illumina"


#提取结果
ESTIMATE_result <- read.table("tpm_estimate_scores.txt",sep = "\t",row.names = 1,check.names = F,stringsAsFactors = F,header = T)
ESTIMATE_result <- ESTIMATE_result[,-1]   
colnames(ESTIMATE_result) <- ESTIMATE_result[1,]   
ESTIMATE_result <- as.data.frame(t(ESTIMATE_result[-1,]))
rownames(ESTIMATE_result) <- colnames(exp)
# 将评分列转换为数值型（关键：解决chr类型问题）
ESTIMATE_result[, c("StromalScore", "ImmuneScore", "ESTIMATEScore")] <- 
  apply(ESTIMATE_result[, c("StromalScore", "ImmuneScore", "ESTIMATEScore")], 
        2, as.numeric)
write.table(ESTIMATE_result, file = "ESTIMATE_result.txt",sep = "\t",row.names = T,col.names = NA,quote = F) 

#绘图
library(ggplot2)
library(ggpubr)

# 1. 数据预处理
# 提取样本ID和对应的group
sample_group <- data.frame(
  SampleID = rownames(tpms_with_clinical),  # 样本ID与exp列名一致
  group = tpms_with_clinical$group   # 分组信息（如"No_Metastasis"、"Metastasis"）
)

# 合并分组信息（按样本ID匹配）
ESTIMATE_result <- merge(
  ESTIMATE_result, 
  sample_group, 
  by.x = "row.names",  # ESTIMATE_result的行名是SampleID
  by.y = "SampleID"    # sample_group的列是SampleID
)

# 重置行名为SampleID（合并后会生成新列"Row.names"，需重命名）
rownames(ESTIMATE_result) <- ESTIMATE_result$Row.names
ESTIMATE_result$Row.names <- NULL  # 删除多余的Row.names列

group<-ESTIMATE_result$group
stopifnot(
  is.numeric(ESTIMATE_result$ImmuneScore),
  all(levels(ESTIMATE_result$group) == c("No_Metastasis", "Metastasis")),
  nrow(ESTIMATE_result) == length(group)
)


# 2. 主分析图
# 1. ImmuneScore 分布图
p_immune <- ggplot(ESTIMATE_result, aes(x=group, y=ImmuneScore)) +
  geom_violin(aes(fill=group), width=0.7, alpha=0.3, trim=FALSE) +
  geom_boxplot(aes(fill=group), width=0.2, outlier.shape=NA) +
  geom_jitter(aes(color=group), width=0.1, size=1.8, alpha=0.6) +
  scale_fill_manual(values=c("No_Metastasis"="steelblue", "Metastasis"="firebrick")) +
  scale_color_manual(values=c("No_Metastasis"="steelblue", "Metastasis"="firebrick")) +
  labs(title="Immune Score Distribution", 
       x="Clinical Response Group", 
       y="ESTIMATE Immune Score") +
  theme_minimal(base_size=14) +
  theme(legend.position="none",
        panel.grid.major.x=element_blank()) +
  stat_compare_means(
    comparisons=list(c("No_Metastasis", "Metastasis")),
    method="wilcox.test",
    label="p.format",
    label.y=max(ESTIMATE_result$ImmuneScore) * 1.05,  # 自动适应最大值
    size=5
  )

# 2. StromalScore 分布图
p_stromal <- ggplot(ESTIMATE_result, aes(x=group, y=StromalScore)) +
  geom_violin(aes(fill=group), width=0.7, alpha=0.3, trim=FALSE) +
  geom_boxplot(aes(fill=group), width=0.2, outlier.shape=NA) +
  geom_jitter(aes(color=group), width=0.1, size=1.8, alpha=0.6) +
  scale_fill_manual(values=c("No_Metastasis"="steelblue", "Metastasis"="firebrick")) +
  scale_color_manual(values=c("No_Metastasis"="steelblue", "Metastasis"="firebrick")) +
  labs(title="Stromal Score Distribution", 
       x="Clinical Response Group", 
       y="ESTIMATE Stromal Score") +
  theme_minimal(base_size=14) +
  theme(legend.position="none",
        panel.grid.major.x=element_blank()) +
  stat_compare_means(
    comparisons=list(c("No_Metastasis", "Metastasis")),
    method="wilcox.test",
    label="p.format",
    label.y=max(ESTIMATE_result$StromalScore) * 1.05,  # 自动适应最大值
    size=5
  )

# 3. ESTIMATEScore 分布图
p_estimate <- ggplot(ESTIMATE_result, aes(x=group, y=ESTIMATEScore)) +
  geom_violin(aes(fill=group), width=0.7, alpha=0.3, trim=FALSE) +
  geom_boxplot(aes(fill=group), width=0.2, outlier.shape=NA) +
  geom_jitter(aes(color=group), width=0.1, size=1.8, alpha=0.6) +
  scale_fill_manual(values=c("No_Metastasis"="steelblue", "Metastasis"="firebrick")) +
  scale_color_manual(values=c("No_Metastasis"="steelblue", "Metastasis"="firebrick")) +
  labs(title="ESTIMATE Score Distribution", 
       x="Clinical Response Group", 
       y="Combined ESTIMATE Score") +
  theme_minimal(base_size=14) +
  theme(legend.position="none",
        panel.grid.major.x=element_blank()) +
  stat_compare_means(
    comparisons=list(c("No_Metastasis", "Metastasis")),
    method="wilcox.test",
    label="p.format",
    label.y=max(ESTIMATE_result$ESTIMATEScore) * 1.05,  # 自动适应最大值
    size=5
  )

# 输出所有图形
print(p_immune)
print(p_stromal)
print(p_estimate)

# 保存图形（可选，分别保存）
ggsave("Immune_Score_Distribution.pdf", p_immune, width=8, height=6, dpi=300)
ggsave("Stromal_Score_Distribution.pdf", p_stromal, width=8, height=6, dpi=300)
ggsave("ESTIMATE_Score_Distribution.pdf", p_estimate, width=8, height=6, dpi=300)

# 也可以组合成一个图输出（方便对比）
library(patchwork)
combined_plot <- p_immune + p_stromal + p_estimate + 
  plot_annotation(title="ESTIMATE Scores by Clinical Response")
print(combined_plot)
ggsave("Combined_ESTIMATE_Scores.pdf", combined_plot, width=18, height=6, dpi=300)


########基质的有用









####药物敏感性分析#######
setwd("..")
setwd("IC50")
#函数定义
get_oncoPredict_res <- function(data = data,
                                traData = c('GDSC2', 'GDSC1', 'CTRP2')[1],
                                minNumSamples = 10) {
  library(oncoPredict)
  
  data <- as.matrix(data)
  if (traData == 'GDSC2') {
    traDataExp <- readRDS("Training Data/GDSC2_Expr (RMA Normalized and Log Transformed).rds")
    traDataRes <- readRDS(file = "Training Data/GDSC2_Res.rds")
  } else if (traData == 'GDSC1') {
    traDataExp <- readRDS("Training Data/GDSC1_Expr (RMA Normalized and Log Transformed).rds")
    traDataRes <- readRDS(file = "Training Data/GDSC1_Res.rds")
  } else if (traData == 'CTRP2') {
    traDataExp <- readRDS("Training Data/CTRP2_Expr (TPM, not log transformed).rds")
    traDataExp <- log2(traDataExp + 1)
    traDataRes <- readRDS(file = "Training Data/CTRP2_Res.rds")
  } else {
    stop('请检查 traData 是否正确, 仅支持GDSC2, GDSC1, CTRP2 三种')
  }
  
  calcPhenotype(trainingExprData = traDataExp,
                trainingPtype = traDataRes,
                testExprData = data,
                batchCorrect = 'eb',  #   "eb" for ComBat  
                powerTransformPhenotype = TRUE,
                removeLowVaryingGenes = 0.2,
                minNumSamples = minNumSamples, 
                printOutput = TRUE, 
                removeLowVaringGenesFrom = 'rawData')
}
# 读取表达谱数据
tpm_data <- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_clinical_filtered.txt", row.names=1)
dat_exp <- tpm_data
#药物敏感性预测
#GDSC2
GDSC2 <- get_oncoPredict_res(data = dat_exp,traData = 'GDSC2')
#GDSC1
GDSC1 <- get_oncoPredict_res(data = dat_exp,traData = 'GDSC1')
# CTRP2
CTRP2 <- get_oncoPredict_res(data = dat_exp,traData = 'CTRP2')

#setwd("calcPhenotype_Output")
tpms_with_clinical<- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_with_clinical.txt", row.names=1)
####分析结果
DrugPredictions <- read.csv("~/Bulk-RNA/TCGA-BLCA/IC50/calcPhenotype_Output/DrugPredictions.csv", row.names=1)
#tpm<- read.table("tpms01A_log2.txt",sep = "\t",row.names = 1,check.names = F,stringsAsFactors = F,header = T)

all_drugs <- colnames(DrugPredictions)
# 已知的mTOR抑制剂列表（可再补充）
mTOR_drugs <- grep("m.?tor|rapamycin|everolimus|temsirolimus|sirolimus", 
                   all_drugs, ignore.case = TRUE, value = TRUE)
print(mTOR_drugs)
#mTOR_drugs_extended <- grep("m.?tor|rapamycin|everolimus|temsirolimus|sirolimus|
#ridaforolimus|deforolimus|umlioralimus|zosuquidar", 
#all_drugs, ignore.case = TRUE, value = TRUE)
identical(rownames(DrugPredictions), colnames(tpm_data))
#FALSE
####mTOR####
mTOR_data <- cbind(DrugPredictions[, mTOR_drugs, drop = FALSE], 
                   group = tpms_with_clinical$group[match(rownames(DrugPredictions),colnames(tpm_data))])


# 确保group是因子且水平正确
mTOR_data$group <- factor(mTOR_data$group,levels = c("No_Metastasis", "Metastasis"))

# 循环绘图，显示具体p值
for (drug_name in mTOR_drugs) {
  p <- ggboxplot(mTOR_data,
                 x = "group", y = drug_name,
                 fill = "group",
                 title = drug_name) +
    scale_fill_lancet() +
    stat_compare_means(comparisons = list(c("No_Metastasis", "Metastasis")),
                       method = "wilcox.test",
                       symnum.args = list(cutpoints = c(0, 0.001, 0.01, 0.05, 1),
                                          symbols = c("***", "**", "*", "ns")),
                       label = "p.format")  # 显示具体p值
  
  print(p)
  #ggsave(paste0(drug_name, "_pvalue.pdf"), p, width = 6, height = 5)
}
library(gridExtra)
ggsave("mTOR_drugs_combined.pdf", grid.arrange(grobs = lapply(mTOR_drugs, function(drug) ggboxplot(mTOR_data, x="group", y=drug, fill="group", title=drug) 
                                                              + scale_fill_lancet() + stat_compare_means(comparisons=list(c("No_Metastasis","Metastasis")), method="wilcox.test", label="p.format")), 
                                               ncol=1), width=8, height=6*length(mTOR_drugs))

# 
# for (drug_name in mTOR_drugs) {
#   p <- ggboxplot(mTOR_data,
#                  x = "group", y = drug_name,
#                  fill = "group",
#                  title = drug_name) +
#     scale_fill_lancet() +
#     stat_compare_means(comparisons = list(c("No_Metastasis", "Metastasis")),
#                        method = "wilcox.test",
#                        label = "p.format")  # 显示具体p值，而不是符号
#   
#   print(p)
#   # ggsave(paste0(drug_name, "_pvalue.pdf"), p, width = 6, height = 5)
# }

# ----------THBS1---------------------

# 读取药敏数据
DrugPredictions <- read.csv("~/Bulk-RNA/TCGA-BLCA/IC50/calcPhenotype_Output/DrugPredictions.csv", row.names=1)

# 根据图片信息和您的药物列表，筛选THBS1/TGF-β相关药物
# 从您的药物列表中查找相关药物

# 1. THBS1/CD47相关药物
thbs1_drugs <- c()
# 查找ABT系列药物 (ABT-510, ABT-898)
abt_drugs <- grep("ABT", all_drugs, value = TRUE)
thbs1_drugs <- c(thbs1_drugs, abt_drugs)

# 查找CD47相关药物 (Magrolimab)
cd47_drugs <- grep("CD47|Magrol", all_drugs, ignore.case = TRUE, value = TRUE)
thbs1_drugs <- c(thbs1_drugs, cd47_drugs)

# 2. TGF-β通路抑制剂
tgf_drugs <- c()
# Galunisertib (TGF-β受体激酶抑制剂)
galunisertib <- grep("Galun", all_drugs, ignore.case = TRUE, value = TRUE)
tgf_drugs <- c(tgf_drugs, galunisertib)

# Vactosertib (TGF-β受体激酶抑制剂)
vactosertib <- grep("Vacto", all_drugs, ignore.case = TRUE, value = TRUE)
tgf_drugs <- c(tgf_drugs, vactosertib)

# Fresolimumab (TGF-β中和抗体)
fresolimumab <- grep("Fresoli", all_drugs, ignore.case = TRUE, value = TRUE)
tgf_drugs <- c(tgf_drugs, fresolimumab)

# SRK-181 (TGF-β抗体)
srk_drugs <- grep("SRK", all_drugs, value = TRUE)
tgf_drugs <- c(tgf_drugs, srk_drugs)

# Sotatercept (TGF-β陷阱分子)
sotatercept <- grep("Sotater", all_drugs, ignore.case = TRUE, value = TRUE)
tgf_drugs <- c(tgf_drugs, sotatercept)

# 其他TGF-β相关药物
other_tgf <- grep("TGF", all_drugs, ignore.case = TRUE, value = TRUE)
tgf_drugs <- c(tgf_drugs, other_tgf)

# 合并所有找到的药物
thbs1_related_drugs <- unique(c(thbs1_drugs, tgf_drugs))

print("找到的THBS1/TGF-β相关药物：")
print(thbs1_related_drugs)

# 检查是否找到药物
if (length(thbs1_related_drugs) == 0) {
  # 如果没有找到精确匹配，查找可能的相关药物
  # TGF-β通路相关的小分子抑制剂
  potential_tgf_drugs <- c("SB.431542", "LY.2157299")  # 已知的TGF-β抑制剂
  thbs1_related_drugs <- intersect(potential_tgf_drugs, all_drugs)
  
  if (length(thbs1_related_drugs) > 0) {
    print("使用已知的TGF-β通路抑制剂：")
    print(thbs1_related_drugs)
  } else {
    stop("未找到THBS1/TGF-β相关药物，请手动选择")
  }
}

# 继续进行分析
identical(rownames(DrugPredictions), colnames(tpm_data))

# 创建分析数据框
thbs1_data <- cbind(DrugPredictions[, thbs1_related_drugs, drop = FALSE], 
                    group = tpms_with_clinical$group[match(rownames(DrugPredictions), colnames(tpm_data))])

# 确保分组正确
thbs1_data$group <- factor(thbs1_data$group, levels = c("No_Metastasis", "Metastasis"))

# 加载必要包
library(ggpubr)
library(ggplot2)
library(gridExtra)

# 绘制箱线图
for (drug_name in thbs1_related_drugs) {
  p <- ggboxplot(thbs1_data,
                 x = "group", 
                 y = drug_name,
                 fill = "group",
                 palette = "lancet",
                 title = paste("Drug Sensitivity:", drug_name),
                 xlab = "Group",
                 ylab = "Predicted IC50") +
    stat_compare_means(comparisons = list(c("No_Metastasis", "Metastasis")),
                       method = "wilcox.test",
                       label = "p.format")
  
  print(p)
}

# 保存组合图
if (length(thbs1_related_drugs) > 0) {
  plot_list <- lapply(thbs1_related_drugs, function(drug) {
    ggboxplot(thbs1_data, 
              x = "group", 
              y = drug, 
              fill = "group",
              palette = "lancet",
              title = drug) +
      stat_compare_means(comparisons = list(c("No_Metastasis", "Metastasis")), 
                         method = "wilcox.test", 
                         label = "p.format")
  })
  
  n_cols <- min(2, length(plot_list))
  combined_plot <- grid.arrange(grobs = plot_list, ncol = n_cols)
  
  ggsave("THBS1_TGFb_related_drugs_sensitivity.pdf", 
         plot = combined_plot, 
         width = 8, 
         height = 4 * ceiling(length(plot_list)/n_cols))
}








# ----------HER2---------------------
# 1. 筛选 HER2 ADC 类药物
her2_adc_keywords <- "her2|trastuzumab emtansine|t-dm1|trastuzumab deruxtecan|t-dxd|disitamab vedotin|rc48|arx788|syd985|her2 adc|ado-trastuzumab emtansine|ds-8201"

her2_adc_drugs <- grep(her2_adc_keywords, 
                       all_drugs, 
                       ignore.case = TRUE, 
                       value = TRUE)

print("筛选出的 HER2 ADC 类药物有：")
print(her2_adc_drugs)
#character(0)
##非ADC类
her2_tki_keywords <- "lapatinib|neratinib|afatinib|trastuzumab"  # 拉帕替尼、来那替尼、阿法替尼、赫赛汀（单抗，不是ADC但可参考）
her2_tki_drugs <- grep(her2_tki_keywords, all_drugs, ignore.case = TRUE, value = TRUE)
print(her2_tki_drugs)

#"neratinib" "afatinib"  "lapatinib"



her2_tki_data <- cbind(
  DrugPredictions[, her2_tki_drugs, drop = FALSE], 
  group = tpms_with_clinical$group[match(rownames(DrugPredictions),colnames(tpm_data))])

# 确保 group 是因子，且水平是 No_Metastasis 在前，Metastasis 在后
her2_tki_data$group <- factor(her2_tki_data$group, levels = c("No_Metastasis", "Metastasis"))

# 检查数据结构（可选）
# str(her2_tki_data)
head(her2_tki_data)

# ：每个 HER2-TKI 药物的箱线图 + 统计检验（Wilcox 检验）
for (drug_name in her2_tki_drugs) {
  if (!drug_name %in% colnames(her2_tki_data)) next  # 避免列名找不到报错
  
  p <- ggboxplot(her2_tki_data,
                 x = "group", y = drug_name,
                 fill = "group",
                 title = drug_name) +
    scale_fill_lancet() +
    stat_compare_means(
      comparisons = list(c("No_Metastasis", "Metastasis")),
      method = "wilcox.test",
      symnum.args = list(
        cutpoints = c(0, 0.001, 0.01, 0.05, 1),
        symbols = c("***", "**", "*", "ns")
      ),
      label = "p.format"  # 显示具体 p 值，如 0.001 -> ***
    )
  
  print(p)
  
  # 可选：保存单图
  # ggsave(paste0("HER2_TKI_", drug_name, "_sensitivity.pdf"), p, width = 6, height = 5)
}


# 4. （可选）把所有 HER2-TKI 药物画在一张大图

if (length(her2_tki_drugs) > 0) {
  plots <- lapply(her2_tki_drugs, function(drug) {
    ggboxplot(her2_tki_data, x = "group", y = drug, fill = "group", title = drug) +
      scale_fill_lancet() +
      stat_compare_means(
        comparisons = list(c("No_Metastasis", "Metastasis")),
        method = "wilcox.test",
        symnum.args = list(cutpoints = c(0, 0.001, 0.01, 0.05, 1),
                           symbols = c("***", "**", "*", "ns")),
        label = "p.format"
      )
  })
  
  combined_plot <- grid.arrange(grobs = plots, ncol = 1)
  ggsave("HER2_TKI_Drugs_Sensitivity_Combined.pdf", 
         combined_plot, 
         width = 8, 
         height = 6 * length(her2_tki_drugs))  # 高度根据药物数量自适应
} else {
  cat("⚠️ 未找到 HER2-TKI 药物，请检查 all_drugs。\n")
}


##her2全是ns


#=================== WGCNA1 ====================
#全过程不要清空文件
#BiocManager::install("preprocessCore")
#BiocManager::install("impute")
#install.packages("WGCNA")
library("tidyverse")
library("WGCNA")  
setwd("..")
setwd("WGCNA")
#导入差异基因文件
#选取用于分析的基因
load("~/Bulk-RNA/TCGA-BLCA/DEG/DEG_Metastasis_Rel.Rda")

# 重新构建，把SYMBOL放回行名
DEG_new <- as.data.frame(res) %>%
  rownames_to_column("SYMBOL") %>%
  dplyr::filter(abs(log2FoldChange) > 0.5, padj < 0.05)

# 【关键】把基因Symbol设置为行名，保证和tpm矩阵匹配
DEG_final <- DEG_new %>% column_to_rownames("SYMBOL")

# 现在再验证基因是否存在


DEG <- DEG_final 
c("THBS1" %in% rownames(DEG), "TGFB3" %in% rownames(DEG))

tpm_data <- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_clinical_filtered.txt", row.names=1)
exp <- tpm_data
# 清除首尾所有空白、隐藏不可见字符
rownames(DEG) <- trimws(rownames(DEG))
rownames(tpm_data) <- trimws(rownames(tpm_data))

# 改用intersect做交集，规避%in%的字符bug
common_genes <- intersect(rownames(DEG), rownames(tpm_data))

# 立刻核验
c("THBS1" %in% common_genes, "TGFB3" %in% common_genes)
# 找出 DEG 中的基因名（即 DEG 的行名），且在 exp 的行名中也存在
#common_genes <- rownames(exp)[rownames(DEG) %in% rownames(exp)]

# 然后根据这些共同的基因名，从 exp 中提取对应的行
input <- exp[common_genes, ]
#input <- exp  #如果需要分析全部基因

#保证样本在行，基因在列 很重要！！！！
datExpr0 = as.data.frame(t(input)) 
#检查缺失值
gsg = goodSamplesGenes(datExpr0, verbose = 3)
gsg$allOK
# #如果没有达标就需要筛选
# if (!gsg$allOK){
#   # Optionally, print the gene and sample names that were removed:
#   if (sum(!gsg$goodGenes)>0) 
#     printFlush(paste("Removing genes:", paste(names(datExpr0)[!gsg$goodGenes], collapse = ", ")));
#   if (sum(!gsg$goodSamples)>0) 
#     printFlush(paste("Removing samples:", paste(rownames(datExpr0)[!gsg$goodSamples], collapse = ", ")));
#   # Remove the offending genes and samples from the data:
#   datExpr0 = datExpr0[gsg$goodSamples, gsg$goodGenes]
# }
if (!gsg$allOK){
  # 只剔除不合格样本，【保留所有基因，不再删除任何基因】
  if (sum(!gsg$goodSamples)>0) 
    printFlush(paste("Removing samples:", paste(rownames(datExpr0)[!gsg$goodSamples], collapse = ", ")));
  
  # 关键改动：只筛选样本，基因一列全部保留
  datExpr0 = datExpr0[gsg$goodSamples, ]
}
####样本聚类 去除离群样本
#只需要改两处剪切线的高度
# 聚类
sampleTree = hclust(dist(datExpr0), method = "average")
# 画图（样本的聚类树）
par(cex = 0.6)
par(mar = c(0,4,2,0))
plot(sampleTree)
plot(sampleTree, main = "Sample clustering to detect outliers", sub="", xlab="", cex.lab = 1.5, cex.axis = 1.5, cex.main = 2)
###剪切线
abline(h = 150, col = "red")  #主观选择剪切线的高度
###删除剪切线以上的样品
clust = cutreeStatic(sampleTree, cutHeight = 150, minSize = 10) # cutHeight 数字同上
table(clust)#以此选出分组
# clust
# 0  1  2  3  4 
# 48 69 27 24 15 
keepSamples = (clust==1)#要数量最多的组
datExpr0 = datExpr0[keepSamples, ] #注意这里datExpr0发生了变化
dev.off()
# 重新聚类
sampleTree2 = hclust(dist(datExpr0), method = "average")
plot(sampleTree2)
dev.off()
# 记录基因和样本数 保存表达谱
nGenes = ncol(datExpr0)#基因数
nSamples = nrow(datExpr0)#样本数
save(datExpr0, nGenes, nSamples,file = "Step01-WGCNA_input.Rda")

####选择最佳power值（软阈值选择）
#只需要改最佳power值
#选择适合的软阈值power值，确保网络同时满足无标度特性和合理的连通性
enableWGCNAThreads()   #多线程工作，加快计算速度
powers = c(1:20)       #幂指数范围1:20
sft = pickSoftThreshold(datExpr0, powerVector = powers, verbose = 5)

par(mfrow = c(1,2))
cex1 = 0.8
###拟合指数与power值散点图，通常R²接近1更好
plot(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     xlab="Soft Threshold (power)",ylab="Scale Free Topology Model Fit,signed R^2",type="n",
     main = paste("Scale independence"));
text(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
     labels=powers,cex=cex1,col="red");
abline(h=0.80,col="red") #可以修改 ，此处阈值选了0.9
###平均连通性与power值散点图
plot(sft$fitIndices[,1], sft$fitIndices[,6],
     xlab="Soft Threshold (power)",ylab="Mean Connectivity", type="n",
     main = paste("Mean connectivity"))
text(sft$fitIndices[,1], sft$fitIndices[,6], labels=powers, cex=cex1,col="red")
#保存图片
#dev.off()
#邻接矩阵转换
sft #查看最佳power值
softPower =sft$powerEstimate #最佳power值，显示8
#softPower =8 #更改
adjacency = adjacency(datExpr0, power = softPower)

#TOM矩阵
TOM = TOMsimilarity(adjacency)
dissTOM = 1-TOM
save(TOM,file = "TOM.Rda")




####基因聚
#不需要改，几个颜色就是几个模块
geneTree = hclust(as.dist(dissTOM), method = "average");
plot(geneTree, xlab="", sub="", main = "Gene clustering on TOM-based dissimilarity",
     labels = FALSE, hang = 0.04)

# 动态剪切模块识别
minModuleSize = 30      #模块基因数目
dynamicMods = cutreeDynamic(dendro = geneTree, distM = dissTOM,
                            deepSplit = 2, pamRespectsDendro = FALSE,
                            minClusterSize = minModuleSize);
table(dynamicMods)

dynamicColors = labels2colors(dynamicMods)
table(dynamicColors)

plotDendroAndColors(geneTree, dynamicColors, "Dynamic Tree Cut",
                    dendroLabels = FALSE, hang = 0.03,
                    addGuide = TRUE, guideHang = 0.05,
                    main = "Gene dendrogram and module colors")
#dev.off()
# 

MEList = moduleEigengenes(datExpr0, colors = dynamicColors)
MEs = MEList$eigengenes
MEDiss = 1-cor(MEs);
METree = hclust(as.dist(MEDiss), method = "average")
plot(METree, main = "Clustering of module eigengenes",
     xlab = "", sub = "")
#保存图片
##以下两句根据情况，看聚类图有没有离得近的进行合并
MEDissThres = 0.25#剪切高度可修改，这里什么都没有切到，7类都比较分散
abline(h=MEDissThres, col = "red")
# #相似模块合并
# merge = mergeCloseModules(datExpr0, dynamicColors, cutHeight = MEDissThres, verbose = 3)
# mergedColors = merge$colors
# mergedMEs = merge$newMEs
# plotDendroAndColors(geneTree, mergedColors,"Dynamic Tree Cut",
#                     dendroLabels = FALSE, hang = 0.03,
#                     addGuide = TRUE, guideHang = 0.05,
#                     main = "Gene dendrogram and module colors")

# moduleColors = mergedColors
# table(moduleColors)
# colorOrder = c("grey", standardColors(50))
# moduleLabels = match(moduleColors, colorOrder)-1
# MEs = mergedMEs
# #dev.off()

####与性状做相关性分析
# 导入所需的免疫评分或其他文件 根据需要来。这部分只需要改这个文件
#比如ESTIMATE_result.txt 就可以找出免疫、基质、纯度等相关的基因组别，
#ciber可以找到22种免疫细胞各自相关的基因组别
ESTIMATE_result <- read.delim("~/Bulk-RNA/TCGA-BLCA/ESTIMATE/ESTIMATE_result.txt", row.names=1)
ESTIMATE = ESTIMATE_result
# 将行名中的 "-" 替换为 "."
rownames(ESTIMATE) <- gsub("-", ".", rownames(ESTIMATE))
#ESTIMATE <- read.table("ESTIMATE_result.txt",sep = "\t",row.names = 1,check.names = F,stringsAsFactors = F,header = T)
ESTIMATE <- ESTIMATE[rownames(datExpr0),]
identical(rownames(ESTIMATE),rownames(datExpr0))
# 查看ESTIMATE信息
head(ESTIMATE)
#样本必须在行
# 对表达矩阵进行预处理
datTraits = as.data.frame(do.call(cbind,lapply(ESTIMATE, as.numeric)))
rownames(datTraits) = rownames(ESTIMATE)

# 对样本进行聚类
sampleTree2 = hclust(dist(datExpr0), method = "average")

# 将ESTIMATE信息转换为颜色，白色表示低，红色表示高，灰色表示缺失
traitColors = numbers2colors(datTraits, signed = FALSE)

# 
plotDendroAndColors(sampleTree2, 
                    traitColors,
                    groupLabels = names(datTraits), 
                    main = "Sample dendrogram and trait heatmap")
#保存图片

#dev.off()

##网络的分析
# 对模块特征矩阵进行排序
MEs=orderMEs(MEs)
#计算模型特征矩阵和样本信息矩阵的相关度。
moduleTraitCor=cor(MEs, datTraits, use="p")
write.table(file="Step04-modPhysiological.cor.xls",moduleTraitCor,sep="\t",quote=F)
moduleTraitPvalue=corPvalueStudent(moduleTraitCor, nSamples)
write.table(file="Step04-modPhysiological.p.xls",moduleTraitPvalue,sep="\t",quote=F)

#使用labeledHeatmap()将上述相关矩阵和p值可视化。
textMatrix=paste(signif(moduleTraitCor,2),"\n(",signif(moduleTraitPvalue,1),")",sep="")
dim(textMatrix)=dim(moduleTraitCor)
# 基因模块与免疫评分信息相关性图
labeledHeatmap(Matrix=moduleTraitCor,#模块和表型的相关性矩阵，这个参数最重要，其他可以不变
               xLabels=colnames(datTraits),
               yLabels=names(MEs),
               ySymbols=names(MEs),
               colorLabels=FALSE,
               colors=blueWhiteRed(50),
               textMatrix=textMatrix,
               setStdMargins=FALSE,
               cex.text=0.7,
               cex.lab=0.7,
               zlim=c(-1,1),
               main=paste("Module-trait Metastasisationships"))
#这是最终结果 保存图片。现在的这张图提示选turquoise 
dynamicColors
# blue     brown      grey turquoise    yellow 
# 165       130         3       362        87 
#dev.off()
# ==========================================
# WGCNA 后续模块与基因性状关联分析优化版
# ==========================================

library(dplyr)
library(WGCNA)
library(tibble)

# ------------------------------------------
# 1. 基础矩阵计算与规范化命名
# ------------------------------------------
modNames <- substring(names(MEs), 3)

# 计算 Module Membership (MM) 
geneModuleMembership_raw <- as.data.frame(cor(datExpr0, MEs, use = "p"))
MMPvalue_raw <- as.data.frame(corPvalueStudent(as.matrix(geneModuleMembership_raw), nSamples))

# 规范化 MM 矩阵的列名
names(geneModuleMembership_raw) <- paste0("MM", modNames)
names(MMPvalue_raw) <- paste0("p.MM", modNames)

# 计算 Gene Significance (GS)
traitNames <- names(datTraits)
geneTraitSignificance_raw <- as.data.frame(cor(datExpr0, datTraits, use = "p"))
GSPvalue_raw <- as.data.frame(corPvalueStudent(as.matrix(geneTraitSignificance_raw), nSamples))

# 规范化 GS 矩阵的列名
names(geneTraitSignificance_raw) <- paste0("GS.", traitNames)
names(GSPvalue_raw) <- paste0("p.GS.", traitNames)

# 【核心改进】立即将行名转换为明确的“gene_symbol”列，避免被 dplyr 误删
geneModuleMembership <- geneModuleMembership_raw %>% rownames_to_column("gene_symbol")
MMPvalue <- MMPvalue_raw %>% rownames_to_column("gene_symbol")
geneTraitSignificance <- geneTraitSignificance_raw %>% rownames_to_column("gene_symbol")
GSPvalue <- GSPvalue_raw %>% rownames_to_column("gene_symbol")

# ------------------------------------------
# 2. 批量输出性状和模块散点图 (安全遍历版)
# ------------------------------------------
# 创建存放 PDF 的目录，避免污染当前工作空间
dir.create("MM_GS_plots", showWarnings = FALSE)

for (trait in traitNames) {
  # 精确构建当前的 GS 列名
  target_gs_col <- paste0("GS.", trait)
  
  for (module in modNames) {
    # 精确构建当前的 MM 列名
    target_mm_col <- paste0("MM", module)
    
    # 提取属于当前模块的基因
    moduleGenes <- (moduleColors == module)
    
    # 健壮性检查：确保列名存在且模块内有基因
    if (target_mm_col %in% colnames(geneModuleMembership_raw) && 
        target_gs_col %in% colnames(geneTraitSignificance_raw) && 
        sum(moduleGenes) > 1) {
      
      outPdf <- file.path("MM_GS_plots", paste0(trait, "_", module, ".pdf"))
      pdf(file = outPdf, width = 7, height = 7)
      par(mfrow = c(1, 1))
      
      # 使用准确的列名字符串进行提取，拒绝使用易错的数字索引
      verboseScatterplot(
        abs(geneModuleMembership_raw[moduleGenes, target_mm_col]),
        abs(geneTraitSignificance_raw[moduleGenes, target_gs_col]),
        xlab = paste("Module Membership in", module, "module"),
        ylab = paste("Gene significance for", trait),
        main = paste("Module membership vs. gene significance\n"),
        cex.main = 1.2, cex.lab = 1.2, cex.axis = 1.2, 
        col = module
      )
      # 绘制阈值线
      abline(v = 0.8, h = 0.6, col = "red", lty = 2) 
      dev.off()
    }
  }
}

# ------------------------------------------
# 3. 安全输出每个模块的基因列表
# ------------------------------------------
dir.create("Module_Genes", showWarnings = FALSE)
probes <- colnames(datExpr0)

for (modules in unique(moduleColors)) {
  inModule <- (moduleColors == modules)
  modGenes <- probes[inModule]
  
  write.table(
    modGenes, 
    file = file.path("Module_Genes", paste0(modules, ".txt")),
    sep = "\t", row.names = FALSE, col.names = FALSE, quote = FALSE
  )
}

# ------------------------------------------
# 4. 目标模块 (以 turquoise 模块为例) 核心基因安全提取
# ------------------------------------------
# 读取目标模块基因列表
turquoise_txt_path <- "~/Bulk-RNA/TCGA-BLCA/WGCNA/Module_Genes/turquoise.txt"

if (!file.exists(turquoise_txt_path)) {
  stop("未找到目标 turquoise.txt 文件，请检查路径是否正确！")
}

turquoise_genes_raw <- read.table(turquoise_txt_path, header = FALSE, stringsAsFactors = FALSE)$V1
cat("从黑框文本中共读取到：", length(turquoise_genes_raw), "个原始基因。\n")

# 【核心改进】安全交集：只保留同时存在于表达矩阵和txt文件中的基因，防止引入 NA 行
turquoise_module_genes <- intersect(turquoise_genes_raw, geneModuleMembership$gene_symbol)
cat("过滤后，共有", length(turquoise_module_genes), "个基因匹配进入下一步分析。\n")

# 指定你关心的特定免疫性状列名
target_trait_gs_col <- "GS.ImmuneScore" 

# 检查该列名是否存在于矩阵中
if (!target_trait_gs_col %in% colnames(geneTraitSignificance)) {
  cat("\n【错误提示】未找到指定列名：", target_trait_gs_col, "\n当前可用的GS列名如下：\n")
  print(colnames(geneTraitSignificance %>% select(-gene_symbol)))
  stop("请从上方打印出的可用列名中选择正确的名称替换到代码中！")
}

# 使用 Tidyverse 管道进行无损连接与筛选
wgcna_turquoise_module <- geneModuleMembership %>%
  filter(gene_symbol %in% turquoise_module_genes) %>%
  select(gene_symbol, MM = .data$MMturquoise) %>% # .data 确保动态安全引用
  inner_join(
    geneTraitSignificance %>% 
      filter(gene_symbol %in% turquoise_module_genes) %>% 
      select(gene_symbol, GS = all_of(target_trait_gs_col)),
    by = "gene_symbol"
  ) %>%
  filter(!is.na(MM) & !is.na(GS))

# 导出完整的整合文件
dir.create("result", showWarnings = FALSE)
output_file <- "result/wgcna_turquoise_module_st.csv"
write.csv(wgcna_turquoise_module, output_file, row.names = FALSE, fileEncoding = "UTF-8")
cat("\n整合文件已安全保存至：", output_file, "\n")

# ------------------------------------------
# 5. 关键 Hub 基因高标准筛选 (MM > 0.8 & GS > 0.6)
# ------------------------------------------
key_turquoise_genes <- wgcna_turquoise_module %>%
  filter(abs(MM) > 0.8 & abs(GS) > 0.5)

key_turquoise_genes
# gene_symbol        MM        GS
# 1        TIMP2 0.8937112 0.5446820
# 2         MSR1 0.8200986 0.7045966
# 3          TNC 0.8484566 0.5491270
# 4       CYBRD1 0.8277117 0.5214846
# 5       CCDC80 0.8819355 0.5924824
# 6     CRISPLD2 0.8291101 0.5061000
# 7        AEBP1 0.8517682 0.5966275
# 8          LOX 0.8770911 0.5211905
# 9         NRP2 0.8871291 0.5042470
# 10       TGFB3 0.8631455 0.5467560
# 11        FMOD 0.8160315 0.5208205
# 12       CALD1 0.9147508 0.5336985
# 13     TNFAIP6 0.8465101 0.5810171
# 14       GFPT2 0.8205987 0.5647891
# 15       THBS1 0.8038673 0.5192851
# 16     EMILIN1 0.8178732 0.5606843
# 17      COL6A1 0.8521830 0.5748521
# 18      COL6A2 0.8801005 0.6118499
# 直接精准检索目标基因
wgcna_turquoise_module %>%
  filter(gene_symbol %in% c("THBS1", "TGFB3"))

# gene_symbol        MM        GS
# 1       TGFB3 0.8631455 0.5467560
# 2       THBS1 0.8038673 0.5192851










#=================== WGCNA2====================
# 步骤2：选择与“复发状态”最相关的性状（示例：若你关注StromalScore，列名是GS.StromalScore）
# ！！！请根据你的实际分析目标修改此处的GS列名（如GS.ImmuneScore、GS.ESTIMATEScore等）
target_trait_gs_col <- "GS.ImmuneScore"

# 步骤3：提取绿色模块基因的GS值
gs_turquoise <- geneTraitSignificance %>%
  rownames_to_column("gene_symbol") %>%
  filter(gene_symbol %in% turquoise_module_genes) %>% # 仅保留绿色模块基因
  select(gene_symbol, GS = all_of(target_trait_gs_col)) # 提取目标性状的GS值

# 检查是否成功提取GS值
if (nrow(gs_turquoise) == 0) {
  stop(paste("未找到", target_trait_gs_col, "列！请运行'colnames(geneTraitSignificance)'确认正确的GS列名"))
}


# ===================== 4. 合并MM和GS，生成最终文件 
# 合并MM和GS（按基因名匹配）
wgcna_turquoise_module <- mm_turquoise %>%
  inner_join(gs_turquoise, by = "gene_symbol") %>% # 确保基因同时有MM和GS值
  filter(!is.na(MM) & !is.na(GS)) # 去除缺失值（极少出现）

# 查看结果概况
cat("\n最终绿色模块基因（含MM/GS值）数量：", nrow(wgcna_turquoise_module), "\n")
cat("MM值范围：", round(min(wgcna_turquoise_module$MM), 3), "~", round(max(wgcna_turquoise_module$MM), 3), "\n")
cat(target_trait_gs_col, "值范围：", round(min(wgcna_turquoise_module$GS), 3), "~", round(max(wgcna_turquoise_module$GS), 3), "\n")

# 保存为wgcna_turquoise_module.csv（与后续整合分析代码兼容）
write.csv(wgcna_turquoise_module, "wgcna_turquoise_module.csv", row.names = FALSE, fileEncoding = "UTF-8")
cat("\n已生成wgcna_turquoise_module.csv，路径：", getwd(), "\n")


# ===================== 5. 可选：验证MM/GS筛选的关键基因
# 按你前期代码中的筛选阈值（MMturquoise>0.8且GS.StromalScore>0.6）筛选关键基因
key_turquoise_genes <- wgcna_turquoise_module %>%
  filter(MM > 0.7 & GS > 0.5)  # 更宽松，免疫相关候选池更大

cat("\n按MM > 0.7 & GS > 0.5筛选的关键基因数量：", nrow(key_turquoise_genes), "\n")
if (nrow(key_turquoise_genes) > 0) {
  cat("前10个关键基因：\n")
  print(head(key_turquoise_genes, 10))
} else {
  warning("未筛选到满足MM > 0.7 & GS > 0.5的基因，可适当降低阈值（如MM>0.7或GS>0.5）")
}


####前10个关键基因：
# gene_symbol        MM        GS
# 1     TMEM176A 0.8592904 0.7513777
# 2        IFFO1 0.9001514 0.6471726
# 3        STAB1 0.7298659 0.6161775
# 4          BTK 0.8842660 0.7898959
# 5         MRC2 0.7740897 0.6339875
# 6        ANOS1 0.7503497 0.5129453
# 7          DCN 0.9110999 0.6029257
# 8       TYROBP 0.7925206 0.8555568
# 9          WAS 0.8062889 0.8169627
# 10         VIM 0.8473278 0.6605903

















# ==================== NMF ====================
setwd("..")
setwd("NMF")
##BiocManager::install('Biobase')
##install.packages('NMF')
Sys.setenv(LANGUAGE = "en") #显示英文报错信息
options(stringsAsFactors = FALSE) #禁止chr转成factor
##清空环境
rm(list=ls())
#install.packages("NMF")
library(NMF)
library(data.table)
library(ggsci)
library(pheatmap)
library(AUCell)
library(GEOquery)
library(tidyverse)
library(Seurat)
library(RColorBrewer)
library(corrplot)

bulk_matrix <- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_clinical_filtered.txt", row.names=1)
any(bulk_matrix < 0)

# 将负值截断为 0
bulk_matrix  <- pmax(bulk_matrix, 0)

# 过滤低表达基因（TPM>1至少在50%样本中）
keep_genes <- rowSums(bulk_matrix > 1) >= ncol(bulk_matrix)*0.5
bulk_matrix <- bulk_matrix[keep_genes, ]

# 参数设置
topn <- 6000    # 选择高变异基因数（与单细胞分析一致）
ranks <- 2:6    # 测试rank范围（根据需求调整）
nrun <- 30      # 迭代次数

# 选择高变异基因（基于标准差）
genesd <- apply(bulk_matrix, 1, sd)
top_genes <- names(genesd[order(genesd, decreasing = TRUE)][1:topn])
nmfdat <- bulk_matrix[top_genes, ]

# 运行NMF（Brunet算法）
set.seed(123)
res <- nmf(nmfdat, rank = ranks, method = "brunet", nrun = nrun)

# 评估最佳rank（通过轮廓系数）
plot(res)  # 选择轮廓系数最高的rank
optimal_rank <- 4  # 假设选择rank=4（需根据plot结果调整）

# 提取特征矩阵（基因权重）
# 确认实际运行的rank值
print(ranks)  # 应显示如2:6的范围
print(names(res))  # 查看res对象的结构

# 正确提取特定rank的结果（假设ranks=2:6）
optimal_rank <- 4  # 假设选择rank=4
signature <- basis(res$fit[[optimal_rank - min(ranks) + 1]])  # 调整索引
colnames(signature) <- paste0("Factor_", 1:optimal_rank)

# 保存结果
write.table(signature, "bulk_NMF_signature.txt", sep = "\t")
saveRDS(res, "NMF_results.rds")

# 可视化因子热图（前30个特征基因）
pdf("NMF_heatmap.pdf")
library(pheatmap)
top_genes <- rownames(signature)[order(rowSums(signature), decreasing = TRUE)[1:30]]
pheatmap(signature[top_genes, ], cluster_rows = FALSE, main = "Top 30 Feature Genes")
#dev.off()
# 样本聚类（基于NMF因子得分）
# Instead of:
# sample_scores <- t(coef(res[[optimal_rank]]))

# Use this:
sample_scores <- t(coef(res$fit[[optimal_rank - min(ranks) + 1]]))
heatmap(cor(sample_scores), main = "Sample Clustering by NMF Factors")

#####查看一致性矩阵共识值 和 轮廓系数 
# res是nmf()函数的输出结果
consensus_matrix <- consensus(res$fit[[optimal_rank - min(ranks) + 1]])  # 提取最佳秩对应的一致性矩阵
consensus_value <- mean(consensus_matrix)  # 计算整体共识值
print(consensus_value)  # 共识值（整体一致性）0.2795943

# 从样本得分矩阵确定每个样本的聚类标签（归属概率最高的因子）
cluster_labels <- apply(sample_scores, 1, which.max)  # 每行最大值对应的列索引即为聚类标签
library(cluster)
# 计算样本间距离矩阵（以基因表达矩阵为例）
input<- bulk_matrix  
dist_matrix <- dist(t(input))  # input为用于NMF的基因表达矩阵（基因行、样本列）
# 计算轮廓系数
sil <- silhouette(cluster_labels, dist_matrix)
silhouette_coef <- mean(sil[, "sil_width"])  # 整体轮廓系数
print(silhouette_coef)  # 输出 轮廓系数 0.1016029




# 因子功能注释（示例：gProfiler2）
#install.packages("gprofiler2")  # 从CRAN官方源安装
library(gprofiler2)           
# for (i in 1:optimal_rank) {
#   top_genes <- names(sort(signature[, i], decreasing = TRUE)[1:100])
#   gostres <- gost(top_genes, organism = "hsapiens", sources = "GO:BP")
#   print(head(gostres$result[, c("term_name", "p_value")]))
# }
# ######这一步运行超超时

# 加载包
library(clusterProfiler)
library(org.Hs.eg.db)  # 人类基因注释（如果是小鼠：org.Mm.eg.db）
library(fgsea)
library(ggplot2)

# 确认最优rank=4
optimal_rank <- 4

# 提取基因权重矩阵（特征矩阵）
signature <- basis(res$fit[[optimal_rank - min(ranks) + 1]])
colnames(signature) <- paste0("Factor_", 1:optimal_rank)

# 提取样本得分矩阵
sample_scores <- t(coef(res$fit[[optimal_rank - min(ranks) + 1]]))
colnames(sample_scores) <- colnames(signature)

# 查看前5个基因的权重
head(signature, 5)


# 定义提取Top基因的函数
get_top_genes <- function(factor_name, n=100) {
  # 按权重降序排序
  sorted_genes <- rownames(signature)[order(signature[, factor_name], decreasing = TRUE)]
  return(sorted_genes[1:n])
}

# 为每个因子提取Top基因
factor_genes <- lapply(colnames(signature), get_top_genes)
names(factor_genes) <- colnames(signature)

# 查看Factor_1的Top基因
head(factor_genes$Factor_1)


# 将基因符号转换为Entrez ID（clusterProfiler需要）
convert_to_entrez <- function(gene_symbols) {
  mapIds(org.Hs.eg.db, 
         keys = gene_symbols,
         keytype = "SYMBOL", 
         column = "ENTREZID")
}

# 对每个因子进行GO和KEGG富集分析
enrichment_results <- list()

for (factor in names(factor_genes)) {
  entrez_ids <- convert_to_entrez(factor_genes[[factor]])
  entrez_ids <- na.omit(entrez_ids)
  
  # GO富集（生物过程）
  go_bp <- enrichGO(
    gene = entrez_ids,
    OrgDb = org.Hs.eg.db,
    ont = "BP",  # Biological Process
    pvalueCutoff = 0.05,
    qvalueCutoff = 0.1
  )
  
  # KEGG通路富集
  kegg <- enrichKEGG(
    gene = entrez_ids,
    organism = "hsa",  # 人类："hsa"；小鼠："mmu"
    pvalueCutoff = 0.05
  )
  
  enrichment_results[[paste0(factor, "_GO")]] <- go_bp
  enrichment_results[[paste0(factor, "_KEGG")]] <- kegg
}

# 保存富集结果
saveRDS(enrichment_results, "NMF_factor_enrichment_results.rds")

for (factor in names(factor_genes)) {
  go_result <- enrichment_results[[paste0(factor, "_GO")]]
  
  if (nrow(go_result) > 0) {
    p <- barplot(go_result, showCategory=10, font.size=8) + 
      ggtitle(paste(factor, "Top GO Biological Processes")) +
      theme(plot.title = element_text(size=10))
    print(p)
    ggsave(paste0(factor, "_GO_enrichment.pdf"), width=8, height=6)
  } else {
    message("No significant GO terms for ", factor)
  }
}


for (factor in names(factor_genes)) {
  kegg_result <- enrichment_results[[paste0(factor, "_KEGG")]]
  
  if (nrow(kegg_result) > 0) {
    p <- dotplot(kegg_result, showCategory=10) + 
      ggtitle(paste(factor, "Top KEGG Pathways")) +
      theme(plot.title = element_text(size=10))
    print(p)
    ggsave(paste0(factor, "_KEGG_enrichment.pdf"), width=8, height=6)
  } else {
    message("No significant KEGG pathways for ", factor)
  }
}

##3合并图片
# 加载包
library(patchwork)
library(ggplot2)

# 创建存放所有图的列表
all_plots <- list()

# 循环处理每个因子
for (factor in names(factor_genes)) {
  # 获取当前因子的结果
  go_result <- enrichment_results[[paste0(factor, "_GO")]]
  kegg_result <- enrichment_results[[paste0(factor, "_KEGG")]]
  
  # 初始化子图列表
  factor_plots <- list()
  
  # 绘制GO条形图（如果存在显著结果）
  if (nrow(go_result) > 0) {
    p_go <- barplot(go_result, showCategory=5, font.size=7) +  # 减少显示类别以适应合并
      ggtitle(paste(factor, "Top GO Terms")) +
      theme(plot.title = element_text(size=9),
            axis.text.y = element_text(size=6))
    factor_plots[["GO"]] <- p_go
  }
  
  # 绘制KEGG点图（如果存在显著结果）
  if (nrow(kegg_result) > 0) {
    p_kegg <- dotplot(kegg_result, showCategory=5) +  # 减少显示类别以适应合并
      ggtitle(paste(factor, "Top KEGG Pathways")) +
      theme(plot.title = element_text(size=9),
            axis.text.y = element_text(size=6))
    factor_plots[["KEGG"]] <- p_kegg
  }
  
  # 如果当前因子有至少一种显著结果，添加到总图中
  if (length(factor_plots) > 0) {
    # 合并当前因子的GO和KEGG图（垂直排列）
    combined_factor <- wrap_plots(factor_plots, ncol = 1, heights = rep(1, length(factor_plots)))
    all_plots[[factor]] <- combined_factor
  } else {
    message("No significant terms for ", factor)
  }
}

# 合并所有因子的图（水平排列）
final_plot <- wrap_plots(all_plots, nrow = 1) + 
  plot_annotation(title = "NMF Factor Enrichment Analysis",
                  theme = theme(plot.title = element_text(hjust = 0.5, size = 12)))

# 保存合并的大图
ggsave("Combined_Enrichment_Plot.pdf", 
       plot = final_plot, 
       width = 6 * length(all_plots),  # 宽度根据因子数量调整
       height = 8, 
       limitsize = FALSE)

# 显示图形（在RStudio中查看）
print(final_plot)

#######汇总########
# 加载包
library(patchwork)
library(ggplot2)
library(clusterProfiler)

# 创建更美观的富集分析图表
create_enrichment_plots <- function(factor_name, go_result, kegg_result) {
  plots <- list()
  
  # GO富集条形图
  if (nrow(go_result) > 0) {
    p_go <- barplot(go_result, showCategory=8, font.size=9) + 
      ggtitle(paste(factor_name, "Top GO Terms")) +
      theme(plot.title = element_text(size=11, face="bold", hjust=0.5),
            axis.text.y = element_text(size=8),
            axis.text.x = element_text(size=8),
            legend.position = "none") +  # 移除图例，用数值标注
      scale_fill_gradient(low = "steelblue", high = "firebrick") +
      geom_text(aes(label = format.pval(p.adjust, digits = 2)), 
                hjust = -0.1, size = 2.5, color = "turquoise")
    plots[["GO"]] <- p_go
  }
  
  # KEGG通路点图
  if (nrow(kegg_result) > 0) {
    p_kegg <- dotplot(kegg_result, showCategory=8, font.size=9) + 
      ggtitle(paste(factor_name, "Top KEGG Pathways")) +
      theme(plot.title = element_text(size=11, face="bold", hjust=0.5),
            axis.text.y = element_text(size=8),
            axis.text.x = element_text(size=8),
            legend.position = "right") +
      scale_color_gradient(low = "blue", high = "red") +
      scale_size_continuous(range = c(3, 8))  # 调整气泡大小范围
    plots[["KEGG"]] <- p_kegg
  }
  
  return(plots)
}

# 为每个因子创建图表
all_factor_plots <- list()

for (factor in names(factor_genes)) {
  go_result <- enrichment_results[[paste0(factor, "_GO")]]
  kegg_result <- enrichment_results[[paste0(factor, "_KEGG")]]
  
  factor_plots <- create_enrichment_plots(factor, go_result, kegg_result)
  
  if (length(factor_plots) > 0) {
    # 垂直排列GO和KEGG图
    combined_factor <- wrap_plots(factor_plots, ncol = 1, heights = c(1, 1.2))
    all_factor_plots[[factor]] <- combined_factor
  }
}

# 创建分页显示（每页2个因子）
for (i in seq(1, length(all_factor_plots), by = 2)) {
  page_factors <- names(all_factor_plots)[i:min(i+1, length(all_factor_plots))]
  page_plots <- all_factor_plots[page_factors]
  
  page_combined <- wrap_plots(page_plots, nrow = 1) + 
    plot_annotation(title = paste("NMF Factor Enrichment Analysis - Page", ceiling(i/2)),
                    theme = theme(plot.title = element_text(hjust = 0.5, size=14, face="bold")))
  
  ggsave(paste0("Enrichment_Page_", ceiling(i/2), ".pdf"), 
         plot = page_combined, 
         width = 16, 
         height = 10,
         dpi = 300)
}

# 单独保存每个因子的高质量图表
for (factor in names(factor_genes)) {
  go_result <- enrichment_results[[paste0(factor, "_GO")]]
  kegg_result <- enrichment_results[[paste0(factor, "_KEGG")]]
  
  if (nrow(go_result) > 0) {
    p_go <- barplot(go_result, showCategory=15) + 
      ggtitle(paste(factor, "GO Enrichment")) +
      theme(plot.title = element_text(size=14, face="bold", hjust=0.5))
    ggsave(paste0(factor, "_GO_Detailed.pdf"), width=10, height=8, dpi=300)
  }
  
  if (nrow(kegg_result) > 0) {
    p_kegg <- dotplot(kegg_result, showCategory=15) + 
      ggtitle(paste(factor, "KEGG Enrichment")) +
      theme(plot.title = element_text(size=14, face="bold", hjust=0.5))
    ggsave(paste0(factor, "_KEGG_Detailed.pdf"), width=12, height=8, dpi=300)
  }
}

# 创建汇总表格
library(kableExtra)
library(dplyr)

enrichment_summary <- data.frame()

for (factor in names(factor_genes)) {
  go_result <- enrichment_results[[paste0(factor, "_GO")]]
  kegg_result <- enrichment_results[[paste0(factor, "_KEGG")]]
  
  if (nrow(go_result) > 0) {
    go_summary <- head(go_result@result, 5) %>%
      mutate(Database = "GO", Factor = factor) %>%
      select(Factor, Database, Term = Description, p.adjust, Count)
    enrichment_summary <- rbind(enrichment_summary, go_summary)
  }
  
  if (nrow(kegg_result) > 0) {
    kegg_summary <- head(kegg_result@result, 5) %>%
      mutate(Database = "KEGG", Factor = factor) %>%
      select(Factor, Database, Term = Description, p.adjust, Count)
    enrichment_summary <- rbind(enrichment_summary, kegg_summary)
  }
}

# 保存汇总表格
write.csv(enrichment_summary, "Enrichment_Summary_Table.csv", row.names = FALSE)

# 在RMarkdown中创建美观的表格
kable(enrichment_summary, format = "html", caption = "NMF Factor Enrichment Summary") %>%
  kable_styling(bootstrap_options = c("striped", "hover")) %>%
  save_kable("Enrichment_Summary.html")

#######检验####
tpms_with_clinical <- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_with_clinical.txt", row.names=1)
exp_surv_clinical_tpms<- tpms_with_clinical 
group_labels <-  data.frame(
  sample_id = rownames(exp_surv_clinical_tpms),  # 行名作为“样本ID”列
  group = exp_surv_clinical_tpms$group           # 提取“group”列
)
group_labels <- as.vector(group_labels)
# 检查分组内容
table(group_labels)
group <- group_labels$group  # 提取分组信息（chr向量）
names(group) <- gsub("-", ".", group_labels$sample_id)  # 命名样本名（与sample_scores对齐）
common_samples <- intersect(rownames(sample_scores), names(group))
sample_scores <- sample_scores[common_samples, ]
group <- group[common_samples]



sample_names_in_se <- rownames(exp_surv_clinical_tpms)  # ⬅ SingleCellExperiment 的样本/细胞名
# 假设你最优的 rank 是 4，那么有 Factor_1, Factor_2, Factor_3, Factor_4
num_factors <- optimal_rank  # 假设 optimal_rank 是 4
colnames(sample_scores) <- paste0("Factor_", 1:num_factors)
print(colnames(sample_scores))  # 应该不再为 NULL
# 
# # 强制确保顺序一致（推荐先检查）
# if (!all(rownames(sample_scores) %in% sample_names_in_se)) {
#   stop("sample_scores 的行名与 SingleCellExperiment 的样本名（colnames(se)）不匹配，请检查！")
# }
sample_names_in_se <- rownames(exp_surv_clinical_tpms)
sample_names_in_se <- gsub("-", ".", sample_names_in_se)  # 替换 "-" 为 "."
factors <- colnames(sample_scores)  # 如 Factor_1, Factor_2, ...

results <- list()

for (factor in factors) {
  x <- sample_scores[, factor]  # 正确写法，适用于矩阵和数据框
  
  group <- as.factor(group)      # 已经从 colData(se) 提取
  
  # 检查是否有足够样本
  # if (length(unique(group)) != 2) {
  #   warning(paste("分组不是二分类，跳过因子:", factor))
  #   next
  # }
  
  # 尝试正态性检验 & 方差分析
  normality_pvals <- tapply(x, group, function(y) {
    if (length(y) > 3) shapiro.test(y)$p.value else NA
  })
  
  # 先尝试 ANOVA
  anova_model <- try(aov(x ~ group), silent = TRUE)
  
  if (!inherits(anova_model, "try-error")) {
    anova_summary <- summary(anova_model)
    anova_p <- anova_summary[[1]]$"Pr(>F)"[1]
    
    ss_total <- sum((x - mean(x))^2)
    ss_between <- anova_summary[[1]]$"Sum Sq"[1]
    eta_sq <- ss_between / ss_total
    
    results[[factor]] <- data.frame(
      Factor = factor,
      Method = "ANOVA",
      P_value = anova_p,
      Eta_squared = eta_sq,
      Normality_p = mean(normality_pvals, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  } else {
    # 如果ANOVA失败，则使用 Kruskal-Wallis
    kruskal_test <- kruskal.test(x ~ group)
    kruskal_p <- kruskal_test$p.value
    
    n <- length(x)
    k <- length(levels(group))
    epsilon_sq <- (kruskal_test$statistic / (n^2 - 1)) * (k - 1)
    
    results[[factor]] <- data.frame(
      Factor = factor,
      Method = "Kruskal-Wallis",
      P_value = kruskal_p,
      Eta_squared = epsilon_sq,
      Normality_p = mean(normality_pvals, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }
}

# 转为数据框
results_df <- do.call(rbind, results)

# 添加显著性标记
results_df$Significance <- ifelse(results_df$P_value < 0.001, "***",
                                  ifelse(results_df$P_value < 0.01, "**",
                                         ifelse(results_df$P_value < 0.05, "*", "ns")))

# 按 p 值排序
results_df <- results_df[order(results_df$P_value), ]

# 查看结果
print(results_df)

# 保存结果
write.csv(results_df, "NMF_factor_clinical_group_statistical_test_results.csv", row.names = FALSE)

#####可视化

library(ggplot2)
library(tidyr)
library(dplyr)

# 确保 sample_scores 行名与 group_labels 一一对应（已对齐）
# sample_scores: 每个样本的 NMF factor 得分（行是样本，列是 Factor_1, Factor_2, ...）
# group_labels: colData(se)$group，如 "Metastasis" "No_Metastasis"

# 转换为 long format
sample_scores_long <- sample_scores %>%
  as.data.frame() %>%
  tibble::rownames_to_column(var = "Sample") %>%
  pivot_longer(cols = -Sample, names_to = "Factor", values_to = "Score")

# 添加分组信息
sample_scores_long$Group <- group_labels[sample_scores_long$Sample]

# 保存过如下文件（请根据你的实际文件名调整）
#results_df <- read.csv("NMF_factor_clinical_group_statistical_test_results.csv", stringsAsFactors = FALSE)

factors_to_plot <- unique(sample_scores_long$Factor)  # 如 Factor_1, Factor_2, ...

#循环：为每个 Factor 绘制一张图
# 安装 ggsci 包（如果尚未安装）
if (!requireNamespace("ggsci", quietly = TRUE)) {
  install.packages("ggsci")
}

# 加载 ggsci 包
library(ggsci)
for (factor in factors_to_plot) {
  # --- Step 1: 数据准备 ---
  df_plot <- sample_scores_long %>%
    filter(Factor == factor) %>%
    mutate(Group = as.factor(Group))  # 确保 Group 是因子
  
  # --- Step 2: 显著性标记 ---
  sig_row <- results_df %>% filter(Factor == factor)
  p_sig <- ifelse(nrow(sig_row) > 0, sig_row$Significance[1], "ns")
  
  # --- Step 3: 绘图 ---
  p <- ggplot(df_plot, aes(x = Group, y = Score, fill = Group)) +
    geom_violin(alpha = 0.7, trim = FALSE) +
    geom_boxplot(width = 0.15, fill = "white", outlier.shape = NA) +
    geom_jitter(width = 0.15, size = 1.2, alpha = 0.6) +
    scale_x_discrete() +  # 关键修复：声明 x 轴为离散变量
    scale_fill_npg() +
    labs(
      title = paste("NMF Factor:", factor),
      x = "Clinical Group",
      y = "Factor Score"
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  
  # --- Step 4: 添加显著性标记 ---
  y_max <- max(df_plot$Score, na.rm = TRUE)
  p <- p + 
    geom_text(
      aes(x = 1.5, y = y_max * 1.1, label = p_sig),
      size = 6, inherit.aes = FALSE
    )
  
  # 保存图片
  ggsave(
    paste0("NMF_Factor_", factor, ".pdf"), 
    plot = p, width = 4, height = 5, dpi = 300
  )
  
  print(p)
}


######合并箱线图
# 
# library(ggplot2)
# library(tidyr)
# library(dplyr)
# 
# # 确保 sample_scores 行名与 colnames(se) 一致
# sample_names_in_se <- colnames(se)
# if (!all(rownames(sample_scores) %in% sample_names_in_se)) {
#   stop("sample_scores 的行名需要与 SingleCellExperiment 的样本名（colnames(se)）一致！")
# }
# 
# # 转为 long format
# sample_scores_long <- sample_scores %>%
#   as.data.frame() %>%
#   tibble::rownames_to_column(var = "Sample") %>%
#   pivot_longer(cols = -Sample, names_to = "Factor", values_to = "Score")
# 
# # 添加分组信息
# sample_scores_long$Group <- group_labels[match(sample_scores_long$Sample, sample_names_in_se)]
# 
# # 检查前几行
# head(sample_scores_long)

# # 画每个 factor 的箱线图
# factors_to_plot <- colnames(sample_scores)
# print(results_df)
# Factor Method    P_value Eta_squared  Normality_p Significance
# 1 Factor_3  ANOVA 0.01184583 0.064168352 0.0821801835            *
#   2 Factor_1  ANOVA 0.01535282 0.059667076 0.0788311072            *
#   3 Factor_4  ANOVA 0.02518151 0.051120112 0.0002400504            *
#   4 Factor_2  ANOVA 0.41964590 0.006796649 0.0599567339           ns
# 
# 

library(ggplot2)
library(ggsci)

# 确保 Group 是因子
sample_scores_long$Group <- as.factor(sample_scores_long$Group)

# 绘图
p_all <- ggplot(sample_scores_long, aes(x = Group, y = Score, fill = Group)) +
  # 箱线图
  geom_boxplot(
    alpha = 0.7,
    outlier.shape = 16,
    size = 0.5,
    width = 0.6
  ) +
  # 散点
  geom_jitter(
    width = 0.2,
    size = 1.0,
    alpha = 0.6
  ) +
  # 坐标轴与主题
  scale_x_discrete() +  # 关键修复：声明 x 轴为离散变量
  scale_fill_npg() +    # 确保已加载 ggsci
  labs(x = "Clinical Group", y = "Factor Score") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold"),
    legend.position = "top",
    strip.background = element_rect(fill = "grey85"),
    strip.text = element_text(face = "bold")
  ) +
  # 分面：按 Factor 排列
  facet_wrap(~Factor, ncol = 4, scales = "free_y") +
  
  # 显著性标记（修正 x 位置）
  geom_text(
    data = results_df,
    aes(
      x = 1.5,  # 可能需要根据分组数量调整（如 1.5 适用于 2 分组）
      y = 1.1 * max(sample_scores_long$Score, na.rm = TRUE),
      label = Significance
    ),
    size = 6,
    color = "turquoise",
    inherit.aes = FALSE
  )

print(p_all)

ggsave("NMF_All_Factors_Boxplot_With_Significance.tiff", 
       plot = p_all, 
       width = 12, height = 6, dpi = 300)

######机器学习比较######
# 样本得分矩阵（行是样本，列是因子）
X <- as.data.frame(sample_scores)  # 每个样本在各个因子上的得分

# 临床分组 - 转换为0/1数值型变量
y <- ifelse(group == "Metastasis", 1, 0)  # Metastasis=1, No_Metastasis=0
y_factor <- as.factor(ifelse(y == 1, "Metastasis", "No_Metastasis")) # 用于随机森林和SVM

# 检查数据
head(X)
table(y)

# 安装必要包（如果尚未安装）
if (!require(randomForest)) install.packages("randomForest")
if (!require(e1071)) install.packages("e1071") # 用于SVM
if (!require(pROC)) install.packages("pROC")
if (!require(ggplot2)) install.packages("ggplot2")

library(randomForest)
library(e1071)
library(pROC)
library(ggplot2)

# 1. 逻辑回归
logistic_model <- glm(y ~ ., data = X, family = binomial)
summary(logistic_model)

# 2. 随机森林
rf_model <- randomForest(x = X, y = y_factor, importance = TRUE, ntree = 500)
print(rf_model)

# 3. 支持向量机(SVM)
svm_model <- svm(x = X, y = y_factor, probability = TRUE)
print(svm_model)

# ROC曲线比较
# 逻辑回归的ROC
logistic_prob <- predict(logistic_model, type = "response")
roc_logistic <- roc(y, logistic_prob)

# 随机森林的ROC
rf_prob <- predict(rf_model, type = "prob")[,"Metastasis"]
roc_rf <- roc(y, rf_prob)

# SVM的ROC
svm_prob <- attr(predict(svm_model, newdata = X, probability = TRUE), "probabilities")[,"Metastasis"]
roc_svm <- roc(y, svm_prob)

# 绘制ROC曲线比较图
roc_data <- data.frame(
  Specificity = c(1 - roc_logistic$specificities, 
                  1 - roc_rf$specificities,
                  1 - roc_svm$specificities),
  Sensitivity = c(roc_logistic$sensitivities, 
                  roc_rf$sensitivities,
                  roc_svm$sensitivities),
  Method = rep(c("Logistic Regression", "Random Forest", "SVM"), 
               c(length(roc_logistic$sensitivities), 
                 length(roc_rf$sensitivities),
                 length(roc_svm$sensitivities)))
)

# 自定义颜色
method_colors <- c("#E69F00", "#56B4E9", "#009E73")

ggplot(roc_data, aes(x = Specificity, y = Sensitivity, color = Method)) +
  geom_line(size = 1) +
  geom_abline(intercept = 1, slope = 1, linetype = "dashed", color = "gray") +
  scale_x_reverse() +
  labs(title = "ROC Curve Comparison",
       x = "1 - Specificity (False Positive Rate)",
       y = "Sensitivity (True Positive Rate)") +
  theme_minimal() +
  scale_color_manual(values = method_colors) +
  annotate("text", x = 0.75, y = 0.30, 
           label = paste("Logistic Regression AUC =", round(auc(roc_logistic), 3)),
           color = method_colors[1], hjust = 0) +
  annotate("text", x = 0.75, y = 0.25, 
           label = paste("Random Forest AUC =", round(auc(roc_rf), 3)),
           color = method_colors[2], hjust = 0) +
  annotate("text", x = 0.75, y = 0.20, 
           label = paste("SVM AUC =", round(auc(roc_svm), 3)),
           color = method_colors[3], hjust = 0)

ggsave("ROC_Comparison_3methods.pdf", width = 8, height = 6)

# 输出AUC值比较
cat("\nModel Performance Comparison:\n")
cat("1. Logistic Regression AUC:", round(auc(roc_logistic), 3), "\n")
cat("2. Random Forest AUC:", round(auc(roc_rf), 3), "\n")
cat("3. SVM AUC:", round(auc(roc_svm), 3), "\n")

# 模型重要性/系数比较
cat("\nVariable Importance Comparison:\n")

# 逻辑回归系数
logistic_coef <- data.frame(
  Factor = gsub("Factor_", "", names(coef(logistic_model)[-1])),
  Coefficient = coef(logistic_model)[-1],
  Abs_Coefficient = abs(coef(logistic_model)[-1])
)
logistic_coef <- logistic_coef[order(-logistic_coef$Abs_Coefficient), ]

# 随机森林重要性
rf_importance <- importance_rf[order(-importance_rf$Importance), ]

# SVM不支持直接获取变量重要性，但可以通过其他方法估计
# 这里使用模型权重作为替代（对于线性SVM）
if (svm_model$type == 0) { # 如果是C-classification
  svm_weights <- t(svm_model$coefs) %*% svm_model$SV
  svm_importance <- data.frame(
    Factor = colnames(X),
    Importance = as.vector(abs(svm_weights))
  )
  svm_importance <- svm_importance[order(-svm_importance$Importance), ]
} else {
  svm_importance <- data.frame(Factor = colnames(X), Importance = NA)
  cat("Note: Variable importance not available for this SVM type\n")
}

# 打印重要性比较
print("Logistic Regression Coefficients (sorted by absolute value):")
print(logistic_coef)

print("\nRandom Forest Importance (MeanDecreaseGini):")
print(rf_importance)

if (exists("svm_importance") && !all(is.na(svm_importance$Importance))) {
  print("\nSVM Variable Importance (absolute weights):")
  print(svm_importance)
}

# 统计检验比较
cat("\nStatistical Comparisons:\n")
cat("1. Logistic Regression vs Random Forest:\n")
print(roc.test(roc_logistic, roc_rf))

cat("\n2. Logistic Regression vs SVM:\n")
print(roc.test(roc_logistic, roc_svm))

cat("\n3. Random Forest vs SVM:\n")
print(roc.test(roc_rf, roc_svm))
# data:  roc_rf and roc_svm
# Z = -1.5014, p-value = 0.1333
# alternative hypothesis: true difference in AUC is not equal to 0
# 95 percent confidence interval:
#   -0.12996331  0.01721821
# sample estimates:
#   AUC of roc1 AUC of roc2 
# 0.6960042   0.7523767 
#######向量机结果最好但是表现factor2优势







#=================== 2.cellchat（bulk版） ====================
# 加载所需库
setwd("..")
setwd("cellchat")
suppressMessages({
  library(CellChat)
  library(SummarizedExperiment)
  library(ggplot2)
  library(dplyr)
  library(pheatmap)
})

# ====================== 1. 数据准备与CellChat对象创建 ======================
tpm_data <- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_clinical_filtered.txt", row.names=1)
tpms_with_clinical<- read.delim("~/Bulk-RNA/TCGA-BLCA/clinical/tpms_with_clinical.txt", row.names=1)
# 将行名中的 "-" 替换为 "."
rownames(tpms_with_clinical) <- gsub("-", ".", rownames(tpms_with_clinical))

expr_matrix <- as.matrix(tpm_data)

# 提取样本分组信息
sample_groups <- tpms_with_clinical$group
identity <- data.frame(group = sample_groups, row.names = rownames(tpms_with_clinical))

# 为bulk数据创建CellChat对象（每个样本视为“细胞”，分组视为“细胞类型”）
cellchat <- createCellChat(object = expr_matrix, meta = identity, group.by = "group")
cellchat <- addMeta(cellchat, meta = identity, meta.name = "Group")
cellchat <- setIdent(cellchat, ident.use = "Group")

# 查看分组情况
cat("分组水平：", paste(levels(cellchat@idents), collapse = ", "), "\n")
groupSize <- as.numeric(table(cellchat@idents))

# ====================== 2. 加载数据库与数据预处理 ======================
# 选择物种对应的CellChat数据库
species <- "Human"  # 可改为"Mouse"或"Zebrafish"
if (species == 'Human') {
  CellChatDB <- CellChatDB.human
} else if (species == 'Mouse') {
  CellChatDB <- CellChatDB.mouse
} else {
  CellChatDB <- CellChatDB.zebrafish
}

# 选择信号类型（如“Secreted Signaling”）
CellChatDB.use <- subsetDB(CellChatDB, search = "Secreted Signaling")
cellchat@DB <- CellChatDB.use

# 数据预处理：截取信号基因表达、识别过表达基因与互作
cellchat <- subsetData(cellchat)
cellchat <- identifyOverExpressedGenes(cellchat, thresh.p = 0.05)
cellchat <- identifyOverExpressedInteractions(cellchat)

# 投影到PPI网络（人类/小鼠分别对应不同PPI）
if (species == 'Human') {
  cellchat <- projectData(cellchat, PPI.human)
} else if (species == 'Mouse') {
  cellchat <- projectData(cellchat, PPI.mouse)
}

# ====================== 3. 计算细胞通讯与通路分析 ======================
# 计算通讯概率并过滤网络
cellchat <- computeCommunProb(cellchat, raw.use = FALSE, trim = TRUE)
cellchat <- filterCommunication(cellchat, min.cells = 1)  # bulk数据放宽过滤

# 推断通路水平通讯并聚合网络
cellchat <- computeCommunProbPathway(cellchat, thresh = 0.05)
cellchat <- aggregateNet(cellchat, thresh = 0.05)

# 保存CellChat对象（后续可直接加载，无需重复计算）
saveRDS(cellchat, "cellchat_bulk.rds")

# ====================== 4. 通路活性分析与可视化（核心修正部分） ======================
# ---- 4.1 提取三维通路活性数据并转换为二维矩阵 ----
pathway_3d <- cellchat@netP$prob  # 结构：通路 × 源分组 × 目标分组
pathways <- dimnames(pathway_3d)[[1]]       # 通路名
source_groups <- dimnames(pathway_3d)[[2]]  # 源分组名
target_groups <- dimnames(pathway_3d)[[3]]  # 目标分组名

# 构建“通路 × 源→目标分组”的二维矩阵
col_names <- paste(rep(source_groups, each = length(target_groups)), 
                   target_groups, sep = "→")
pathway_matrix <- matrix(
  nrow = length(pathways), 
  ncol = length(col_names),
  dimnames = list(pathways, col_names)
)

# 填充矩阵：每个元素为通路在“源→目标”下的平均通讯概率
for (p in pathways) {
  for (s in source_groups) {
    for (t in target_groups) {
      col_idx <- which(col_names == paste(s, t, sep = "→"))
      pathway_matrix[p, col_idx] <- mean(pathway_3d[p, s, t])
    }
  }
}

# 处理异常值与过滤无方差通路
pathway_matrix[is.na(pathway_matrix) | is.infinite(pathway_matrix)] <- 0
row_vars <- apply(pathway_matrix, 1, var)
pathway_filtered <- pathway_matrix[row_vars > 0, , drop = FALSE]

# ---- 4.2 绘制通路活性热图 ----
if (nrow(pathway_filtered) > 0) {
  pdf("pathway_activity_heatmap.pdf", width = 12, height = 10)
  pheatmap(
    pathway_filtered, 
    scale = "row",  # 按行标准化（不同通路间可比）
    show_rownames = TRUE, 
    show_colnames = TRUE,
    treeheight_row = 10, 
    treeheight_col = 10,
    main = "不同分组组合的信号通路活性热图"
  )
  dev.off()
} else {
  warning("所有通路方差为0，热图未生成！")
}

#####plot
if (nrow(pathway_filtered) > 0) {
  # 直接绘制热图（显示在 R 的图形设备中）
  pheatmap(
    pathway_filtered, 
    scale = "row",          # 按行标准化
    show_rownames = TRUE,   # 显示行名（通路名）
    show_colnames = TRUE,   # 显示列名（样本/分组名）
    treeheight_row = 10,    # 行聚类树高度
    treeheight_col = 10,    # 列聚类树高度
    main = "不同分组组合的信号通路活性热图"  # 标题
  )
} else {
  warning("所有通路方差为0，热图未生成！")
}
# ---- 4.3 比较两组通路活性差异（示例：No_Metastasis→No_Metastasis vs Metastasis→Metastasis） ----
focus_cols <- c("No_Metastasis→No_Metastasis", "Metastasis→Metastasis")  # 可根据实际分组修改
if (all(focus_cols %in% colnames(pathway_filtered))) {
  group1 <- focus_cols[1]
  group2 <- focus_cols[2]
  pathway_diff <- pathway_filtered[, group1] - pathway_filtered[, group2]
  
  # 取差异最大的前20个通路（通路不足20则取全部）
  top_pathways <- names(sort(abs(pathway_diff), decreasing = TRUE)[1:min(20, length(pathway_diff))])
  
  pdf("top_pathway_differences.pdf", width = 10, height = 8)
  data.frame(
    Pathway = factor(top_pathways, levels = rev(top_pathways)),
    Difference = pathway_diff[top_pathways]
  ) %>%
    ggplot(aes(Pathway, Difference)) +
    geom_bar(stat = "identity", aes(fill = Difference > 0)) +
    coord_flip() +
    labs(
      title = paste0(group1, " vs ", group2, " 通路活性差异"),
      y = paste0(group1, " - ", group2, " 活性差异")
    ) +
    theme_minimal()
  dev.off()
} else {
  warning("指定的分组组合不存在，差异图未生成！")
}

# ---- 4.4 可视化特定通路的通讯网络（示例：COMPLEMENT） ----
target_pathway <- "COMPLEMENT"  # 替换为实际存在的通路名
if (target_pathway %in% rownames(pathway_filtered)) {
  pdf(paste0(target_pathway, "_pathway_communication.pdf"), width = 10, height = 8)
  netVisual_aggregate(
    cellchat, 
    signaling = target_pathway,
    layout = "circle",
    title.name = paste0(target_pathway, " 通路通讯网络")
  )
  dev.off()
} else {
  warning(paste0("通路 '", target_pathway, "' 不存在，网络可视化未生成！"))
}

# ---- 4.5 输出通路活性数据 ----
write.table(
  pathway_filtered, 
  "pathway_activity_scores.txt",
  sep = "\t", 
  quote = FALSE, 
  row.names = TRUE, 
  col.names = TRUE
)



#######生存分析#########
setwd("clinical")
surv <- read.table("exp_surv_clinical_tpms.txt", sep = "\t", row.names = 1, check.names = F, stringsAsFactors = F, header = T)


surv$OS.time <- surv$OS.time / 30.44  # 将天转换为月（平均每月30.44天）


# 为THBS1做生存分析 ----------------------------------------------------------

# 根据THBS1表达量的中位数分组
surv$THBS1_group <- ifelse(surv$THBS1 > median(surv$THBS1, na.rm = TRUE), "High", "Low")
surv$THBS1_group <- factor(surv$THBS1_group, levels = c("Low", "High"))

# 检查分组情况
table(surv$THBS1_group)

# 加载生存分析包
library(survival)
library(survminer)

# 计算生存差异
fitd_THBS1 <- survdiff(Surv(OS.time, OS) ~ THBS1_group,
                       data = surv,
                       na.action = na.exclude)
pValue_THBS1 <- 1 - pchisq(fitd_THBS1$chisq, length(fitd_THBS1$n) - 1)

# 拟合生存曲线
fit_THBS1 <- survfit(Surv(OS.time, OS) ~ THBS1_group, data = surv)
summary(fit_THBS1)

# 准备P值标签
p.lab_THBS1 <- paste0("P", ifelse(pValue_THBS1 < 0.001, " < 0.001", paste0(" = ", round(pValue_THBS1, 3))))

# 绘制生存曲线
ggsurvplot(fit_THBS1,
           data = surv,
           pval = p.lab_THBS1,
           conf.int = TRUE,
           risk.table = TRUE,
           risk.table.col = "strata",
           palette = "jco",
           legend.labs = c("Low", "High"),
           size = 1,
           xlim = c(0, 100),
           break.time.by = 20,
           legend.title = "THBS1 Expression",
           surv.median.line = "hv",
           ylab = "Survival probability (%)",
           xlab = "Time (Months)",
           ncensor.plot = TRUE,
           ncensor.plot.height = 0.25,
           risk.table.y.text = FALSE,
           title = "Survival Analysis by THBS1 Expression")

# 保存图形
# ggsave("THBS1_survival_plot.tiff", width = 8, height = 6)
# dev.off()

# 为TGFB3做生存分析 ----------------------------------------------------------

# 根据TGFB3表达量的中位数分组
surv$TGFB3_group <- ifelse(surv$TGFB3 > median(surv$TGFB3, na.rm = TRUE), "High", "Low")
surv$TGFB3_group <- factor(surv$TGFB3_group, levels = c("Low", "High"))

# 检查分组情况
table(surv$TGFB3_group)

# 计算生存差异
fitd_TGFB3 <- survdiff(Surv(OS.time, OS) ~ TGFB3_group,
                       data = surv,
                       na.action = na.exclude)
pValue_TGFB3 <- 1 - pchisq(fitd_TGFB3$chisq, length(fitd_TGFB3$n) - 1)

# 拟合生存曲线
fit_TGFB3 <- survfit(Surv(OS.time, OS) ~ TGFB3_group, data = surv)
summary(fit_TGFB3)

# 准备P值标签
p.lab_TGFB3 <- paste0("P", ifelse(pValue_TGFB3 < 0.001, " < 0.001", paste0(" = ", round(pValue_TGFB3, 3))))

# 绘制生存曲线
ggsurvplot(fit_TGFB3,
           data = surv,
           pval = p.lab_TGFB3,
           conf.int = TRUE,
           risk.table = TRUE,
           risk.table.col = "strata",
           palette = "jco",
           legend.labs = c("Low", "High"),
           size = 1,
           xlim = c(0, 100),
           break.time.by = 20,
           legend.title = "TGFB3 Expression",
           surv.median.line = "hv",
           ylab = "Survival probability (%)",
           xlab = "Time (Months)",
           ncensor.plot = TRUE,
           ncensor.plot.height = 0.25,
           risk.table.y.text = FALSE,
           title = "Survival Analysis by TGFB3 Expression")

# 保存图形
#ggsave("TGFB3_survival_plot.tiff", width = 12, height = 6)
#dev.off()

#####手动保存图片







