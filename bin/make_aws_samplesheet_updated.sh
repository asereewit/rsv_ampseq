aws_dir=$1
r1_ext='L001_R1_001.fastq.gz'
r2_ext='L001_R2_001.fastq.gz'
aws s3 ls ${aws_dir} | grep "fastq.gz" | rev | cut -d " " -f1 | rev > aws_file_list.txt
echo "sample,fastq_1,fastq_2" > samplesheet.csv
IFS=$'\n\r'
for line in $(cat aws_file_list.txt | grep "${r1_ext}")
do
	base=`basename $line $r1_ext`
	echo "${base},${aws_dir}${base}${r1_ext},${aws_dir}${base}${r2_ext}" >> samplesheet.csv 
done
