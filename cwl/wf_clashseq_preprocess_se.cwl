#!/usr/bin/env cwltool

### Workflow for handling reads containing one barcode ###

cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement      # TODO needed?
  - class: MultipleInputFeatureRequirement
  - class: InlineJavascriptRequirement
  
inputs:

  dataset_name:
    type: string

  ## end eCLIP-specific params ##

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
    
  ## Default trim params ##
  sort_names:
    type: boolean
    default: true
  trim_times:
    type: string
    default: "1"
  trim_error_rate:
    type: string
    default: "0.1"
  trimfirst_overlap_length:
    type: string
    default: "1"
        
outputs:

  b1_demuxed_fastq_r1:
    type: File
    outputSource: demultiplex/A_output_demuxed_read1

  b1_trimx1_fastq:
    type: File[]
    outputSource: X_trim/output_trim
  b1_trimx1_metrics:
    type: File
    outputSource: X_trim/output_trim_report
  b1_read1_fasta:
    type: File
    outputSource: step_fastq_to_fasta/output_fasta_file
  b1_collapsed_read1_fasta:
    type: File
    outputSource: step_fasta2collapse/collapsed_file

steps:

###########################################################################
# Upstream
###########################################################################

  demultiplex:
    run: wf_demultiplex_se.cwl
    in:
      dataset: dataset_name
      read: read
    out: [
      A_output_demuxed_read1,
      read_name,
      dataset_name
    ]

  
###########################################################################
# Parse adapter files to array inputs
###########################################################################

  get_a_adapters:
    run: file2stringArray.cwl
    in:
      file: 
        source: read
        valueFrom: |
          ${
            return self.adapters;
          }
    out:
      [output]

###########################################################################
# Trim
###########################################################################

  X_trim:
    run: trim_se.cwl
    in:
      input_trim: 
        source: demultiplex/A_output_demuxed_read1
        valueFrom: ${ return [ self ]; }
      input_trim_overlap_length: trimfirst_overlap_length
      input_trim_a_adapters: get_a_adapters/output
      times: trim_times
      error_rate: trim_error_rate
    out: [output_trim, output_trim_report]
  
  step_gzip_sort_X_trim:
    run: gzip.cwl
    scatter: input
    in:
      input: X_trim/output_trim
    out:
      - gzipped
  
  ### Trimming twice removes too many reads due to the new adapter. Deprecated step ###
  # X_trim_again:
  #   run: trim_se.cwl
  #   in:
  #     input_trim: X_trim/output_trim
  #     input_trim_overlap_length: trimagain_overlap_length
  #     input_trim_a_adapters: get_a_adapters/output
  #     times: trim_times
  #     error_rate: trim_error_rate
  #   out: [output_trim, output_trim_report]
  
  A_sort_trimmed_fastq:
    run: fastqsort.cwl
    scatter: input_fastqsort_fastq
    in:
      # input_fastqsort_fastq: X_trim_again/output_trim
      input_fastqsort_fastq: X_trim/output_trim
    out:
      [output_fastqsort_sortedfastq]
  
  ### Trimming twice removes too many reads due to the new adapter. Deprecated step ###
  # step_gzip_sort_X_trim_again:
  #   run: gzip.cwl
  #   scatter: input
  #   in:
  #     input: A_sort_trimmed_fastq/output_fastqsort_sortedfastq
  #   out:
  #     - gzipped
      
###########################################################################
# Collapse reads and reverse-map miRs
###########################################################################

  step_fastq_to_fasta:
    run: fastq2fasta.cwl
    in:
      fastq_file:
        source: A_sort_trimmed_fastq/output_fastqsort_sortedfastq
        valueFrom: |
          ${
            return self[0];
          }
    out:
      - output_fasta_file

  step_fasta2collapse:
    run: fasta2collapse.cwl
    in:
      input_file: step_fastq_to_fasta/output_fasta_file
    out:
      - collapsed_file