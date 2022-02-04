#!/usr/bin/env python

# adds a number of bases to both ends of a fasta file

import argparse


def add_to_fasta(fn, fo, n):
    """
    adds a number of bases to both ends of a fasta file
    :param fn: string
        name of input fasta file
    :param fo: string
        name of output padded fasta file
    :return:
    """
    seq = ""
    
    pad = "" 
    for i in range(n):
        pad += "N"
        
    with open(fo, 'w') as o:
        with open(fn, 'r') as f:
            o.write(f.readline())
            for line in f:
                if line.startswith('>'):
                    o.write("{}{}{}\n{}\n".format(pad, seq, pad, line.rstrip()))
                    seq = ""
                else:
                    seq += line.rstrip()
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
    parser.add_argument(
        "--n",
        required=False,
        default=5,
        type=int
    )

    # Process arguments
    args = parser.parse_args()
    out_file = args.out_file
    in_file = args.in_file
    n = args.n
    
    # main func
    add_to_fasta(
        fn=in_file,
        fo=out_file,
        n=n
    )

if __name__ == "__main__":
    main()
