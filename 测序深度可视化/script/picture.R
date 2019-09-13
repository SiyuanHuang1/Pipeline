###导入文件，需要用到两个文件
chr_bed <- "Arabidopsis_thaliana.rename.bed"
depth_bed <- "sample1_depth_distribution.bed"
sample_name <- "sample_139"
###


###安装加载R包
a <- installed.packages()
b <- a[,"Package"]
pkg <- setdiff(c("karyoploteR"), b)

if (length(pkg) == 1) {
  if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
  
  BiocManager::install("karyoploteR")
}

library(karyoploteR)
rm(list=c("a","b","pkg"))
###


Bn.genome <- toGRanges(chr_bed)
kp <- plotKaryotype(genome=Bn.genome,labels.plotter = NULL,plot.type=1,main=sample_name)
kpAddChromosomeNames(kp, cex = 1.2) #cex调整字的大小
sample_bar <- toGRanges(depth_bed)
kpBars(kp, sample_bar,border="#377EB8",data.panel = 1,r0 = 0,r1 = 1,ymin = 0,ymax = 100) #此处的100选自前面数据整理过程中的最大深度为100


#在图形左右添加纵坐标轴，可以结合图形微调
kpAxis(kp, data.panel = 1, ymin = 0, ymax=100, tick.pos = c(20,40,60,80), labels = c("20","40","60","80"),tick.len = 700000, label.margin = -600000, side = 2, cex = 0.4, col="#777777")
kpAxis(kp, data.panel = 1, ymin = 0, ymax=100, tick.pos = c(20,40,60,80), labels = c("20","40","60","80"),tick.len = 700000, label.margin = -600000, side = 1, cex = 0.4, col="#777777")
