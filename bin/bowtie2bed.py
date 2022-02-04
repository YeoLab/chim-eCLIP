#!/usr/bin/env python

import pandas as pd
from collections import defaultdict

import argparse


def bowtie2bed(fn, fo):
    """
    From a bowtie output (tsv, NOT sam) file, return a BED file.

    :param fn: string
        name of bowtie default output tsv file
    :param fo: string
        name of bedfile output to write
    :return:
    """
    bowtie_headers = [
        "read_name", "strand", "chrom", "start", "seq", "ascii_score", "alt_align", "mismatches"
    ]
    df = pd.read_csv(fn, names=bowtie_headers, sep="\t")
    df['len'] = df['seq'].apply(lambda x: len(x))
    df['read_name_fixed'] = df['read_name'].apply(lambda x: x.split("_")[0].split('#')[:-1])
    df['end'] =  df['start'] + df['len']
    df = df[['chrom','start','end','read_name_fixed','alt_align','strand']]
    df.to_csv(fo, sep="\t", header=False, index=False)

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--in_file",
        required=True,
    )
    parser.add_argument(
        "--out_file",
        required=True,
    )


    # Process arguments
    args = parser.parse_args()
    out_file = args.out_file
    in_file = args.in_file

    # main func
    bowtie2bed(
        fn=in_file,
        fo=out_file
    )

if __name__ == "__main__":
    main()
