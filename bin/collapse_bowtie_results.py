#!/usr/bin/env python

from Bio import SeqIO
from Bio.Seq import Seq
from Bio.Alphabet import generic_dna
import pandas as pd
import pysam
import sys
from collections import defaultdict, OrderedDict

import argparse


def filter_mismatched_alignments(df):
    """
    Removes any alignment that contains more than the smallest number of mismatches.
    If there are two miRs that map to a single read, this function compares both 
    miRs and returns only the one(s) that have the least amount of mismatches.
    """
    print("Now filtering miRs with mismatches.")
    return df[df.groupby('ref_name')['mutation_num'].transform('min') == df['mutation_num']]


def filter_stranded_alignments(df):
    """
    This filters stranded alignments by returning only the rows
    whose int representation of strand (1 for +, -1 for -, 0 for ambiguous)
    is the highest. This will ensure that if a miR and its antisense both map 
    to the same read, that we will only choose the positive strand version 
    (idxmax selects the highest integer value within the group). If a read 
    just maps to the negative strand, it will not pass this filter.
    """
    print("Now filtering negative stranded miRs.")
    df = df[df['int_strand']==1]
    return df[df.groupby('ref_name')['int_strand'].transform('max') == df['int_strand']]


def return_mismatch_number(row):
    """
    Parses the number of mismatches found in the alignment, returning the number.
    """
    if type(row['mutation_string']) == float: # if it's NaN means no mismatches found.
        return 0
    mismatches = row['mutation_string'].split(',')
    return len(mismatches)


def strand2int(row):
    """
    returns 1 for positive strand, -1 for negative strand, 0 for ambiguous (anything else).
    """
    if row['strand'] == '+':
        return 1
    elif row['strand'] == '-':
        return -1
    else:
        print("Strand error: [{}], [{}]".format(row['ref_name'], row['strand']))
        sys.exit(1)
    
    
def collapse_bowtie_output(bowtie_align):
    bowtie_headers = [
        "mir", "strand", "ref_name", "offset0base", "qseq", "qualities",
        "alt_alignments", "mutation_string"
    ]
    df = pd.read_csv(bowtie_align, sep='\t', names=bowtie_headers)
    df['mutation_num'] = df.apply(return_mismatch_number, axis=1)
    df['int_strand'] = df.apply(strand2int, axis=1)
    
    dx = filter_stranded_alignments(df)
    dy = filter_mismatched_alignments(dx)
    dy = dy[bowtie_headers]
    return dy 


def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--bowtie_align",
        required=True,
    )
    parser.add_argument(
        "--out_file",
        required=True,
    )

    ### Process arguments ###
    args = parser.parse_args()
    bowtie_align = args.bowtie_align
    out_file = args.out_file
    ### main func ###
        
    # rnames : 
    # metrics1 :
    
    collapsed = collapse_bowtie_output(bowtie_align)
    collapsed.to_csv(out_file, sep='\t', index=False, header=False)
    
if __name__ == "__main__":
    main()
