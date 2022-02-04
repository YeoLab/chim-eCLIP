#!/usr/bin/env python

from Bio import SeqIO
from Bio.Seq import Seq
# from Bio.Alphabet import generic_dna
import pandas as pd
import pysam
import sys
from collections import defaultdict, OrderedDict
# from future.utils import iteritems

import argparse


def revcomp(seq):
    new_seq = ""
    translation_dict = {'A':'T', 'C':'G', 'G':'C', 'T':'A', 'N':'N'}
    for character in reversed(list(seq)):
        new_seq = new_seq + translation_dict[character.upper()]
    return new_seq


def get_reference_seq_from_query(row):
    """
    From a bowtie standard output row, return the reference (read) sequence. 
    
    For eCLASH, 
     reference = read
     query = miR
     
    Bowtie outputs are formatted as follows:
    1.  Read name
    2.  Reference strand aligned to
    3.  Name of reference sequence where alignment occurs
    4.  0-based offset into the forward reference strand
    5.  Read sequence (reverse complemented if orientation is -)
    6.  ASCII-encoded read qualities
    7.  If -M was specified and the prescribed ceiling was exceeded for this read, this column
        contains the value of the ceiling, indicating that at least that many valid alignments
        were found in addition to the one reported.
    8.  Comma-separated list of mismatch descriptors. If no mismatch, this column is empty.
    :param row: string
        An 8-column row of a bowtie output file.
    :return ref_name: string
        reference name (if we are reverse-mapping miRs, this is the read name)
    :return rseq: string
        reference sequence, after accounting for mismatch/mutations in query
    :return strand: character
        positive or negative strand
    """

    # Collect columns.
    mir, strand, ref_name, offset0base, qseq, qualities, \
    alt_alignments, mutation_string = row.rstrip('\n').split('\t')

    rseq = qseq
    mutations = mutation_string.split(',') if mutation_string != "" else []
    for mutation in mutations:
        pos0base, change = mutation.split(':')
        ref, query = change.split('>')
        if strand == "-":
            pos0base = (len(rseq) - 1) - int(pos0base)
        else:
            pos0base = int(pos0base)

        rseq = rseq[:pos0base] + ref + rseq[pos0base + 1:]
        try:
            assert qseq[pos0base] == query
        except AssertionError:
            print(qseq, strand, pos0base, ref, query)
    
    if strand == '+':
        true_qseq = qseq
    elif strand == '-':
        true_qseq = revcomp(qseq)

    
    return ref_name, rseq, strand, mir, true_qseq


def get_reference_seq_from_sam_alignedsegment(aligned_segment):
    """
    From a pysam.AlignedSegment object, return the reference (read) sequence. 
    
    ** Expects the segment to be aligned to a reference, otherwise it will exit **
    
    For eCLASH, 
     reference = read
     query = miR
     
    Bowtie2 outputs are formatted as a standard SAM file (which must include MD tags!)
    :param aligned_segment: pysam.AlignedSegment
        an AlignedSegment object that contains read mapping information.
    :return ref_name: string
        reference name (if we are reverse-mapping miRs, this is the read name)
    :return rseq: string
        reference sequence, after accounting for mismatch/mutations in query
    :return strand: character
        positive or negative strand
    """
    
    ref_name = aligned_segment.reference_name
    try:
        ref_seq = aligned_segment.get_reference_sequence().upper()
    except ValueError:
        print(aligned_segment)
        sys.exit(1)
    mir = aligned_segment.query_name
    if aligned_segment.is_reverse:
        strand = "-"
    else:
        strand = "+"
    
    return ref_name, ref_seq, strand, mir
        
        
