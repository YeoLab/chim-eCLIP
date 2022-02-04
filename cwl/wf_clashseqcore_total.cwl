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
        adapters:
          type: File
        name:
          type: string
  mirna_fasta:
    type: File
  three_prime_umi_length:
    type: int
    
outputs:

  output_umi_extracted_read:
    type: File
    outputSource: step_extract_umi/output_read1

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
    
  output_read1_fasta:
    type: File
    outputSource: step_trim_and_map/output_read1_fasta
  output_collapsed_read1_fasta:
    type: File
    outputSource: step_trim_and_map/output_collapsed_read1_fasta
  output_bowtie_results:
    type: File
    outputSource: step_trim_and_map/output_bowtie_results
  output_bowtie_log:
    type: File
    outputSource: step_trim_and_map/output_bowtie_log
  output_filtered_bowtie_results:
    type: File
    outputSource: step_trim_and_map/output_filtered_bowtie_results
  output_chimeric_candidates:
    type: File
    outputSource: step_trim_and_map/output_chimeric_candidates
  output_chimeric_metrics:
    type: File
    outputSource: step_trim_and_map/output_chimeric_metrics

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
  output_rmdup_sorted_bam:
    type: File
    outputSource: step_trim_and_map/output_rmdup_sorted_bam
    
  output_pos_bw:
    type: File
    outputSource: step_trim_and_map/output_pos_bw
  output_neg_bw:
    type: File
    outputSource: step_trim_and_map/output_neg_bw
    
  output_eclip_repeats:
    type: File
    outputSource: step_trim_and_map/output_eclip_repeats
  output_eclip_repeats_stats:
    type: File
    outputSource: step_trim_and_map/output_eclip_repeats_stats
  output_eclip_repeats_unmapped_fastq:
    type: File
    outputSource: step_trim_and_map/output_eclip_repeats_unmapped_fastq
  
  output_eclip_genome:
    type: File
    outputSource: step_trim_and_map/output_eclip_genome
  output_eclip_sorted_genome:
    type: File
    outputSource: step_trim_and_map/output_eclip_sorted_genome
  output_eclip_genome_stats:
    type: File
    outputSource: step_trim_and_map/output_eclip_genome_stats

  output_eclip_rmdup_bam:
    type: File
    outputSource: step_trim_and_map/output_eclip_rmdup_bam
  output_eclip_rmdup_sorted_bam:
    type: File
    outputSource: step_trim_and_map/output_eclip_rmdup_sorted_bam
  
  output_eclip_pos_bw:
    type: File
    outputSource: step_trim_and_map/output_eclip_pos_bw
  output_eclip_neg_bw:
    type: File
    outputSource: step_trim_and_map/output_eclip_neg_bw
    
steps:

###########################################################################
# Upstream
###########################################################################

  step_extract_umi:
    run: wf_extract_umi_and_parse_total.cwl
    in:
      dataset: dataset
      read: read
    out: [
      output_read1,
      output_metrics,
      read_name,
      dataset_name
    ]

  step_trim_and_map:
    run: wf_clashseq_trim_and_map_total.cwl
    in:
      a_adapters: 
        source: read
        valueFrom: |
          ${
            return self.adapters;
          }
      read1: step_extract_umi/output_read1
      mirna_fasta: mirna_fasta
      speciesGenomeDir: speciesGenomeDir
      repeatElementGenomeDir: repeatElementGenomeDir
      chrom_sizes: chrom_sizes
      three_prime_umi_length: three_prime_umi_length
    out: [
      output_trim_first,
      output_trim_first_metrics,
      output_trim_first_fastqc_report,
      output_trim_first_fastqc_stats,
      output_read1_fasta,
      output_collapsed_read1_fasta,
      output_bowtie_results,
      output_bowtie_log,
      output_filtered_bowtie_results,
      output_chimeric_candidates,
      output_chimeric_metrics,
      output_maprepeats_mapped_to_genome,
      output_maprepeats_stats,
      output_maprepeats_star_settings,
      output_sort_repunmapped_fastq,
      output_mapgenome_mapped_to_genome,
      output_mapgenome_stats,
      output_mapgenome_star_settings,
      output_mapgenome_unmapped_chimeras,
      output_sorted_bam,
      output_rmdup_bam,
      # output_rmdup_metrics,
      output_rmdup_sorted_bam,
      output_pos_bw,
      output_neg_bw,
      output_eclip_repeats,
      output_eclip_repeats_stats,
      output_eclip_repeats_unmapped_fastq,
      output_eclip_genome,
      output_eclip_sorted_genome,
      output_eclip_genome_stats,
      output_eclip_rmdup_bam,
      output_eclip_rmdup_sorted_bam,
      output_eclip_pos_bw,
      output_eclip_neg_bw
    ]
