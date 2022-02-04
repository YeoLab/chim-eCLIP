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
  
  samples:
    type:
      type: array
      items:
        type: array
        items:
          type: record
          fields:
            bam:
              type: File

  species:
    type: string
  exclude_regions_file:
    type: File
  chrom_sizes:
    type: File
    
outputs:

  ### Peak outputs ###


  output_clipper_bed:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_clipper_bed
  output_inputnormed_peaks:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_inputnormed_peaks
  output_compressed_peaks:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_compressed_peaks

  ### Downstream ###
  
  output_excluded_regions_bed:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_excluded_regions_bed
  output_narrowpeak:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_narrowpeak
  output_fixed_bed:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_fixed_bed
  output_bigbed:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_bigbed
  output_entropynum:
    type: File[]
    outputSource: wf_clashseqcore_total_normalize/output_entropynum
    
steps:

  wf_clashseqcore_total_normalize:
    run: wf_clashseqcore_total_normalize.cwl
    scatter: sample
    in:
      sample: samples
      species: species
      exclude_regions_file: exclude_regions_file
      chrom_sizes: chrom_sizes
    out: [
      output_clipper_bed,
      output_inputnormed_peaks,
      output_compressed_peaks,
      output_excluded_regions_bed,
      output_narrowpeak,
      output_fixed_bed,
      output_bigbed,
      output_entropynum
    ]
doc: |
  This workflow calls CLIPper and normalizes over a Size-matched input background.