def get_rnames_and_rseq_fragments_from_bowtie_output(fn):
    """
    From a bowtie output tsv file, return the reference (read) sequence 
    and strand as a dictionary, with the reference name as key.
    That means duplicate reference names will be collapsed into one.

    :param fn: string
        path to the bowtie output tsv file
    :return rnames: defaultdict(dict)
        dictionary of [readname]:{"fragment":sequence, "strand":strand}
    :return metrics: pandas.DataFrame()
        dataframe of read names and the number of times a miR aligned to each.
        Since we are keeping only a single miR per read, this is useful for
        determining how many miRs aligned to each (read->miR is many-to-many,
        we are turning that into one-to-many).
    """
    rnames = defaultdict(dict) # {readname:{fragment:read fragment, strand:read strand, mir:miRNA name}}
    metrics = defaultdict(int) # {readname:number of miRs aligned to the read}
    
    with open(fn, 'r') as f:
        for line in f:
            rname, rseq, strand, mir, true_qseq = get_reference_seq_from_query(line)

            # kind of a hack to get around the fasta2collapse.pl appended '#'
            assert rname.count('#') == 1
            rname = rname.split('#')[0]
            # This is where the collapse happens.
            rnames[rname] = {"fragment":rseq, "strand":strand, "mir":mir, "true_qseq":true_qseq} # may need to change based on read names
            metrics[rname] += 1

    metrics = pd.DataFrame(metrics, index=['count']).T
    return rnames, metrics


def get_rnames_and_rseq_fragments_from_bowtie2_output(fn):
    """
    From a bowtie2 bam file, return the reference (read) sequence 
    and strand as a dictionary, with the reference name as key.
    That means duplicate reference names will be collapsed into one.

    :param fn: string
        path to the bowtie output tsv file
    :return rnames: defaultdict(dict)
        dictionary of [readname]:{"fragment":sequence, "strand":strand}
    :return metrics: pandas.DataFrame()
        dataframe of read names and the number of times a miR aligned to each.
        
        ** This counts both primary and secondary alignments. **
        
        Since we are keeping only a single miR per read, this is useful for
        determining how many miRs aligned to each (read->miR is many-to-many,
        we are turning that into one-to-many).
    """
    rnames = defaultdict(dict) # {readname:{fragment:read fragment, strand:read strand, mir:miRNA name}}
    metrics = defaultdict(int) # {readname:number of miRs aligned to the read}
    
    samfile = pysam.AlignmentFile(fn, "r")
    for read in samfile:
        if read.is_unmapped:
            pass
        else:
            rname, rseq, strand, mir = get_reference_seq_from_sam_alignedsegment(read)
            # kind of a hack to get around the fasta2collapse.pl appended '#'
            assert rname.count('#') == 1
            rname = rname.split('#')[0]
            metrics[rname] += 1
            
            # only count the mirs that are primary alignments in rnames
            if read.is_secondary:
                pass
            else:
                rnames[rname] = {"fragment":rseq, "strand":strand, "mir":mir} # may need to change based on read names
            
    metrics = pd.DataFrame(metrics, index=['count']).T
    return rnames, metrics

def get_name2seq_dict(fa_file, rnames):
    """
    Takes a fasta file and a dictionary of names,
    returns a dictionary containing {read_name:sequence}

    :param fa_file: string
        path to an un-collapsed fasta file
    :param rnames: defaultdict(dict)
        dictionary of rnames[read_name]:{"fragment":fragment, "strand":strand}
        where:
            read_name: name of the read, minus trailing '#' char which was originally appended by fasta2collapse.pl
            fragment: the reference fragment that was mapped
            strand: the reference strand aligned to (if miR was aligned to reverse strand read reference,
                     this will be -)
        see get_rnames_and_rseq_fragments_from_bowtie_output()
    :return name2seq_dict: defaultdict(dict)
        a dictionary that hashes read_names:{
            read_fragment: the mir-aligned piece within the reference read that was aligned
            read_sequence: the full read sequence (read_fragment should be fully contained within read_sequence)
            strand: carried over from rnames[read_name][strand]
        }
    :return seq2name_dict: defaultdict(str)
        a dictionary that essentially hashes sequence strings:read_names, used to look up values in name2seq_dict
        in add_duplicated_sequences_to_name2seq_dictionary()
    """

    counter = 0 # if it's a very large fasta file, need to measure
    name2seq_dict = OrderedDict() # every {read:sequence}
    seq2name_dict = OrderedDict() # every {sequence:read}
    read_names = set(rnames.keys())
    handle = open(fa_file, "rU")
    for record in SeqIO.parse(handle, "fasta"):
        if record.id in read_names:
            d = {
                "read_fragment":rnames[record.id]["fragment"],
                "read_sequence":str(record.seq),
                "strand":rnames[record.id]["strand"],
                "mir":rnames[record.id]["mir"],
                "true_qseq":rnames[record.id]["true_qseq"]
            }
            name2seq_dict[record.id] = d
            seq2name_dict[record.seq] = record.id
        if counter % 100000 == 0:
            print("Read {} records".format(counter))
        counter += 1
    handle.close()
    
    print("read names length: {}".format(len(read_names)))
    print("name2seq_dict length: {}".format(len(name2seq_dict.keys())))
    print("seq2name_dict length: {}".format(len(seq2name_dict.keys())))
    
    return name2seq_dict, seq2name_dict


