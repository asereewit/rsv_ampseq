# RSV-AMPSEQ
A nextflow pipeline for genome assembly and variants calling (fusion gene) of human respiratory syncytial virus amplicon sequencing

## Usage
Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation)

Install [`Docker`](https://docs.docker.com/engine/installation/)

Running the pipeline:

```
nextflow run asereewit/rsv_ampseq -r main -latest --input input_samplesheet.csv --output pipeline_output -profile docker
```

To run it on AWS, add your nextflow config for AWS using -c:

```
nextflow run asereewit/rsv_ampseq -r main -latest --input input_samplesheet.csv --output pipeline_output -profile docker -with-tower -c nextflow_aws.config
```

You can create a samplesheet using the bundled python script fastq_dir_samplesheet.py in bin folder, like this:

```
python fastq_dir_samplesheet.py fastq_dir samplesheet_name.csv
```

## Options
|Option|Explanation|
|------|-----------|
| `--input` | samplesheet in csv format with fastq information, samplesheet example: `assets/samplesheet.csv` |
| `--output` | output directory |
| `--skip_fastqc` | skip quality control using FastQC (default: false) |
| `--skip_fastp` | skip adapters and reads trimming using fastp (default: false) |
| `--trim_len` | minimum read length to keep (default:50) |
| `--min_trim_reads | mininum number of trimmed reads required for downstream processes (default: 0) |
| `--min_mapped_reads | minimum number of mapped reads for variants and consensus calling (default: 1000) |
| `--skip_ivar_trim` | skip primer clipping step |

## Custom primers options
|Option|Explanation|
|------|-----------|
| `--ref_RSVA` | RSVA reference fasta |
| `--primer_bed_RSVA` | RSVA primer bed file with "RSVA" as the header in the first column, "_LEFT" denotes forward primers, "_RIGHT" denotes reverse primers |
| `--ref_gff_RSVA` | RSVA gff file with "RSVA" as the header in the first column |
| `--RSVA_F_coord` | RSVA reference's fusion gene coordinates in the format of xxxx-yyyy (e.g. 5682-7406) |
| `--RSVA_F_length` | RSVA fusion gene length |
| `--ref_RSVB` | RSVB reference fasta |
| `--primer_bed_RSVB` | RSVB primer bed file with "RSVB" as the header in the first column, "_LEFT" denotes forward primers, "_RIGHT" denotes reverse primers |
| `--ref_gff_RSVB` | RSVB gff file with "RSVB" as the header in the first column |
| `--RSVB_F_coord` | RSVB reference's fusion gene coordinates in the format of xxxx-yyyy (e.g. 5717-7441) |
| `--RSVB_F_length` | RSVB fusion gene length |
