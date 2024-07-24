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
| `--skip_ivar_trim` | skip primer clipping step |

## Custom primers options
|Option|Explanation|
|------|-----------|
| `--ref_RSVA` | RSVA reference fasta with ">RSVA" as header |
| `--primer_bed_RSVA` | RSVA primer bed file, "_LEFT" denotes forward primers, "_RIGHT" denotes reverse primers |
| `--ref_gff_RSVA` | RSVA gff file |
| `--bowtie2_index_RSVA` | directory containing bowtie2 index for RSVA reference |
| `--RSVA_F_coord` | fusion gene coordinates in RSVA reference |
| `--RSVA_F_length` | RSVA fusion gene length |
| `--ref_RSVB` | RSVB reference fasta with ">RSVB" as header |
| `--primer_bed_RSVB` | RSVB primer bed file, "_LEFT" denotes forward primers, "_RIGHT" denotes reverse primers |
| `--ref_gff_RSVB` | RSVB gff file |
| `--bowtie2_index_RSVB` | directory containing bowtie2 index for RSVB reference |
| `--RSVB_F_coord` | fusion gene coordinates in RSVB reference |
| `--RSVB_F_length` | RSVB fusion gene length |
| `--fasta` | fasta file of RSVA and RSVB references |
