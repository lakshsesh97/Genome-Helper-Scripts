# Genome-Helper-Scripts
Small scripts to help with Genomics Projects

<h2>Calculate Variant Allele frequency from Bam file </h2>

**Useful for** 

Bash script for calculating VAF from BAM files with flexible mutation types (SNV, INS, DEL)

**Example:** 

```bash
./calculate_vaf_from_bam.sh --bam <file> --position <pos> --mutation-type <type> [--ref <file>]
Options:
  --bam              BAM file path
  --position, --pos  Position (e.g., chr1:12345-12345)
  --mutation-type, --type    Type: snv, ins, or del
  --ref, --reference Reference genome
  -h, --help         Show this help message

