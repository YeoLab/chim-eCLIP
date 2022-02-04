#!/usr/bin/env python

# adds a number of bases to both ends of a fasta file

import argparse
import sys
import os
import pandas as pd
from collections import OrderedDict, defaultdict
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

###############################################################################
def parse_cutadapt_file(report, paired_end):
    #############################
    #print("parse_cutadapt_file report:", report)
    if os.path.getsize(report) == 0:
        return
    old_cutadapt = get_cutadapt_version(report) <= 8
    if paired_end:
        if old_cutadapt:
            return parse_old_cutadapt_file_pe(report)
        else:
            return parse_new_cutadapt_file(report)
    else:
        return parse_new_cutadapt_file(report)

###############################################################################
def get_cutadapt_version(report):
    ##############################
    with open(report) as file_handle:
            version = file_handle.next()
    try:
        version = version.split()[-4]
    except:
        1

    return int(version.split(".")[1])


###############################################################################
def parse_old_cutadapt_file_pe(report):
    ################################
    report_dir = {}
    try:
        with open(report) as report:
            report.next() #header
            report.next() #paramaters
            report.next() #max error rate
            report.next() #adapters (known already)
            processed_reads = [x.strip() for x in report.next().strip().split(":")]
            processed_bases = [x.strip() for x in report.next().strip().split(":")]
            trimmed_reads   = [x.strip() for x in report.next().strip().split(":")]
            quality_trimmed = [x.strip() for x in report.next().strip().split(":")]
            trimmed_bases   = [x.strip() for x in report.next().strip().split(":")]
            too_short_reads = [x.strip() for x in report.next().strip().split(":")]
            too_long_reads  = [x.strip() for x in report.next().strip().split(":")]
            total_time      = [x.strip() for x in report.next().strip().split(":")]
            time_pre_read   = [x.strip() for x in report.next().strip().split(":")]
            report_dir[processed_reads[0]] = int(processed_reads[1])
            report_dir[processed_bases[0]] = int(processed_bases[1].split()[0])
            report_dir[trimmed_reads[0]] = int(trimmed_reads[1].split()[0])
            report_dir[quality_trimmed[0]] = int(quality_trimmed[1].split()[0])
            report_dir[trimmed_bases[0]] = int(trimmed_bases[1].split()[0])
            report_dir[too_short_reads[0]] = int(too_short_reads[1].split()[0])
            report_dir[too_long_reads[0]] = int(too_long_reads[1].split()[0])
            report_dir[trimmed_bases[0]] = int(trimmed_bases[1].split()[0])
    except:
            print(report)
    return report_dir


###############################################################################

