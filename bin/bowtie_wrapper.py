#!/usr/bin/env python

__author__ = 'byee4'

from subprocess import call
import subprocess
import os
import pysam
import argparse

def bowtie_build(fasta_file, log):
    bowtie_index_prefix = os.path.splitext(fasta_file)[0] + ".bowtie_index"
    priming_call = "bowtie-build --offrate 2 --threads 8 {} {}".format(
        fasta_file, bowtie_index_prefix
    )
    with open(log, 'w') as o:
        subprocess.check_call(priming_call, shell=True, stdout=o)
    return bowtie_index_prefix

def bowtie_map(fasta, index, output_tsv, log):
    priming_call = "bowtie -a -e 35 -f -l 8 -n 1 -p 8 {} {} {}".format(
        index, fasta, output_tsv
    )
    with open(log, 'w') as o:
        subprocess.check_call(priming_call, shell=True, stderr=o)


def main():
    parser = argparse.ArgumentParser(description="Builds a bowtie index and maps")
    parser.add_argument("--fasta", help="collapsed fasta file to build index on", required=True)
    parser.add_argument("--mir", help="miR fasta file to map", required=True)
    parser.add_argument("--output_tsv", help="output file", required=True)
    parser.add_argument("--output_index_log", help="output log for index", required=True)
    parser.add_argument("--output_map_log", help="output log for mapping", required=True)

    args = parser.parse_args()
    fasta_file = args.fasta
    mir = args.mir
    output_tsv = args.output_tsv
    output_index_log = args.output_index_log
    output_map_log = args.output_map_log
    
    index_prefix = bowtie_build(fasta_file=fasta_file, log=output_index_log)
    bowtie_map(fasta=mir, index=index_prefix, output_tsv=output_tsv, log=output_map_log)

if __name__ == "__main__":
    main()