#! /usr/bin/sh

######以下是配置部分，每次运行脚本之前需要确认一下

#样本信息
fq1="689_R1.fq.gz" #每次需要更改
fq2="689_R2.fq.gz" #每次需要更改
SM="689" #每次需要更改，表示样本名称
LB="lib" #通常不需要改
ID="lane" #通常不需要改
PL="illumina" #通常不需要改

#原始测序数据存放在哪个目录下面，末尾的斜线不能忘
data_path=/ifs1/Grp3/huangsiyuan/project/data/689/
#希望将比对后的bam存放到哪里？
align_path=/ifs1/Grp3/huangsiyuan/project/map/689_to_v20/
#这两个目录需要确保存在，可以根据自己的课题创建类似的目录，尽可能使目录结构清晰有意义，
#比如/ifs1/Grp3/huangsiyuan是我的home目录（登录服务器后，输入`pwd`命令可以知道），
#在下面创建`课题名称`的目录，再在`课题名称`下面创建`data`，`map`，`variation`等子目录

#参考序列的绝对路径，参考序列的索引创建见另一个脚本
ref_path=/ifs1/Grp3/huangsiyuan/project/ref/ref_v2.0/branap_v2.0.fa

#需要用到的软件的绝对路径。可以在软件的安装目录下面找到绝对路径，比如/ifs1/Software/biosoft/picard/就是安装目录，picard.jar是这个目录下面的软件，/ifs1/Software/biosoft/picard/picard.jar就是绝对路径。
#如果终端窗口下敲入`软件名`能显示软件使用的相关说明，表示该软件已经被添加到PATH环境变量，则不必要再在下方定义软件的绝对路径，比如`samtools`一般会包含在PATH中，所以此处没有写它的绝对路径
fastqc_path=/ifs1/Software/bin/fastqc
trim_path=/ifs1/Software/biosoft/Trimmomatic-0.36/trimmomatic-0.36.jar
picard_path=/ifs1/Software/biosoft/picard/picard.jar
gatk_path=~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar

#比对后生成的bam文件的命名前缀，比如`sample1.bam`的前缀是`sample1`，`/directory/sample1.bam`的前缀是`/directory/sample1`
bam_info=${align_path}${SM}

#根据脚本QC.sh的结果，看看是否有接头，如果有，在确定接头之后，将接头序列如下定义
#adapters_path=/ifs1/Software/biosoft/Trimmomatic-0.36/adapters/TruSeq3-PE.fa   #这种接头是用得比较多的，`TruSeq3`+`PE`，保存在Trimmomatic软件的安装包下面
#这里假设没有接头序列，所以上面一句被我用`#`注释掉了

######配置部分结束

######以下部分是主体，比对+变异检测，基本可以不用更改，除了两个地方
######1.`trim`这一步的`ILLUMINACLIP`参数在有接头的情况下使用，如果没有接头则不需要
######2.SNP和InDel过滤那一步的参数，这些参数需要根据文献中说的来做一些调整

###QC&trim
cd ${data_path}
#java -jar ${trim_path} PE -phred33 ${fq1} ${fq2} out.${fq1} out.trim.${fq1} out.${fq2} out.trim.${fq2} ILLUMINACLIP:${adapters_path}:2:30:10 SLIDINGWINDOW:5:20 LEADING:5 TRAILING:5 MINLEN:50
java -jar ${trim_path} PE -phred33 ${fq1} ${fq2} out.${fq1} out.trim.${fq1} out.${fq2} out.trim.${fq2} SLIDINGWINDOW:5:20 LEADING:5 TRAILING:5 MINLEN:50
${fastqc_path} out.${fq1} out.${fq2} -o ${data_path}fastqc_report

###比对
cd ${align_path}
bwa mem -t 4 -M -R "@RG\tID:"${ID}"\tPL:"${PL}"\tLB:"${LB}"\tSM:"${SM} ${ref_path} ${data_path}"out."${fq1} ${data_path}"out."${fq2} | samtools view -Sb - > ${bam_info}.bam

###对bam文件排序
java -jar ${picard_path} SortSam I=${bam_info}.bam  O=${bam_info}.s.bam SO=coordinate

###对bam文件标记PCR重复
java -jar ${picard_path} MarkDuplicates I=${bam_info}.s.bam O=${bam_info}.sm.bam M=${bam_info}.markdup_metrics.txt

###为bam文件建索引
samtools index ${bam_info}.sm.bam

###局部重比对
java -jar ${gatk_path} -T RealignerTargetCreator -R ${ref_path} -I ${bam_info}.sm.bam -o ${bam_info}.IndelRealigner.intervals
java -Xmx4g -jar ${gatk_path} -T IndelRealigner -R ${ref_path} -I ${bam_info}.sm.bam -targetIntervals ${bam_info}.IndelRealigner.intervals -o ${bam_info}.smr.bam

###变异检测
java -jar ${gatk_path} -T HaplotypeCaller -R ${ref_path} -I ${bam_info}.smr.bam -stand_call_conf 50 -A QualByDepth -A RMSMappingQuality -A MappingQualityRankSumTest -A ReadPosRankSumTest -A FisherStrand -A StrandOddsRatio -A Coverage -o ${bam_info}.vcf

###分开SNP和InDel
java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${bam_info}.vcf -selectType SNP -o ${align_path}snp_raw.vcf
java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${bam_info}.vcf -selectType INDEL -o ${align_path}indel_raw.vcf

###根据一些指标的阈值过滤不可信的变异
java -Xmx8g -jar ${gatk_path} -T VariantFiltration -R ${ref_path} -V ${align_path}snp_raw.vcf --filterExpression "( vc.hasAttribute('QD') && QD<2.0 ) || FS > 60.0 || MQ < 40.0 || ( vc.hasAttribute('ReadPosRankSum' ) && ReadPosRankSum < -8.0 ) || ( vc.hasAttribute('MQRankSum') && MQRankSum < -12.5 ) || ( vc.hasAttribute('SOR') && SOR > 3.0 ) || QUAL < 30.0 " --filterName "my_snp_filter" -o ${align_path}snp_f.vcf
java -Xmx8g -jar ${gatk_path} -T VariantFiltration -R ${ref_path} -V ${align_path}indel_raw.vcf --filterExpression "( vc.hasAttribute('QD') && QD<2.0 ) || FS > 200.0 || ( vc.hasAttribute('InbreedingCoeff' ) && InbreedingCoeff < -0.8 ) || ( vc.hasAttribute('ReadPosRankSum' ) && ReadPosRankSum < -20.0 ) || ( vc.hasAttribute('SOR') && SOR > 10.0 ) || QUAL < 30.0 " --filterName "my_inddel_filter" -o ${align_path}indel_f.vcf

java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${align_path}snp_f.vcf --excludeFiltered -o ${align_path}snp_filter.vcf
java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${align_path}indel_f.vcf --excludeFiltered -o ${align_path}indel_filter.vcf

######主体部分结束

######下面演示代码块注释
:<<EOF
#此处是代码，中间的任何命令都不会执行，比如
samtools index ${bam_info}.sm.bam
EOF
######演示结束