#! /usr/bin/sh

###path&conf
data_path=/ifs1/Grp3/huangsiyuan/project/data/689/
align_path=/ifs1/Grp3/huangsiyuan/project/map/689_to_v20/
#只有数据和数据目录是需要提前准备的
#这两个每次都要改
ref_path=/ifs1/Grp3/huangsiyuan/project/ref/ref_v2.0/branap_v2.0.fa
fastqc_path=/ifs1/Software/bin/fastqc
trim_path=/ifs1/Software/biosoft/Trimmomatic-0.36/trimmomatic-0.36.jar
adapters_path=/ifs1/Software/biosoft/Trimmomatic-0.36/adapters/TruSeq3-PE.fa
picard_path=/ifs1/Software/biosoft/picard/picard.jar
gatk_path=~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar
###variable#
fq1="689_R1.fq.gz"
fq2="689_R2.fq.gz"
SM="689"
LB="lib"
ID="lane"
PL="illumina"
#这六个每次都要改
bam_info=${align_path}${SM}"."${ID}
############

###QC&trim##
cd ${data_path}
mkdir fastqc_report
${fastqc_path} ${fq1} ${fq2} -o ${data_path}fastqc_report
java -jar ${trim_path} PE -phred33 -trimlog logfile ${fq1} ${fq2} out.${fq1} out.trim.${fq1} out.${fq2} out.trim.${fq2} ILLUMINACLIP:${adapters_path}:2:30:10 SLIDINGWINDOW:5:20 LEADING:5 TRAILING:5 MINLEN:50
${fastqc_path} out.${fq1} out.${fq2} -o ${data_path}fastqc_report
rm -f logfile
############
mkdir ${align_path}
cd ${align_path}
bwa mem -t 4 -M -R "@RG\tID:"${ID}"\tPL:"${PL}"\tLB:"${LB}"\tSM:"${SM} ${ref_path} ${data_path}"out."${fq1} ${data_path}"out."${fq2} | samtools view -Sb - > ${bam_info}.bam
############
java -jar ${picard_path} SortSam I=${bam_info}.bam  O=${bam_info}.s.bam SO=coordinate
############
java -jar ${picard_path} MarkDuplicates I=${bam_info}.s.bam O=${bam_info}.sm.bam M=${bam_info}.markdup_metrics.txt
############
samtools index ${bam_info}.sm.bam
############
java -jar ${gatk_path} -T RealignerTargetCreator -R ${ref_path} -I ${bam_info}.sm.bam -o ${bam_info}.IndelRealigner.intervals
java -Xmx4g -jar ${gatk_path} -T IndelRealigner -R ${ref_path} -I ${bam_info}.sm.bam -targetIntervals ${bam_info}.IndelRealigner.intervals -o ${bam_info}.smr.bam
############
java -jar ${gatk_path} -T HaplotypeCaller -R ${ref_path} -I ${bam_info}.smr.bam -stand_call_conf 50 -A QualByDepth -A RMSMappingQuality -A MappingQualityRankSumTest -A ReadPosRankSumTest -A FisherStrand -A StrandOddsRatio -A Coverage -o ${bam_info}.vcf
############
java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${bam_info}.vcf -selectType SNP -o ${align_path}snp_raw.vcf
java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${bam_info}.vcf -selectType INDEL -o ${align_path}indel_raw.vcf
############
java -Xmx8g -jar ${gatk_path} -T VariantFiltration -R ${ref_path} -V ${align_path}snp_raw.vcf --filterExpression "( vc.hasAttribute('QD') && QD<2.0 ) || FS > 60.0 || MQ < 40.0 || ( vc.hasAttribute('ReadPosRankSum' ) && ReadPosRankSum < -8.0 ) || ( vc.hasAttribute('MQRankSum') && MQRankSum < -12.5 ) || ( vc.hasAttribute('SOR') && SOR > 3.0 ) || QUAL < 30.0 " --filterName "my_snp_filter" -o ${align_path}snp_f.vcf
java -Xmx8g -jar ${gatk_path} -T VariantFiltration -R ${ref_path} -V ${align_path}indel_raw.vcf --filterExpression "( vc.hasAttribute('QD') && QD<2.0 ) || FS > 200.0 || ( vc.hasAttribute('InbreedingCoeff' ) && InbreedingCoeff < -0.8 ) || ( vc.hasAttribute('ReadPosRankSum' ) && ReadPosRankSum < -20.0 ) || ( vc.hasAttribute('SOR') && SOR > 10.0 ) || QUAL < 30.0 " --filterName "my_inddel_filter" -o ${align_path}indel_f.vcf
############
java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${align_path}snp_f.vcf --excludeFiltered -o ${align_path}snp_filter.vcf
java -jar ${gatk_path} -T SelectVariants -R ${ref_path} -V ${align_path}indel_f.vcf --excludeFiltered -o ${align_path}indel_filter.vcf

:<<EOF
#下回记得给参考基因组改名字！

