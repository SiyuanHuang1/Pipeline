#原始测序数据的质量检测，这一步的目的是对测序质量有一个直观的认识，还有确定测序数据是否含有接头adapter及含有哪一种接头（这一点比较重要），
#因为后面会根据接头序列来确定是否过滤（切掉）一条测序reads的两端

data_path=/ifs1/Grp3/huangsiyuan/project/data/689/

fq1="689_R1.fq.gz" 
fq2="689_R2.fq.gz" 

fastqc_path=/ifs1/Software/bin/fastqc

cd ${data_path}
mkdir fastqc_report
${fastqc_path} ${fq1} ${fq2} -o ${data_path}fastqc_report

#之前我的毕业课题测序数据用的是二综的illumina测序平台，检测结果显示没有接头序列，这是希望的结果
#如果显示有接头，还需要进一步确定接头序列的种类