#!/usr/bin/env cwltool

cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:

  a_adapters:
    type: File
  read1:
    type: File
    
outputs:

  output_trim_first:
    type: File[]
    outputSource: step_gzip_trim_first/gzipped
  output_trim_first_metrics:
    type: File
    outputSource: step_trim/output_trim_report
  output_trim_first_fastqc_report:
    type: File
    outputSource: step_fastqc_trim/output_qc_report
  output_trim_first_fastqc_stats:
    type: File
    outputSource: step_fastqc_trim/output_qc_stats
    
  output_trim_again:
    type: File[]
    outputSource: step_sort_trimmed_fastq/output_fastqsort_sortedfastq
  output_trim_again_metrics:
    type: File
    outputSource: step_trim_again/output_trim_report
  output_trim_again_fastqc_report:
    type: File
    outputSource: step_fastqc_trim_again/output_qc_report
  output_trim_again_fastqc_stats:
    type: File
    outputSource: step_fastqc_trim_again/output_qc_stats
    
steps:

###########################################################################
# Parse adapter files to array inputs
###########################################################################

  get_a_adapters:
    run: file2stringArray.cwl
    in:
      file: a_adapters
    out:
      [output]

###########################################################################
# Trim
###########################################################################

  step_trim:
    run: trim_se.cwl
    in:
      input_trim: 
        source: read1
        valueFrom: ${ return [ self ]; }
      input_trim_overlap_length: 
        default: "1"
      input_trim_a_adapters: get_a_adapters/output
      times:
        default: "1"
      error_rate: 
        default: "0.1"
    out: [output_trim, output_trim_report]
  
  step_gzip_trim_first:
    run: gzip.cwl
    scatter: input
    in:
      input: step_trim/output_trim
    out: [gzipped]
      
  step_trim_again:
    run: trim_se.cwl
    in:
      input_trim: step_trim/output_trim
      input_trim_overlap_length: 
        default: "5"
      input_trim_a_adapters: get_a_adapters/output
      times:
        default: "1"
      error_rate: 
        default: "0.1"
    out: [output_trim, output_trim_report]
  
  step_sort_trimmed_fastq:
    run: fastqsort.cwl
    scatter: input_fastqsort_fastq
    in:
      input_fastqsort_fastq: step_trim_again/output_trim
    out:
      [output_fastqsort_sortedfastq]
  
  step_gzip_trim_again:
    run: gzip.cwl
    scatter: input
    in:
      input: step_sort_trimmed_fastq/output_fastqsort_sortedfastq
    out: [gzipped]

      
###########################################################################
# FastQC
###########################################################################
  step_fastqc_trim:
    run: wf_fastqc.cwl
    in:
      reads: 
        source: step_gzip_trim_first/gzipped
        valueFrom: |
          ${
            return self[0];
          }
    out: [output_qc_report, output_qc_stats]
      
  step_fastqc_trim_again:
    run: wf_fastqc.cwl
    in:
      reads: 
        source: step_gzip_trim_again/gzipped
        valueFrom: |
          ${
            return self[0];
          }
    out: [output_qc_report, output_qc_stats]
    
doc: |
  This workflow takes in appropriate trimming params and reads,
  and performs the following steps in order: trimx1, trimx2, fastq-sort
