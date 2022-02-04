#!/usr/bin/env cwltool

### space to remind me of what the metadata runner is ###

cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: InlineJavascriptRequirement

inputs:

  a_adapters:
    type: File
  read1:
    type: File
  mirna_fasta:
    type: File
  speciesGenomeDir:
    type: Directory
  chrom_sizes:
    type: File
  repeatElementGenomeDir:
    type: Directory
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
    
  output_read1_fasta:
    type: File
    outputSource: step_map/output_fasta
  output_collapsed_read1_fasta:
    type: File
    outputSource: step_map/output_collapsed_fasta

  output_bowtie_results:
    type: File
    outputSource: step_map/output_bowtie_results
  output_bowtie_log:
    type: File
    outputSource: step_map/output_bowtie_log
  output_filtered_bowtie_results:
    type: File
    outputSource: step_map/output_filtered_bowtie_results
    
  output_chimeric_candidates:
    type: File
    outputSource: step_map/output_chimeric_candidates
  output_chimeric_metrics:
    type: File
    outputSource: step_map/output_chimeric_metrics

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
  output_mapgenome_unmapped_chimeras:
    type: File
    outputSource: step_map/output_mapgenome_unmapped_chimeras
  
  output_sorted_bam:
    type: File
    outputSource: step_map/output_sorted_bam
    
  output_rmdup_bam:
    type: File
    outputSource: step_map/output_rmdup_bam
    
  output_rmdup_sorted_bam:
    type: File
    outputSource: step_map/output_rmdup_sorted_bam
  
  output_pos_bw:
    type: File
    outputSource: step_map/output_pos_bw
  output_neg_bw:
    type: File
    outputSource: step_map/output_neg_bw
  
  output_eclip_repeats:
    type: File
    outputSource: step_map/output_eclip_repeats
  output_eclip_repeats_stats:
    type: File
    outputSource: step_map/output_eclip_repeats_stats
  output_eclip_repeats_unmapped_fastq:
    type: File
    outputSource: step_map/output_eclip_repeats_unmapped_fastq
  
  output_eclip_genome:
    type: File
    outputSource: step_map/output_eclip_genome
  output_eclip_sorted_genome:
    type: File
    outputSource: step_map/output_eclip_sorted_genome
  output_eclip_genome_stats:
    type: File
    outputSource: step_map/output_eclip_genome_stats

  output_eclip_rmdup_bam:
    type: File
    outputSource: step_map/output_eclip_rmdup_bam

  output_eclip_rmdup_sorted_bam:
    type: File
    outputSource: step_map/output_eclip_rmdup_sorted_bam
  
  output_eclip_pos_bw:
    type: File
    outputSource: step_map/output_eclip_pos_bw
  output_eclip_neg_bw:
    type: File
    outputSource: step_map/output_eclip_neg_bw
    
steps:

###########################################################################
# Trim
###########################################################################

  step_trim:
    run: wf_clashseq_trim.cwl
    in:
      three_prime_umi_length: three_prime_umi_length
      a_adapters: a_adapters
      read1: read1
    out: [
      output_trim_first,
      output_trim_first_metrics,
      output_trim_first_fastqc_report,
      output_trim_first_fastqc_stats,
      output_trim_first_unzipped
    ]
      
###########################################################################
# Map
###########################################################################

  step_map:
    run: wf_clashseq_map_total.cwl
    in:
      reads: step_trim/output_trim_first_unzipped
      read_idx_name: 
        source: step_trim/output_trim_first_unzipped
        valueFrom: |
          ${
            return self[0].nameroot + ".bowtie_index";
          }
      mirna_fasta: mirna_fasta
      speciesGenomeDir: speciesGenomeDir
      repeatElementGenomeDir: repeatElementGenomeDir
      chrom_sizes: chrom_sizes
    out: [
      output_fasta,
      output_collapsed_fasta,
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

doc: |
  This workflow takes in appropriate trimming params and demultiplexed reads,
  and performs the following steps in order: trimx1, trimx2, fastq-sort, filter repeat elements, fastq-sort, genomic mapping, sort alignment, index alignment, namesort, PCR dedup, sort alignment, index alignment