def parse_new_cutadapt_file(report):
    ################################
    report_dict = {}
    try:
        with open(report) as file_handle:
            remove_header(file_handle)
            processed_reads = get_number(file_handle.next())
            paired_file = processed_reads[0] == 'Total read pairs processed'
            if paired_file:
                r1_adapter = get_number_and_percent(file_handle.next())
                r2_adapter = get_number_and_percent(file_handle.next())
            else:
                adapter = get_number_and_percent(file_handle.next())

            too_short = get_number_and_percent(file_handle.next())
            written = get_number_and_percent(file_handle.next())
            file_handle.next()
            bp_processed = get_number(strip_bp(file_handle.next()))
            if paired_file:
                r1_bp_processed = get_number(strip_bp(file_handle.next()))
                r2_bp_processed = get_number(strip_bp(file_handle.next()))

            bp_quality_trimmed = get_number_and_percent(strip_bp(file_handle.next()))
            if paired_file:
                r1_bp_trimmed = get_number(strip_bp(file_handle.next()))
                r2_bp_trimmed = get_number(strip_bp(file_handle.next()))

            bp_written = get_number_and_percent(strip_bp(file_handle.next()))
            if paired_file:
                r1_bp_written = get_number(strip_bp(file_handle.next()))
                r2_bp_written = get_number(strip_bp(file_handle.next()))

    except Exception as e:
        print("exception occurred in cutadapt parsing: {}".format(e))
        print(report)
        return report_dict

    report_dict['Processed reads'] = processed_reads[1]
    if paired_file:
        report_dict["Read 1 with adapter"] = r1_adapter[1]
        report_dict["Read 1 with adapter percent"] = r1_adapter[2]
        report_dict["Read 2 with adapter"] = r2_adapter[1]
        report_dict["Read 2 with adapter percent"] = r2_adapter[2]
        report_dict['Read 1 basepairs processed'] = r1_bp_processed[1]
        report_dict['Read 2 basepairs processed'] = r2_bp_processed[1]
        report_dict['Read 1 Trimmed bases'] = r1_bp_trimmed[1]
        report_dict['Read 2 Trimmed bases'] = r2_bp_trimmed[1]
        report_dict['Read 1 {}'.format(bp_written[0])] = r1_bp_written[1]
        report_dict['Read 2 {}'.format(bp_written[0])] = r2_bp_written[1]
    else:
        report_dict['Reads with adapter'] = adapter[1]
        report_dict['Reads with adapter percent'] = adapter[2]


    report_dict['Too short reads'] = too_short[1]
    report_dict['Reads that were too short percent'] = too_short[2]
    report_dict['Reads Written'] = written[1]
    report_dict['Reads Written percent'] = written[2]
    report_dict['Processed bases'] = bp_processed[1]
    report_dict['Trimmed bases'] = bp_quality_trimmed[1]
    report_dict['Trimmed bases percent'] = bp_quality_trimmed[2]
    report_dict[bp_written[0]] = bp_written[1]
    report_dict["{} percent".format(bp_written[0])] = bp_written[2]
    return report_dict


###############################################################################
## parse_new_cutadapt_file utilities
######################################
def get_number_and_percent(line):
    """
    Parses cutadapt line containing a number (string) and returns
    number typecasted to int, as well as a percentage (float), as a list.

    :param line: basestring
    :return line: list
    """
    line = [x.strip() for x in line.strip().split(":")]

    line = [line[0]] + line[1].split()
    line[2] = float(line[2][1:-2])
    line[1] = int(line[1].replace(",", ""))
    return line


def get_number(line):
    """
    Parses cutadapt line containing a number (string) and returns
    number typecasted to int.

    :param line: basestring
    :return number: int
    """
    line = [x.strip() for x in line.strip().split(":")]
    line[1] = int(line[1].replace(",", ""))
    return line


def strip_bp(line):
    return line.replace("bp", "")


def remove_header(file_handle):
    """ for both SE and PE output removes header unifromly from cutadapt metrics file"""
    while not file_handle.next().startswith('=== Summary ==='):  # skip all lines up until it hits this Summary line
        continue
    file_handle.next()  # blank line after === Summary === line
    
    