nohup java -jar ./../biosoft/Trimmomatic-0.36/trimmomatic-0.36.jar PE -phred33 -trimlog logfile CBW-49_S56_L006_R1_001.fastq.gz CBW-49_S56_L006_R2_001.fastq.gz out.CBW-49_S56_L006_R1_001.fastq.gz out.trim.CBW-49_S56_L006_R1_001.fastq.gz out.CBW-49_S56_L006_R2_001.fastq.gz out.trim.CBW-49_S56_L006_R2_001.fastq.gz ILLUMINACLIP:./../biosoft/Trimmomatic-0.36/adapters/TruSeq3-PE.fa:2:30:10 SLIDINGWINDOW:5:20 LEADING:5 TRAILING:5 MINLEN:50 &

nohup bwa mem -t 4 -M -R '@RG\tID:L004\tPL:illumina\tLB:library\tSM:49_S51_L004' ./../../ref/ref_v2.0/branap_v2.0.fa ./../../data/49_S51_L004/out.CBW49_S51_L004_R1_001.fastq.gz ./../../data/49_S51_L004/out.CBW49_S51_L004_R2_001.fastq.gz > 49_S51_to_v20.sam &
nohup bwa mem -t 4 -M -R '@RG\tID:L004\tPL:illumina\tLB:library\tSM:49_S51_L004' ./../../ref/ref_v2.0/branap_v2.0.fa ./../../data/49_S51_L004/out.CBW49_S51_L004_R1_001.fastq.gz ./../../data/49_S51_L004/out.CBW49_S51_L004_R2_001.fastq.gz 1> 49_S51_to_v20.sam 2> log.txt &
#比上面更好，.sam之中没有运行信息
#-M参数最好加上

samtools view -bS .sam > .bam

java -jar /ifs1/Software/biosoft/picard/picard.jar SortSam I=49_S51_to_v20.bam O=49_S51_to_v20.s.bam SO=coordinate

java -jar /ifs1/Software/biosoft/picard/picard.jar MarkDuplicates I=49_S51_to_v20.s.bam O=49_S51_to_v20.sm.bam M=49_S51_to_v20.markdup_metrics.txt

nohup samtools index 49_S51_to_v20.sm.bam &

#这两步不能少
samtools faidx branap_v2.0.fa
java -jar /ifs1/Software/biosoft/picard/picard.jar CreateSequenceDictionary R=branap_v2.0.fa
#############
nohup java -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T RealignerTargetCreator -R ~/ref/ref_v2.0/branap_v2.0.fa -I 49_S51_to_v20.sm.bam -o 49_S51_to_v20.IndelRealigner.intervals &
#这一步之后出现了下面的信息，这是要过滤的节奏吗？？？这个过滤是指完全删掉还是仅仅是不参与局部重比对？？？完了看看bam文件的大小应该可以知晓
#看来是后者
NFO  23:01:38,647 MicroScheduler - 112040548 reads were filtered out during the traversal out of approximately 200411855 total reads (55.91%) 
    INFO  23:01:38,647 MicroScheduler -   -> 0 reads (0.00% of total) failing BadCigarFilter 
    INFO  23:01:38,647 MicroScheduler -   -> 6073969 reads (3.03% of total) failing BadMateFilter 
    INFO  23:01:38,647 MicroScheduler -   -> 32865988 reads (16.40% of total) failing DuplicateReadFilter 
    INFO  23:01:38,648 MicroScheduler -   -> 0 reads (0.00% of total) failing FailsVendorQualityCheckFilter 
    INFO  23:01:38,648 MicroScheduler -   -> 0 reads (0.00% of total) failing MalformedReadFilter 
    INFO  23:01:38,648 MicroScheduler -   -> 0 reads (0.00% of total) failing MappingQualityUnavailableFilter 
    INFO  23:01:38,648 MicroScheduler -   -> 73100591 reads (36.48% of total) failing MappingQualityZeroFilter 
    INFO  23:01:38,648 MicroScheduler -   -> 0 reads (0.00% of total) failing NotPrimaryAlignmentFilter 
    INFO  23:01:38,648 MicroScheduler -   -> 0 reads (0.00% of total) failing Platform454Filter 
    INFO  23:01:38,648 MicroScheduler -   -> 0 reads (0.00% of total) failing UnmappedReadFilter
