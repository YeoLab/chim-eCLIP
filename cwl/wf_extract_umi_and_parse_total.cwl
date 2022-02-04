#!/usr/bin/env cwltool

cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: MultipleInputFeatureRequirement

inputs:

  dataset:
    type: string
  read:
    type:
      type: record
      fields:
        read1:
          type: File
        name:
          type: string
        adapters:
          type: File
          
outputs:

  output_read1:
    type: File
    outputSource: gzip/gzipped
  output_metrics:
    type: File
    outputSource: step_extract_umi/output_metrics
  read_name:
    type: string
    outputSource: step_extract_umi/name
  dataset_name:
    type: string
    outputSource: step_extract_umi/output_dataset


steps:

###########################################################################
# Upstream
###########################################################################
  step_extract_umi:
    run: extract_umi.cwl
    in:
      reads: read
      dataset: dataset
    out: [
      output_read1,
      output_metrics,
      output_dataset,
      name
    ]

###########################################################################
# Downstream
###########################################################################
  gzip:
    run: gzip.cwl
    in:
      input: step_extract_umi/output_read1
    out:
      - gzipped
        
doc: |
  This workflow takes in single-end reads, and performs the following steps in order:
  extracts 10NT UMI from Read1, gzips resulting file.