def parse_star_file(star_file_name):
    with open(star_file_name) as star_file:
        star_dict = {}
        star_dict["Started job on"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Started mapping on"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Finished on"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Mapping speed, Million of reads per hour"] = star_file.next().strip().split("|")[1].strip()
        star_file.next()
        star_dict["Number of input reads"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["Average input read length"] = float(star_file.next().strip().split("|")[1].strip())
        star_file.next()
        star_dict["STAR genome uniquely mapped number"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["STAR genome uniquely mapped %"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Average mapped length"] = float(star_file.next().strip().split("|")[1].strip())
        star_dict["Number of splices: Total"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["Number of splices: Annotated (sjdb)"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["Number of splices: GT/AG"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["Number of splices: GC/AG"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["Number of splices: AT/AC"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["Number of splices: Non-canonical"] = int(star_file.next().strip().split("|")[1].strip())
        star_dict["Mismatch rate per base, percent"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Deletion rate per base"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Deletion average length"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Insertion rate per base"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Insertion average length"] = star_file.next().strip().split("|")[1].strip()
        star_file.next()
        star_dict["Number of reads mapped to multiple loci"] = star_file.next().strip().split("|")[1].strip()
        star_dict["% of reads mapped to multiple loci"] = star_file.next().strip().split("|")[1].strip()
        star_dict["Number of reads mapped to too many loci"] = star_file.next().strip().split("|")[1].strip()
        star_dict["% of reads mapped to too many loci"] = star_file.next().strip().split("|")[1].strip()
        star_file.next()
        star_dict["% of reads unmapped: too many mismatches"] = star_file.next().strip().split("|")[1].strip()
        star_dict["% of reads unmapped: too short"] = star_file.next().strip().split("|")[1].strip()
        star_dict["% of reads unmapped: other"] = star_file.next().strip().split("|")[1].strip()
    return star_dict

def get_read_num_from_fasta(fn):
    """
    Collects the number of reads in a fasta file.
    """
    count = 0
    with open(fn, 'r') as f:
        for line in f:
            if line.startswith('>'):
                count += 1
    return count

def parse_bowtie_metrics(fn):
    
    with open(fn, 'r') as f:
        for line in f:
            if line.startswith("# reads processed: "):
                reads_processed = int(line.rstrip().split("# reads processed: ")[1])
            elif line.startswith("# reads with at least one reported alignment: "):
                aligned = int(line.rstrip().split("# reads with at least one reported alignment: ")[1].split(' ')[0])
            elif line.startswith("# reads that failed to align: "):
                failed = int(line.rstrip().split("# reads that failed to align: ")[1].split(' ')[0])
            else:
                print("failed to parse bowtie file at line: {}".format(line))
                sys.exit(1)
    return reads_processed, aligned, failed

def parse_extract_candidate_metrics(fn):
    return pd.read_csv(fn, sep="\t").shape[0]

def parse_rmdup_metrics(fn):
    df = pd.read_csv(fn, sep="\t")
    return df['total_counts_post'].sum()


def plot_mir_alignment_positions_along_read(fn, ax=None):
    """
    mir_bowtie_metrics
    """
    bowtie_headers = [
        'miR_name',
        'read_strand',
        'read_name',
        'alignment_start',
        'miR_sequence',
        'alignment_quality',
        'align_other',
        'mismatch_desc'
    ]
    df = pd.read_csv(fn, sep="\t", names=bowtie_headers)
    
    if ax is None:
        fig, ax = plt.subplots()

    df['alignment_start'].value_counts().sort_index().plot(kind='bar', color='blue', alpha=0.5, ax=ax)
    ax.set_title("miR alignment positions")
    ax.set_xlabel("Position")
    ax.set_ylabel("Number of reads")
    
def generate_metrics(
    cutadapt1_metrics, cutadapt2_metrics, uncollapsed_fasta, collapsed_fasta, 
    mir_bowtie_output,
    extract_candidate_metrics, candidate_fa, star_genome_metrics, 
    rmdup_metrics):
    """
    
    """
    metrics = OrderedDict()
    
    cutadapt_round1_metrics_dict = parse_cutadapt_file(cutadapt1_metrics, paired_end=False) # parsed cutadapt metrics files
    cutadapt_round2_metrics_dict = parse_cutadapt_file(cutadapt2_metrics, paired_end=False) # parsed cutadapt metrics files
    read_num = get_read_num_from_fasta(uncollapsed_fasta) # number of uncollapsed reads after trimming
    collapsed_read_num = get_read_num_from_fasta(collapsed_fasta) # number of collapsed (unique) read sequences
    # mirs_queried, mirs_found, _ = parse_bowtie_metrics(mir_bowtie_metrics) # number of mirs queried
    star_genome_metrics_dict = parse_star_file(star_genome_metrics)
    candidate_read_num = get_read_num_from_fasta(candidate_fa)
    reads_containing_mirs = parse_extract_candidate_metrics(extract_candidate_metrics) # number of reads with mir
    # read_fragments_queried, genomic_mapped_reads, _ = parse_bowtie_metrics(candidate_bowtie_metrics) # number of upstream and downstream sequences
    genomic_mapped_reads_rmdup = parse_rmdup_metrics(rmdup_metrics) # 
    metrics['cutadapt1_reads_in'] = cutadapt_round1_metrics_dict['Processed reads']
    metrics['cutadapt1_reads_with_adapter'] = cutadapt_round1_metrics_dict['Reads with adapter']
    metrics['cutadapt1_too_short_reads'] = cutadapt_round1_metrics_dict['Too short reads']
    metrics['cutadapt1_too_short_reads_percent'] = cutadapt_round1_metrics_dict['Reads that were too short percent']
    metrics['cutadapt2_reads_in'] = cutadapt_round2_metrics_dict['Processed reads']
    metrics['cutadapt2_reads_with_adapter'] = cutadapt_round2_metrics_dict['Reads with adapter']
    metrics['cutadapt2_too_short_reads'] = cutadapt_round2_metrics_dict['Too short reads']
    metrics['cutadapt2_too_short_reads_percent'] = cutadapt_round2_metrics_dict['Reads that were too short percent']
    metrics['read_num'] = read_num
    metrics['collapsed_read_num'] = collapsed_read_num
    metrics['reads_containing_mirs'] = reads_containing_mirs
    metrics['candidate_flanking_sequences'] = candidate_read_num
    metrics['star_genome_uniquely_mapped'] = star_genome_metrics_dict['STAR genome uniquely mapped number']
    metrics['star_genome_uniquely_mapped_percent'] = star_genome_metrics_dict['STAR genome uniquely mapped %']
    metrics['star_genome_unmapped_too_many_mismatches'] = star_genome_metrics_dict['% of reads unmapped: too many mismatches']
    metrics['star_genome_unmapped_too_short'] = star_genome_metrics_dict['% of reads unmapped: too short']
    metrics['star_genome_unmapped_other'] = star_genome_metrics_dict['% of reads unmapped: other']
    return pd.DataFrame(metrics, index=["{}".format(os.path.basename(cutadapt1_metrics))]).T
    
def main():
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--out_file",
        required=True,
    )
    parser.add_argument(
        "--out_svg",
        required=True,
    )
    parser.add_argument(
        "--cutadapt_metrics",
        required=True,
        type=str
    )
    parser.add_argument(
        "--cutadapt2_metrics",
        required=True,
        type=str
    )
    parser.add_argument(
        "--uncollapsed_fasta",
        required=True,
        type=str
    )
    parser.add_argument(
        "--collapsed_fasta",
        required=True,
        type=str
    )
    parser.add_argument(
        "--mir_bowtie_output",
        required=False,
        type=str
    )
    parser.add_argument(
        "--extract_candidate_metrics",
        required=True,
        type=str
    )
    parser.add_argument(
        "--candidate_fa",
        required=True,
        type=str
    )
    parser.add_argument(
        "--star_genome_metrics",
        required=True,
        type=str
    )
    parser.add_argument(
        "--rmdup_metrics",
        required=True,
        type=str
    )
    
    # Process arguments
    args = parser.parse_args()
    out_file = args.out_file
    out_svg = args.out_svg
    cutadapt1_metrics = args.cutadapt_metrics
    cutadapt2_metrics = args.cutadapt2_metrics
    uncollapsed_fasta = args.uncollapsed_fasta
    collapsed_fasta = args.collapsed_fasta
    mir_bowtie_output = args.mir_bowtie_output
    extract_candidate_metrics = args.extract_candidate_metrics
    candidate_fa = args.candidate_fa
    star_genome_metrics = args.star_genome_metrics
    rmdup_metrics = args.rmdup_metrics
    # main func
    metrics = generate_metrics(
        cutadapt1_metrics, 
        cutadapt2_metrics, 
        uncollapsed_fasta, 
        collapsed_fasta, 
        mir_bowtie_output,
        extract_candidate_metrics, 
        candidate_fa, 
        star_genome_metrics, 
        rmdup_metrics
    )
    
    metrics.to_csv(
        out_file,
        sep="\t"
    )
    
    fig, ax = plt.subplots()
    plot_mir_alignment_positions_along_read(fn=mir_bowtie_output, ax=ax)
    fig.savefig(out_svg)
if __name__ == "__main__":
    main()