INFO  14:27:23,541 MicroScheduler - 112772889 reads were filtered out during the traversal out of approximately 200411855 total reads (56.27%) 
#需要明确几点，为什么原始的reads有九千万条(还要乘以2)，这里是两亿条，因为一条reads可能比对到几个地方
#这里过滤的就是MappingQuality DuplicateRead BadMate不符合条件的比对情况
#局部重比对应该是针对剩下的44%
INFO  14:27:23,541 MicroScheduler - 112772889 reads were filtered out during the traversal out of approximately 200411855 total r    eads (56.27%)
     36     INFO  14:27:23,541 MicroScheduler -   -> 0 reads (0.00% of total) failing BadCigarFilter
      37     INFO  14:27:23,541 MicroScheduler -   -> 6073969 reads (3.03% of total) failing BadMateFilter
       38     INFO  14:27:23,541 MicroScheduler -   -> 32865988 reads (16.40% of total) failing DuplicateReadFilter
        39     INFO  14:27:23,541 MicroScheduler -   -> 0 reads (0.00% of total) failing FailsVendorQualityCheckFilter
         40     INFO  14:27:23,541 MicroScheduler -   -> 0 reads (0.00% of total) failing MalformedReadFilter
          41     INFO  14:27:23,542 MicroScheduler -   -> 0 reads (0.00% of total) failing MappingQualityUnavailableFilter
           42     INFO  14:27:23,542 MicroScheduler -   -> 73100591 reads (36.48% of total) failing MappingQualityZeroFilter
            43     INFO  14:27:23,542 MicroScheduler -   -> 732341 reads (0.37% of total) failing NotPrimaryAlignmentFilter
             44     INFO  14:27:23,542 MicroScheduler -   -> 0 reads (0.00% of total) failing Platform454Filter
              45     INFO  14:27:23,542 MicroScheduler -   -> 0 reads (0.00% of total) failing UnmappedReadFilter
#这是加了M之后得到的，不参与局部重比对的记录，多了一个failing NotPrimaryAlignmentFilter

nohup java -Xmx4g -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T IndelRealigner -R ~/ref/ref_v2.0/branap_v2.0.fa -I 49_S51_to_v20.sm.bam -targetIntervals 49_S51_to_v20.IndelRealigner.intervals -o 49_S51_to_v20.smr.bam &
INFO  03:26:17,033 MicroScheduler - 0 reads were filtered out during the traversal out of approximately 199617469 total reads (0.00%) 
INFO  03:26:17,034 MicroScheduler -   -> 0 reads (0.00% of total) failing BadCigarFilter 
INFO  03:26:17,034 MicroScheduler -   -> 0 reads (0.00% of total) failing MalformedReadFilter
#出现了这些信息
INFO  18:02:27,534 MicroScheduler - 0 reads were filtered out during the traversal out of approximately 199617469 total reads (0.00%) 
    INFO  18:02:27,534 MicroScheduler -   -> 0 reads (0.00% of total) failing BadCigarFilter 
    INFO  18:02:27,534 MicroScheduler -   -> 0 reads (0.00% of total) failing MalformedReadFilter
#这是加了M之后得到的

#call variation 这一步可能需要两三天
nohup java -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T HaplotypeCaller -R ~/ref/ref_v2.0/branap_v2.0.fa -I 49_S51_to_v20.smr.bam -stand_call_conf 50 -A QualByDepth -A RMSMappingQuality -A MappingQualityRankSumTest -A ReadPosRankSumTest -A FisherStrand -A StrandOddsRatio -A Coverage -o 49_S51_to_v20.vcf &

#分开SNP INDEL
nohup java -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T SelectVariants -R ~/ref/ref_v2.0/branap_v2.0.fa -V 49_S56_to_v20.vcf -selectType SNP -o snp_raw.vcf &
nohup java -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T SelectVariants -R ~/ref/ref_v2.0/branap_v2.0.fa -V 49_S56_to_v20.vcf -selectType INDEL -o indel_raw.vcf &
#按照官方标准过滤一遍，此时只是标记出来
nohup java -Xmx8g -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T VariantFiltration -R ~/ref/ref_v2.0/branap_v2.0.fa -V snp_raw.vcf --filterExpression "( vc.hasAttribute('QD') && QD<2.0 ) || FS > 60.0 || MQ < 40.0 || ( vc.hasAttribute('ReadPosRankSum' ) && ReadPosRankSum < -8.0 ) || ( vc.hasAttribute('MQRankSum') && MQRankSum < -12.5 ) || ( vc.hasAttribute('SOR') && SOR > 3.0 ) || QUAL < 30.0 " --filterName "my_snp_filter" -o snp_f.vcf &
nohup java -Xmx8g -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T VariantFiltration -R ~/ref/ref_v2.0/branap_v2.0.fa -V indel_raw.vcf --filterExpression "( vc.hasAttribute('QD') && QD<2.0 ) || FS > 200.0 || ( vc.hasAttribute('InbreedingCoeff' ) && InbreedingCoeff < -0.8 ) || ( vc.hasAttribute('ReadPosRankSum' ) && ReadPosRankSum < -20.0 ) || ( vc.hasAttribute('SOR') && SOR > 10.0 ) || QUAL < 30.0 " --filterName "my_inddel_filter" -o indel_f.vcf &
#删除已经标记了的记录
nohup java -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T SelectVariants -R ~/ref/ref_v2.0/branap_v2.0.fa -V snp_f.vcf --excludeFiltered -o snp_filter.vcf &
nohup java -jar ~/GenomeAnalysisTK-3.4-0/GenomeAnalysisTK.jar -T SelectVariants -R ~/ref/ref_v2.0/branap_v2.0.fa -V indel_f.vcf --excludeFiltered -o indel_filter.vcf &
EOF
