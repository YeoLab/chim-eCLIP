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

  sample:
    type:
      # array of 2, one IP one Input
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
    type: File
    outputSource: step_clipper/output_bed
  output_inputnormed_peaks:
    type: File
    outputSource: step_input_normalize_peaks/inputnormedBed
  output_compressed_peaks:
    type: File
    outputSource: step_compress_peaks/output_bed

  ### Downstream ###
  
  output_excluded_regions_bed:
    type: File
    outputSource: step_exclude_regions/output_excluded_regions_bed
  output_narrowpeak:
    type: File
    outputSource: step_bed_to_narrowpeak/output_narrowpeak
  output_fixed_bed:
    type: File
    outputSource: step_fix_bed_for_bigbed_conversion/output_fixed_bed
  output_bigbed:
    type: File
    outputSource: step_bed_to_bigbed/output_bigbed
  output_entropynum:
    type: File
    outputSource: step_calculate_entropy/output_entropynum
    
steps:

###########################################################################
# Peak calling
###########################################################################

  step_clipper:
    run: clipper.cwl
    in:
      species: species
      bam: 
        source: sample
        valueFrom: |
          ${
            return self[0].bam;
          }
      outfile:
        default: ""
    out:
      [output_bed]
  

###########################################################################
# Downstream
###########################################################################

  step_ip_mapped_readnum:
    run: samtools-mappedreadnum.cwl
    in:
      input: 
        source: sample
        valueFrom: |
          ${
            return self[0].bam;
          }
      readswithoutbits:
        default: 4
      count:
        default: true
      output_name:
        default: ip_mapped_readnum.txt
    out: [output]

  step_input_mapped_readnum:
    run: samtools-mappedreadnum.cwl
    in:
      input: 
        source: sample
        valueFrom: |
          ${
            return self[1].bam;
          }
      readswithoutbits:
        default: 4
      count:
        default: true
      output_name:
        default: input_mapped_readnum.txt
    out: [output]

  step_input_normalize_peaks:
    run: overlap_peakfi_with_bam.cwl
    in:
      clipBamFile: 
        source: sample
        valueFrom: |
          ${
            return self[0].bam;
          }
      inputBamFile: 
        source: sample
        valueFrom: |
          ${
            return self[1].bam;
          }
      peakFile: step_clipper/output_bed
      clipReadnum: step_ip_mapped_readnum/output
      inputReadnum: step_input_mapped_readnum/output
    out: [
      inputnormedBed,
      inputnormedBedfull
    ]

  step_compress_peaks:
    run: peakscompress.cwl
    in:
      input_bed: step_input_normalize_peaks/inputnormedBed
    out: [output_bed]
  
  step_sort_bed:
    run: sort-bed.cwl
    in:
      unsorted_bed: step_compress_peaks/output_bed
    out: [sorted_bed]
    
  step_exclude_regions:
    run: exclude-regions.cwl
    in:
      input_bed: step_sort_bed/sorted_bed
      exclude_regions_file: exclude_regions_file
    out: [output_excluded_regions_bed]
    
  step_bed_to_narrowpeak:
    run: bed_to_narrowpeak.cwl
    in:
      input_bed: step_exclude_regions/output_excluded_regions_bed
      species: species
    out: [output_narrowpeak]
    
  step_fix_bed_for_bigbed_conversion:
    run: fix_bed_for_bigbed_conversion.cwl
    in:
      input_bed: step_exclude_regions/output_excluded_regions_bed
    out: [output_fixed_bed]
    
  step_bed_to_bigbed:
    run: bed_to_bigbed.cwl
    in:
      input_bed: step_fix_bed_for_bigbed_conversion/output_fixed_bed
      chrom_sizes: chrom_sizes
    out: [output_bigbed]

  step_calculate_entropy:
    run: calculate_entropy.cwl
    in:
      full: step_input_normalize_peaks/inputnormedBedfull
      ip_mapped: step_ip_mapped_readnum/output
      input_mapped: step_input_mapped_readnum/output
    out: [output_entropynum]
    
doc: |
  This workflow takes in appropriate trimming params and reads,
  and performs the following steps in order: trimx1, trimx2, fastq-sort
