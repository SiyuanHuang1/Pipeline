#先下载参考序列，课题组服务器里面有就不需要再次下载
#比如，服务器中参考序列的绝对路径是/ifs1/Grp3/huangsiyuan/project/ref/ref_v2.0/branap_v2.0.fa

#需要用到的软件的绝对路径。可以在软件的安装目录下面找到绝对路径，比如/ifs1/Software/biosoft/picard/就是安装目录，picard.jar是这个目录下面的软件，/ifs1/Software/biosoft/picard/picard.jar就是绝对路径。
#如果终端窗口下敲入`软件名`能显示软件使用的相关说明，表示该软件已经被添加到PATH环境变量，则不必要再在下方定义软件的绝对路径，比如`samtools`一般会包含在PATH中，所以此处没有写它的绝对路径
picard_path=/ifs1/Software/biosoft/picard/picard.jar

#先进入文件夹
cd /ifs1/Grp3/huangsiyuan/project/ref/ref_v2.0/

#创建索引
bwa index branap_v2.0.fa
samtools faidx branap_v2.0.fa
java -jar ${picard_path} CreateSequenceDictionary R=branap_v2.0.fa