#!/usr/bin/env python


# Dependent on Chimeric eCLIP read structure: 5’ - miRNA primer - RNA fragment - UMI (9nt) - Adapter - 3’
# Searches the beginning of R1 for the miR and filters out any read that lacks the primer.

import argparse
import os
from Bio import SeqIO, bgzf
from gzip import open as gzopen



def filter_reads(read1, output_file, primer, min_length=18):
    """
    Writes to output_file all reads that contain the primer sequence. Skips all other reads.
    Also trims the primer sequence before writing to output.
    """
    #r1 = gzip.open(read1, 'rt')
    records = SeqIO.parse(
        gzopen(read1, "rt"),
        format="fastq"
    )
    
    # with bgzf.BgzfWriter(output_file, "wb") as outgz:
    with open(output_file, 'w') as o:
        filtered_records = (
            rec[rec.seq.find(primer)+len(primer):]
            for rec in records
            if (rec.seq.find(primer) != -1) & (len(rec[rec.seq.find(primer)+len(primer):]) >= min_length)
        )
        
        SeqIO.write(sequences=filtered_records, handle=o, format="fastq")
                    
    
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--read1",
        required=True,
    )
    parser.add_argument(
        "--primer",
        required=True,
    )
    parser.add_argument(
        "--output_file",
        required=True,
    )
    
    # Process arguments
    args = parser.parse_args()
    read1 = args.read1
    primer = args.primer
    output_file = args.output_file
    
    # main func
    filter_reads(
        read1=read1,
        output_file=output_file,
        primer=primer
    )

if __name__ == "__main__":
    main()