def add_all_sequences_to_name2seq_dictionary(fa_file, name2seq_dict, seq2name_dict):
    """
    Since we have only reverse-mapped miRs to unique/collapsed reads, let's get all reads.
    To do this, we will be taking the dictionary of collapsed read names, extracting the full read
    sequences, and appending all read names (collapsed and uncollapsed) whose sequences match.

    :param fa_file: string
        path to an un-collapsed fasta file
    :param name2seq_dict: defaultdict(dict)
        a dictionary that hashes read_names:{
            read_fragment: the mir-aligned piece within the reference read that was aligned
            read_sequence: the full read sequence (read_fragment should be fully contained within read_sequence)
            strand: carried over from rnames[read_name][strand]
        }
    :param seq2name_dict: defaultdict(str)
        a dictionary that essentially hashes sequence strings:read_names, used to look up values in name2seq_dict
        in add_duplicated_sequences_to_name2seq_dictionary()
    :return all_name2seq_dict: defaultdict(str)
        a dictionary that hashes read_names:{
            read_fragment: the mir-aligned piece within the reference read that was aligned
            read_sequence: the full read sequence (read_fragment should be fully contained within read_sequence)
            strand: carried over from rnames[read_name][strand]
        }. This is identical format to name2seq_dict, except that it contains every read, instead of just the
        collapsed read information.
    """
    counter = 0
    all_seqs = set(seq2name_dict.keys())
    handle = open(fa_file, "rU")
    all_name2seq_dict = OrderedDict()


    for record in SeqIO.parse(handle, "fasta"):
        if str(record.seq) in all_seqs:
            assert str(record.seq) == name2seq_dict[seq2name_dict[str(record.seq)]]["read_sequence"]
            d = {
                "read_fragment":name2seq_dict[seq2name_dict[str(record.seq)]]["read_fragment"],
                "read_sequence":str(record.seq),
                "strand":name2seq_dict[seq2name_dict[str(record.seq)]]["strand"],
                "mir":name2seq_dict[seq2name_dict[str(record.seq)]]["mir"],
                "true_qseq":name2seq_dict[seq2name_dict[str(record.seq)]]["true_qseq"],
            }
            all_name2seq_dict[str(record.id)] = d
        # if counter % 100000 == 0:
        #     print("Read {} records".format(counter))
        counter += 1
    handle.close()
    print("all_name2seq_dict length: {}".format(len(all_name2seq_dict.keys())))
    return all_name2seq_dict


