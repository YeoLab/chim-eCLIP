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
        read2:
          type: File
        name:
          type: string
        adapters:
          type: File
        primer:
          type: string
outputs:

  post_umi_extracted_read:
    type: File
    outputSource: gzip/gzipped
  read_name:
    type: string
    outputSource: extract_umi/name
  dataset_name:
    type: string
    outputSource: extract_umi/output_dataset
  primer:
    type: string
    outputSource: extract_umi/primer

steps:

###########################################################################
# Upstream
###########################################################################
  extract_umi:
    run: extract_r2_umi.cwl
    in:
      read: read
      dataset: dataset
    out: [
      output_read1,
      output_dataset,
      name,
      primer
    ]
    
###########################################################################
# Downstream
###########################################################################
  gzip:
    run: gzip.cwl
    in:
      input: extract_umi/output_read1
    out:
      - gzipped
        
doc: ""