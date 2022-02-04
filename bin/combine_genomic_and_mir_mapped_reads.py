#!/usr/bin/env python

import pandas as pd
import numpy as np
import os
import glob
import pysam

import argparse

bowtie_headers = [
        "read_name", "strand", "chrom", "start", "sequence", "qual", "M", "mm"
    ]

def combine_genomic_and_mir_mapped_reads(metrics_fn, genomic_aln_fn):
    # parse metrics file
    metrics = pd.read_table(metrics_fn)
    
    ### Expects a read structure like: K00180:778:HYGGKBBXX:3:1219:9699:30398_CCCCCCCCCA
    metrics['randomer'] = metrics['Unnamed: 0'].apply(
        lambda x: x.split('_')[1]
    ) # get the randomer sequence

def combine_genomic_and_mir_mapped_reads_OLD(metrics_fn, genomic_aln_fn):
    # parse metrics file
    metrics = pd.read_table(metrics_fn)
    
    ### Expects a read structure like: K00180:778:HYGGKBBXX:3:1219:9699:30398_CCCCCCCCCA
    metrics['randomer'] = metrics['Unnamed: 0'].apply(
        lambda x: x.split('_')[1]
    ) # get the randomer sequence
    
    # parse genomic mapping bowtie output
    genomic_mapping = pd.read_table(genomic_aln_fn, names=bowtie_headers)
    
    ### Expects a read structure like: K00180:778:HYGGKBBXX:3:1219:9699:30398_CCCCCCCCCA
    genomic_mapping['Unnamed: 0'] = genomic_mapping['read_name'].apply(
        lambda x: x.split('_')[1]
    ) # get the read name + randomer
    
    genomic_mapping = genomic_mapping[['Unnamed: 0', 'chrom', 'start', 'strand']]
    
    # merge the two 
    merged = pd.merge(
        metrics, 
        genomic_mapping, 
        how='outer', 
        left_on=['Unnamed: 0'], 
        right_on=['Unnamed: 0']
    )
    
    merged = merged[['Unnamed: 0', 'count', 'mir', 'mirname', 'fullread', 'chrom', 'start', 'strand']]
    
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--bowtie_align",
        required=True,
    )
    parser.add_argument(
        "--fa_file",
        required=True,
    )
    parser.add_argument(
        "--out_file",
        required=True,
    )
    parser.add_argument(
        "--metrics_file",
        required=True,
    )
    parser.add_argument(
        "--min_seq_len",
        required=False,
        default=18
    )

    ### Process arguments ###
    args = parser.parse_args()
    bowtie_align = args.bowtie_align
    out_file = args.out_file
    fa_file = args.fa_file
    min_seq_len = args.min_seq_len
    metrics_file = args.metrics_file

    ### main func ###
    
    # rnames : 
    # metrics1 : 
    rnames, metrics1 = get_rnames_and_rseq_fragments_from_bowtie_output(fn=bowtie_align)
    name2seq_dict, seq2name_dict = get_name2seq_dict(fa_file=fa_file, rnames=rnames)
    
    all_name2seq_dict = add_all_sequences_to_name2seq_dictionary(
        fa_file=fa_file,
        name2seq_dict=name2seq_dict,
        seq2name_dict=seq2name_dict
    )

    lines, metrics2 = write_candidate_chimeric_targets_to_file(
        name2seq=all_name2seq_dict,
        min_seq_len=min_seq_len
    )
    assert len(lines) == len(set(lines)) # should always be unique

    with open(out_file, 'w') as o:
        for l in set(lines):
            o.write(l)

    merged_metrics = pd.merge(metrics1, metrics2, how='outer', left_index=True, right_index=True)
    merged_metrics.to_csv(metrics_file, sep='\t')

if __name__ == "__main__":
    main()
