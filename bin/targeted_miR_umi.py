#!/usr/bin/env python

# Dependent on Chimeric eCLIP read structure: 5’ - miRNA primer - RNA fragment - UMI (9nt) - Adapter - 3’
# Grabs the first --umi_length nt of R2 as the UMI and appends to the end of the R1 name. 

import argparse
import os
from Bio import SeqIO
import gzip 

def add_umi_to_r1(read1, read2, output_file, umi_length):
    r1 = gzip.open(read1, 'rt')
    # r1 = open(read1, 'rb')
    with open(output_file, 'w') as r1_umi:
        with gzip.open(read2, 'rt') as r2:
        # with open(read2, 'r') as r2:
            for record in SeqIO.parse(r2, "fastq"):

                # print(record.id, r1.readline().split(' ')[0][1:])
                r1_header = r1.readline()
                r1_sequence = r1.readline()
                r1_next = r1.readline()
                r1_quality = r1.readline()


                r1_header_id, r1_header_desc = r1_header.split(' ')

                r1_header_id_no_at = r1_header_id[1:] # remove the "@" prefix
                assert record.id == r1_header_id_no_at # make sure that the read ids for r1 and r2 align to each other
                umi_sequence = str(record.seq)[:umi_length]

                r1_umi.write(r1_header_id + "_{} ".format(umi_sequence) + r1_header_desc)  # in umi_tools format.
                r1_umi.write(r1_sequence)
                r1_umi.write(r1_next)
                r1_umi.write(r1_quality)
                
    r1.close()
    
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--read1",
        required=True,
    )
    parser.add_argument(
        "--read2",
        required=True,
    )
    parser.add_argument(
        "--output_file",
        required=True,
    )
    parser.add_argument(
        "--umi_length",
        required=False,
        default=10
    )
    
    # Process arguments
    args = parser.parse_args()
    read1 = args.read1
    read2 = args.read2
    umi_length = args.umi_length
    output_file = args.output_file
    
    # main func
    add_umi_to_r1(
        read1=read1,
        read2=read2,
        output_file=output_file,
        umi_length=umi_length
    )

if __name__ == "__main__":
    main()
