# RSV-AMPSEQ
Nextflow pipeline for variants and consensus calling of human respiratory syncytial virus amplicon sequencing

## Usage
Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=21.10.3`)

Install [`Docker`](https://docs.docker.com/engine/installation/)

Running the pipeline:

```
nextflow run greninger-lab/rsv_ampseq --input input_samplesheet.csv --outdir pipeline_output -profile docker -with-tower
```

To run it on AWS, add your nextflow config for AWS using -c:

```
nextflow run greninger-lab/rsv_ampseq --input input_samplesheet.csv --outdir pipeline_output -profile docker -with-tower -c nextflow_aws.config
```

Samplesheet example: assets/samplesheet.csv

You can create a samplesheet using the python script fastq_dir_samplesheet.py in bin folder, like this:

```
python fastq_dir_samplesheet.py fastq_dir samplesheet_name.csv
```
