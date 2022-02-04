#!/usr/bin/env cwltool

### space to remind me of what the metadata runner is ###

cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  speciesGenomeDir:
    type: Directory
  repeatElementGenomeDir:
    type: Directory
  a_adapters:
    type: File
  read1:
    type: File
  primer: 
    type: string
  chrom_sizes:
    type: File
  three_prime_umi_length: 
    type: int
    
outputs:

  output_trim_first:
    type: File[]
    outputSource: step_trim/output_trim_first
  output_trim_first_metrics:
    type: File
    outputSource: step_trim/output_trim_first_metrics
  output_trim_first_fastqc_report:
    type: File
    outputSource: step_trim/output_trim_first_fastqc_report
  output_trim_first_fastqc_stats:
    type: File
    outputSource: step_trim/output_trim_first_fastqc_stats
    
  output_maprepeats_mapped_to_genome:
    type: File
    outputSource: step_map/output_maprepeats_mapped_to_genome
  output_maprepeats_stats:
    type: File
    outputSource: step_map/output_maprepeats_stats
  output_maprepeats_star_settings:
    type: File
    outputSource: step_map/output_maprepeats_star_settings
  output_sort_repunmapped_fastq:
    type: File
    outputSource: step_map/output_sort_repunmapped_fastq

  output_mapgenome_mapped_to_genome:
    type: File
    outputSource: step_map/output_mapgenome_mapped_to_genome
  output_mapgenome_stats:
    type: File
    outputSource: step_map/output_mapgenome_stats
  output_mapgenome_star_settings:
    type: File
    outputSource: step_map/output_mapgenome_star_settings
  output_sorted_bam:
    type: File
    outputSource: step_map/output_sorted_bam

  output_rmdup_bam:
    type: File
    outputSource: step_map/output_rmdup_bam
  # output_rmdup_metrics:
  #   type: File
  #   outputSource: step_map/output_rmdup_metrics
  output_rmdup_sorted_bam:
    type: File
    outputSource: step_map/output_rmdup_sorted_bam
  
  output_pos_bw:
    type: File
    outputSource: step_map/output_pos_bw
  output_neg_bw:
    type: File
    outputSource: step_map/output_neg_bw
    
steps:

###########################################################################
# Trim
###########################################################################

  step_trim:
    run: wf_clashseq_trim.cwl
    in:
      a_adapters: a_adapters
      read1: read1
      three_prime_umi_length: three_prime_umi_length
    out: [
      output_trim_first,
      output_trim_first_metrics,
      output_trim_first_fastqc_report,
      output_trim_first_fastqc_stats,
      output_trim_first_unzipped
    ]
  
  filter_primers:
    run: filter_primers.cwl
    scatter: read1
    in:
      read1: step_trim/output_trim_first
      primer: primer
    out: [output_filtered]
  
  step_sort_trimmed_primer_filtered_fastq:
    run: fastqsort.cwl
    scatter: input_fastqsort_fastq
    in:
      input_fastqsort_fastq: filter_primers/output_filtered
    out:
      [output_fastqsort_sortedfastq]

###########################################################################
# Mapping
###########################################################################

  step_map:
    run: wf_clashseq_map_targeted.cwl
    in:
      chrom_sizes: chrom_sizes
      speciesGenomeDir: speciesGenomeDir
      repeatElementGenomeDir: repeatElementGenomeDir 
      reads: step_sort_trimmed_primer_filtered_fastq/output_fastqsort_sortedfastq
    out: [
      output_maprepeats_mapped_to_genome,
      output_maprepeats_stats,
      output_maprepeats_star_settings,
      output_sort_repunmapped_fastq,
      output_mapgenome_mapped_to_genome,
      output_mapgenome_stats,
      output_mapgenome_star_settings,
      output_sorted_bam,
      output_rmdup_bam,
      # output_rmdup_metrics,
      output_rmdup_sorted_bam,
      output_pos_bw,
      output_neg_bw
    ]
    
doc: |
  This workflow takes in appropriate trimming params and demultiplexed reads,
  and performs the following steps in order: trimx1, trimx2, fastq-sort, filter repeat elements, fastq-sort, genomic mapping, sort alignment, index alignment, namesort, PCR dedup, sort alignment, index alignment