def write_candidate_chimeric_targets_to_file(name2seq, min_seq_len):
    """

    :param name2seq: defaultdict(str)
        a dictionary that hashes read_names:{
            read_fragment: the mir-aligned piece within the reference read that was aligned
            read_sequence: the full read sequence (read_fragment should be fully contained within read_sequence)
            strand: carried over from rnames[read_name][strand]
        }.
    :param min_seq_len: int
        This is the minimum length a candidate upstream or downstream sequence must be before being
        returned as a candidate.
    :return l: string[]
        list of strings, where each string is a fasta record (multi-line), ">NAME\nSEQUENCE\n"
    """
    metrics = defaultdict(OrderedDict)
    l = []
    for rname, d in name2seq.items():
        to_append = None  # previously we were reporting a 
        rseq, offset = trim_n_and_return_leading_offset(d['read_fragment'])
        strand = d['strand']
        fullseq = d['read_sequence']
        mir = d['mir']
        true_qseq = d['true_qseq']
        
        try:
            assert fullseq.find(rseq) != -1  # cannot find the sequence, mutation must be wrong.
        except AssertionError:
            print("Cannot find sequence within the read! ({} not in {})".format(
                rseq, fullseq
            ))
            sys.exit(1)
        lo = fullseq[:fullseq.find(rseq)+offset]
        hi = fullseq[(fullseq.find(rseq)+offset + len(rseq)):]
        if strand == "-":
            upstream_seq = revcomp(hi)
            downstream_seq = revcomp(lo)
            rseq = revcomp(rseq)
        elif strand == "+":
            upstream_seq = lo
            downstream_seq = hi
        else:
            return 1
        
        if len(upstream_seq) >= min_seq_len:
            metrics[rname]['upstream_pass'] = "yes"
            to_append = ">{}\n{}\n".format(rname, upstream_seq) # we can also embed up/downstream or strandedness into the read, but for simplicity lets just keep the name
        else:
            metrics[rname]['upstream_pass'] = "no"
            
        if len(downstream_seq) >= min_seq_len:
            metrics[rname]['downstream_pass'] = "yes"
            if len(downstream_seq) >= len(upstream_seq):
                to_append = ">{}\n{}\n".format(rname, downstream_seq) # we can also embed up/downstream or strandedness into the read, but for simplicity lets just keep the name
        else:
            metrics[rname]['downstream_pass'] = "no"
        
        if to_append is not None:  # In the event of both upstream/downstream portions meeting the length requirements, we prioritize the downstream seq
            l.append(to_append)
            
        metrics[rname]['mir_alignment_strand'] = strand
        metrics[rname]['upstream'] = upstream_seq
        metrics[rname]['mir_aligned_segment'] = rseq
        metrics[rname]['mir_original_sequence'] = true_qseq
        metrics[rname]['mirname'] = mir
        metrics[rname]['downstream'] = downstream_seq
        metrics[rname]['fullread'] = fullseq

    metrics = pd.DataFrame(metrics).T
    print("METRICS")
    print(metrics.head())
    metrics = metrics[
        ['upstream_pass', 'downstream_pass', 'mir_alignment_strand', 'mirname', 
         'upstream', 'mir_aligned_segment', 'mir_original_sequence', 'downstream',
         'fullread']
    ]
    return l, metrics


def trim_n_and_return_leading_offset(s):
    """
    Trims the leading Ns and returns the number of Ns trimmed.
    Trims the trailing Ns but does not count this number.
    
    ** Only trims the leading and trailing Ns, ignores any 
    inline Ns. **
    """
    offset = len(s)-len(s.lstrip('N'))
    return s.strip('N'), offset
    

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
    parser.add_argument(
        "--inputfmt",
        required=False,
        default="tsv"
    )
    ### Process arguments ###
    args = parser.parse_args()
    bowtie_align = args.bowtie_align
    out_file = args.out_file
    fa_file = args.fa_file
    min_seq_len = args.min_seq_len
    metrics_file = args.metrics_file
    input_fmt = args.inputfmt
    ### main func ###
        
    # rnames : 
    # metrics1 :
    
    if input_fmt == "tsv":
        rnames, metrics1 = get_rnames_and_rseq_fragments_from_bowtie_output(fn=bowtie_align)
    elif input_fmt == "sam":
        rnames, metrics1 = get_rnames_and_rseq_fragments_from_bowtie2_output(fn=bowtie_align)
       
    if len(rnames.keys()) == 0: # hack to get around dealing with empty files
        with open(metrics_file, 'w') as f:
            pass
        with open(out_file, 'w') as f:
            pass
        sys.exit(0)
        
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
    merged_metrics.sort_index(inplace=True)
    merged_metrics.to_csv(metrics_file, sep='\t')
    
if __name__ == "__main__":
    main()
