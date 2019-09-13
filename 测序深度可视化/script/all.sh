###基本配置

#希望将结果保存在哪个目录下面？比如这里的home目录
sample_path=/ifs1/Grp3/huangsiyuan/
#样本名称为？比如这里的sample1，与${sample_path}组合得到：绝对路径的前缀
sample_name=${sample_path}sample1

#需要用到的三个文件
chr_name=/ifs1/Grp3/huangsiyuan/project/ref/ref_v2.0/chr_name_change.txt
bed_path=/ifs1/Grp3/huangsiyuan/project/ref/ref_v2.0/branap_v2.0.fa.bed
bam_path=/ifs1/Grp3/huangsiyuan/project/align/xxx.smr.bam

#这几个脚本所在的目录
script_path=/ifs1/Grp3/huangsiyuan/script/

###配置结束


cd ${script_path}

#perl脚本生成chr_to_50kb.bed
perl chr_to_50kb_window.pl ${bed_path}

less chr_to_50kb.bed | awk '{print $1"\t"$2"\t"$3"\t"$2/50000+1}' > chr_to_50kb.final.bed

samtools depth -b ${bed_path} ${bam_path} > ${sample_name}_base_depth.txt

#如果染色体的名称不规范，这里需要更改，用到chr_name_change.txt，该文件中有两列，第一列是旧名称，第二列是新名称
#原bed文件、chr_to_50kb.final.bed、${sample_name}_base_depth.txt三个文件中的染色体名称都要改
#如果染色体的名称规范，仍然需要准备chr_name_change.txt文件，只不过两列一样
cp ${chr_name} ./tmp0
old_name=$( head -n 1 tmp0 | cut -f1 )
new_name=$( head -n 1 tmp0 | cut -f2 )
rm -f ./tmp0

if [ ${old_name} != ${new_name} ]; then
    perl 3.pl ${chr_name} ${bed_path} > ${bed_path%.*}.rename.bed
    perl 3.pl ${chr_name} chr_to_50kb.final.bed > chr_to_50kb.final.rename.bed
    perl 3.pl ${chr_name} ${sample_name}_base_depth.txt > ${sample_name}_base_depth.rename.txt
else
    cp ${bed_path} ${bed_path%.*}.rename.bed
    cp chr_to_50kb.final.bed chr_to_50kb.final.rename.bed
    cp ${sample_name}_base_depth.txt ${sample_name}_base_depth.rename.txt
fi

awk '{print $1"_"int(($2-1)/50000)+1"\t"$3}' ${sample_name}_base_depth.rename.txt > tmp1

#生成tmp2
perl 1.pl

awk -F "_|\t" '{print $1"\t"$2"\t"$3/50000}' tmp2 | sort -k1,1 -k2,2n > tmp3

less chr_to_50kb.final.rename.bed | awk '{print $1"-"$4"\t"$2"-"$3}' > tmp4

#生成tmp5
perl 2.pl

awk -F "\t|-" '{OFS="\t";$1=$1;print $0}' tmp5 | cut -f1,3,4,5 > tmp6

awk '{if($4 > 100) print $1"\t"$2"\t"$3"\t100"}{if($4 <= 100) print $0}' tmp6 > ${sample_name}_depth_distribution.bed

rm -f tmp{1..6} ${sample_name}_base_depth* chr_to_50kb.*

#最终会得到两个文件一个是测序深度分布文件，存放在你最开始指定的目录下面；另一个是更改染色体名称后的bed文件，它与没有更改染色体名称的bed文件放在一个文件夹下面，在RStudio中画图会用到这两个文件
#后续画图可以在自己的Windows电脑上面操作，所以需要将上述两个生成的文件传到Windows电脑上去
#并且测序深度分布文件需要在第一行加上chr    start   end y1
