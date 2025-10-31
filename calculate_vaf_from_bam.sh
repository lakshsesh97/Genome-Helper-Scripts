#!/bin/bash

#bam="$1"
#mut_type="$2"
#pos="$3"
#ref="/mnt/NFS/s-msp01/pathodata/DB/hg38/hg38.fa"
while [[ $# -gt 0 ]]; do
    case $1 in
        --bam)
            bam="$2"
            shift 2
            ;;
        --position|--pos)
            pos="$2"
            shift 2
            ;;
        --ref|--reference)
            ref="$2"
            shift 2
            ;;
        --mutation-type|--type)
            mut_type="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --bam <file> --position <pos> --mutation-type <type> [--ref <file>]"
            echo ""
            echo "Options:"
            echo "  --bam              BAM file path"
            echo "  --position, --pos  Position (e.g., chr1:12345-12345)"
            echo "  --mutation-type    Type: snv, ins, or del"
            echo "  --ref, --reference Reference genome"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [ -z "$bam" ]; then
    echo "Error: --bam is required"
    exit 1
fi

if [ -z "$pos" ]; then
    echo "Error: --position is required"
    exit 1
fi

if [ -z "$mut_type" ]; then
    echo "Error: --mutation-type is required"
    exit 1
fi

if [[ ! "$mut_type" =~ ^(snv|ins|del)$ ]]; then
    echo "Error: --mutation-type must be snv, ins, or del"
    exit 1
fi

if [ "$mut_type" == "snv" ]; then
	samtools mpileup -f "$ref" \
  -d 1000000 -r "$pos" -A -B "$bam" | \
	awk '{
    	ref=$3; bases=$5;
    	gsub(/\$/, "", bases);
	gsub(/\^./, "", bases);
    	refcount=(bases ~ /[.,]/ ? gsub(/[.,]/, "", bases) : 0);

    	altcount=0;
        bases_copy=$5;
        gsub(/\$/, "", bases_copy);
        gsub(/\^./, "", bases_copy);
        for (i=1; i<=length(bases_copy); i++) {
            b=toupper(substr(bases_copy, i, 1));
            if (b ~ /[ACGTN]/ && b != toupper(ref)) altcount++;
        }

        total=refcount + altcount;
        vaf=(total>0 ? (altcount/total)*100 : 0);
        printf("REF=%d  ALT=%d  TOTAL=%d  VAF=%.3f%%\n", refcount, altcount, total, vaf);
    }'

elif [ "$mut_type" == "ins" ]; then
	samtools mpileup -f "$ref" -d 1000000 -r "$pos" -A -B "$bam" | \
		awk '{
    ref=$3; bases=$5;
        bases_orig=bases;

        gsub(/\$/, "", bases);
        gsub(/\^./, "", bases);

        # Count insertions before removing them
        inscount=gsub(/\+[0-9]+[ACGTNacgtn]+/, "", bases);
        refcount=gsub(/[.,]/, "", bases);

        total=refcount + inscount;
        vaf=(total>0 ? (inscount/total)*100 : 0);
        printf("REF=%d  INS=%d  TOTAL=%d  VAF=%.3f%%\n", refcount, inscount, total, vaf);
    }'

elif [ "$mut_type" == "del" ]; then
	samtools mpileup -f "$ref" -d 1000000 -r "$pos" -A -B "$bam" | \
	awk '{
	ref=$3; bases=$5;

        gsub(/\$/, "", bases);
        gsub(/\^./, "", bases);

        # Count deletions before removing them
        delcount=gsub(/-[0-9]+[ACGTNacgtn]+/, "", bases);
        refcount=gsub(/[.,]/, "", bases);

        total=refcount + delcount;
        vaf=(total>0 ? (delcount/total)*100 : 0);
        printf("REF=%d  DEL=%d  TOTAL=%d  VAF=%.3f%%\n", refcount, delcount, total, vaf);
    }'

fi
