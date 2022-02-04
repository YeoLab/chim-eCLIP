#!/usr/bin/env cwltool

cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: InlineJavascriptRequirement

inputs:
  dataset:
    type: string

  speciesGenomeDir:
    type: Directory

  repeatElementGenomeDir:
    type: Directory

  species:
    type: string

  chrom_sizes:
    type: File
  
  samples:
    type: 
      type: array
      items:
        type: record
        fields:
          read1:
            type: File
          read2:
            type: File
          name: 
            type: string
          adapters:
            type: File
          primer:
            type: string

  three_prime_umi_length:
    type: int
    
outputs:

  output_umi_extracted_read:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_umi_extracted_read

  output_trim_first:
    type: 
      type: array
      items:
        type: array
        items: File
    outputSource: wf_clashseqcore_targeted/output_trim_first
  output_trim_first_metrics:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_trim_first_metrics
  output_trim_first_fastqc_report:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_trim_first_fastqc_report
  output_trim_first_fastqc_stats: 
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_trim_first_fastqc_stats
    
  output_maprepeats_mapped_to_genome:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_maprepeats_mapped_to_genome
  output_maprepeats_stats:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_maprepeats_stats
  output_maprepeats_star_settings:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_maprepeats_star_settings
  output_sort_repunmapped_fastq:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_sort_repunmapped_fastq

  output_mapgenome_mapped_to_genome:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_mapgenome_mapped_to_genome
  output_mapgenome_stats:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_mapgenome_stats
  output_mapgenome_star_settings:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_mapgenome_star_settings

  output_sorted_bam:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_sorted_bam

  # output_rmdup_metrics:
  #   type: File[]
  #   outputSource: wf_clashseqcore_targeted/output_rmdup_metrics

  output_rmdup_sorted_bam:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_rmdup_sorted_bam

  output_pos_bw:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_pos_bw
  output_neg_bw:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_neg_bw

  output_peakclusters:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_peakclusters
  
  output_merged_peakclusters:
    type: File[]
    outputSource: wf_clashseqcore_targeted/output_merged_peakclusters
    
steps:

###########################################################################
# Upstream
###########################################################################
  
  wf_clashseqcore_targeted:
    run: wf_clashseqcore_targeted.cwl
    scatter: read
    in:
      dataset: dataset
      speciesGenomeDir: speciesGenomeDir
      repeatElementGenomeDir: repeatElementGenomeDir
      species: species
      chrom_sizes: chrom_sizes
      read: samples
      three_prime_umi_length: three_prime_umi_length
    out: [
      output_umi_extracted_read,
      output_trim_first,
      output_trim_first_metrics,
      output_trim_first_fastqc_report,
      output_trim_first_fastqc_stats,
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
      output_neg_bw,
      output_peakclusters,
      output_merged_peakclusters
    ]
