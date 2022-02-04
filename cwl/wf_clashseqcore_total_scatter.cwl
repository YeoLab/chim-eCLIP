#!/usr/bin/env cwltool

### Workflow for handling reads containing one barcode ###

cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement
  - class: InlineJavascriptRequirement
  
inputs:

  dataset_name:
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
          name:
            type: string
          adapters:
            type: File
  mirna_fasta:
    type: File
  three_prime_umi_length: 
    type: int
    
outputs:

  output_umi_extracted_read:
    type: File[]
    outputSource: wf_clashseqcore_total/output_umi_extracted_read

  output_trim_first:
    type:
      type: array
      items:
        type: array
        items: File
    outputSource: wf_clashseqcore_total/output_trim_first
  output_trim_first_metrics:
    type: File[]
    outputSource: wf_clashseqcore_total/output_trim_first_metrics
  output_trim_first_fastqc_report:
    type: File[]
    outputSource: wf_clashseqcore_total/output_trim_first_fastqc_report
  output_trim_first_fastqc_stats:
    type: File[]
    outputSource: wf_clashseqcore_total/output_trim_first_fastqc_stats
    
  ### REVERSE MAPPING OUTPUTS ###

  output_read1_fasta:
    type: File[]
    outputSource: wf_clashseqcore_total/output_read1_fasta
  output_collapsed_read1_fasta:
    type: File[]
    outputSource: wf_clashseqcore_total/output_collapsed_read1_fasta
  output_bowtie_results:
    type: File[]
    outputSource: wf_clashseqcore_total/output_bowtie_results
  output_bowtie_log:
    type: File[]
    outputSource: wf_clashseqcore_total/output_bowtie_log
  output_filtered_bowtie_results:
    type: File[]
    outputSource: wf_clashseqcore_total/output_filtered_bowtie_results
  output_chimeric_candidates:
    type: File[]
    outputSource: wf_clashseqcore_total/output_chimeric_candidates
  output_chimeric_metrics:
    type: File[]
    outputSource: wf_clashseqcore_total/output_chimeric_metrics
  output_maprepeats_mapped_to_genome:
    type: File[]
    outputSource: wf_clashseqcore_total/output_maprepeats_mapped_to_genome
  output_maprepeats_stats:
    type: File[]
    outputSource: wf_clashseqcore_total/output_maprepeats_stats
  output_maprepeats_star_settings:
    type: File[]
    outputSource: wf_clashseqcore_total/output_maprepeats_star_settings
  output_sort_repunmapped_fastq:
    type: File[]
    outputSource: wf_clashseqcore_total/output_sort_repunmapped_fastq
  output_mapgenome_mapped_to_genome:
    type: File[]
    outputSource: wf_clashseqcore_total/output_mapgenome_mapped_to_genome
  output_mapgenome_stats:
    type: File[]
    outputSource: wf_clashseqcore_total/output_mapgenome_stats
  output_mapgenome_star_settings:
    type: File[]
    outputSource: wf_clashseqcore_total/output_mapgenome_star_settings
  output_sorted_bam:
    type: File[]
    outputSource: wf_clashseqcore_total/output_sorted_bam
  output_rmdup_bam:
    type: File[]
    outputSource: wf_clashseqcore_total/output_rmdup_bam
  output_rmdup_sorted_bam:
    type: File[]
    outputSource: wf_clashseqcore_total/output_rmdup_sorted_bam
  output_pos_bw:
    type: File[]
    outputSource: wf_clashseqcore_total/output_pos_bw
  output_neg_bw:
    type: File[]
    outputSource: wf_clashseqcore_total/output_neg_bw
    
  output_eclip_repeats:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_repeats
  output_eclip_repeats_stats:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_repeats_stats
  output_eclip_repeats_unmapped_fastq:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_repeats_unmapped_fastq
  
  output_eclip_genome:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_genome
  output_eclip_sorted_genome:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_sorted_genome
  output_eclip_genome_stats:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_genome_stats

  output_eclip_rmdup_bam:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_rmdup_bam

  output_eclip_rmdup_sorted_bam:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_rmdup_sorted_bam
  
  output_eclip_pos_bw:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_pos_bw
  output_eclip_neg_bw:
    type: File[]
    outputSource: wf_clashseqcore_total/output_eclip_neg_bw

steps:

###########################################################################
# Upstream
###########################################################################
  
  wf_clashseqcore_total:
    run: wf_clashseqcore_total.cwl
    scatter: read
    in:
      read: samples
      dataset: dataset_name
      species: species
      mirna_fasta: mirna_fasta
      speciesGenomeDir: speciesGenomeDir
      repeatElementGenomeDir: repeatElementGenomeDir
      chrom_sizes: chrom_sizes
      three_prime_umi_length: three_prime_umi_length
    out: [
      output_umi_extracted_read,
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
      


###########################################################################
# Downstream (candidate for merging with main pipeline)
###########################################################################
