#!/usr/bin/env cwltool

cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
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
  read:
    type:
      type: record
      fields:
        read1:
          type: File
        read2:
          type: File
        adapters:
          type: File
        name:
          type: string
        primer:
          type: string
  three_prime_umi_length: 
    type: int
    
outputs:

  output_umi_extracted_read:
    type: File
    outputSource: step_extract_umi/post_umi_extracted_read

  output_trim_first:
    type: File[]
    outputSource: step_trim_and_map/output_trim_first
  output_trim_first_metrics:
    type: File
    outputSource: step_trim_and_map/output_trim_first_metrics
  output_trim_first_fastqc_report:
    type: File
    outputSource: step_trim_and_map/output_trim_first_fastqc_report
  output_trim_first_fastqc_stats: 
    type: File
    outputSource: step_trim_and_map/output_trim_first_fastqc_stats
    
  output_maprepeats_mapped_to_genome:
    type: File
    outputSource: step_trim_and_map/output_maprepeats_mapped_to_genome
  output_maprepeats_stats:
    type: File
    outputSource: step_trim_and_map/output_maprepeats_stats
  output_maprepeats_star_settings:
    type: File
    outputSource: step_trim_and_map/output_maprepeats_star_settings
  output_sort_repunmapped_fastq:
    type: File
    outputSource: step_trim_and_map/output_sort_repunmapped_fastq

  output_mapgenome_mapped_to_genome:
    type: File
    outputSource: step_trim_and_map/output_mapgenome_mapped_to_genome
  output_mapgenome_stats:
    type: File
    outputSource: step_trim_and_map/output_mapgenome_stats
  output_mapgenome_star_settings:
    type: File
    outputSource: step_trim_and_map/output_mapgenome_star_settings
  output_sorted_bam:
    type: File
    outputSource: step_trim_and_map/output_sorted_bam

  output_rmdup_bam:
    type: File
    outputSource: step_trim_and_map/output_rmdup_bam
  # output_rmdup_metrics:
  #   type: File
  #   outputSource: step_trim_and_map/output_rmdup_metrics
  output_rmdup_sorted_bam:
    type: File
    outputSource: step_trim_and_map/output_rmdup_sorted_bam
    
  output_pos_bw:
    type: File
    outputSource: step_trim_and_map/output_pos_bw
  output_neg_bw:
    type: File
    outputSource: step_trim_and_map/output_neg_bw

  output_peakclusters:
    type: File
    outputSource: clipper/output_bed

  output_merged_peakclusters:
    type: File
    outputSource: merge_clipper/merged_bed
    
steps:

###########################################################################
# Upstream
###########################################################################

  step_extract_umi:
    run: wf_extract_umi_and_parse_targeted.cwl
    in:
      dataset: dataset
      read: read
    out: [
      post_umi_extracted_read,
      read_name,
      dataset_name,
      primer
    ]

  step_trim_and_map:
    run: wf_clashseq_trim_and_map_targeted.cwl
    in:
      chrom_sizes: chrom_sizes
      speciesGenomeDir: speciesGenomeDir
      repeatElementGenomeDir: repeatElementGenomeDir
      a_adapters: 
        source: read
        valueFrom: |
          ${
            return self.adapters;
          }
      read1: step_extract_umi/post_umi_extracted_read
      read_name: step_extract_umi/read_name
      dataset_name: step_extract_umi/dataset_name
      primer: step_extract_umi/primer
      three_prime_umi_length: three_prime_umi_length
    out: [
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
      output_neg_bw
    ]

  clipper:
    run: clipper.cwl
    in: 
      species: species
      bam: step_trim_and_map/output_rmdup_sorted_bam
    out: [
      output_bed
    ]
    
  merge_clipper:
    run: bedtools-merge.cwl
    in: 
      bed: clipper/output_bed
    out: [merged_bed]
