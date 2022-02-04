#!/usr/bin/env python

# splits a very large output bowtie file into smaller ones for faster parsing and easier memory management.

import os
import argparse


def get_prefix_from_line(line):
    """ 
    From a bowtie1 output tsv file, return the prefix of the UMI associated with the read. 
    RELIES HEAVILY ON THE READ NAME STRUCTURE AND LINE 
    ie. K00180:778:HYGGKBBXX:4:1101:17797:37607_GAATACCCAG#19,
    
    hsa-miR-95-3p MIMAT0000094 Homo sapiens miR-95-3p       +       K00180:778:HYGGKBBXX:4:1101:17797:37607_GAATACCCAG#19   2       TTCAACGGGTATTTATTGAGCA  IIIIIIIIIIIIIIIIIIIIII  66
    """
    return line.split('\t')[2].split('_')[1][:2]
    
def split_file(fn):
    """
    adds a number of bases to both ends of a fasta file
    :param fn: string
        name of input fasta file
    :param fo: string
        name of output padded fasta file
    :return:
    """
    split_files = {}
    for pos1 in ['A', 'C', 'G', 'N', 'T']:
        for pos2 in ['A', 'C', 'G', 'N', 'T']:
            split_files['{}{}'.format(pos1, pos2)] = open(os.path.join(os.path.basename(fn) + '.{}{}.tmp'.format(pos1, pos2)), 'w') # removing output directory since this screws with CWL
    
    with open(fn, 'r') as f:
        for line in f:
            prefix = get_prefix_from_line(line)
            split_files[prefix].write(line)
            
    for pos1 in ['A', 'C', 'G', 'N', 'T']:
        for pos2 in ['A', 'C', 'G', 'N', 'T']:
            split_files['{}{}'.format(pos1, pos2)].close()
            
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--in_file",
        required=True,
    )
    # parser.add_argument(
    #     "--out_directory",
    #     required=False,
    #     default=None
    # )
    

    # Process arguments
    args = parser.parse_args()
    in_file = args.in_file
    # out_directory = args.out_directory if args.out_directory is not None else os.path.dirname(in_file)
    # main func
    split_file(
        fn=in_file,
    #     out_dir=out_directory
    )

if __name__ == "__main__":
    main()
