#!/usr/bin/env cwltool

cwlVersion: v1.0
class: Workflow

requirements:
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement      # TODO needed?
  - class: MultipleInputFeatureRequirement

inputs:
  filtered_bowtie_tsv:
    type: File
  output_fasta_file:
    type: File
  
  chimeric_candidates_filename:
    type: string
  chimeric_metrics_filename:
    type: string
  
outputs:

  chimeric_candidates_file:
    type: File
    outputSource: step_join_chimeric_outputs/concatenated
  metrics_file:
    type: File
    outputSource: step_join_chimeric_metrics/concatenated

steps:

  step_split_filtered_bowtie_output:
    run: split_bowtie.cwl
    in:
      bowtie_output: filtered_bowtie_tsv
    out: 
      - bowtie_splits
  
  step_find_chimeric_candidates:
    run: find_candidate_chimeric_seqs_from_mir_alignments.cwl
    scatter: bowtie_align
    in:
      bowtie_align: step_split_filtered_bowtie_output/bowtie_splits
      fa_file: output_fasta_file
    out:
      - chimeric_candidates_file
      - metrics_file
  
  step_join_chimeric_outputs:
    run: concatenate.cwl
    in:
      files: step_find_chimeric_candidates/chimeric_candidates_file
      concatenated_output: chimeric_candidates_filename
    out:
      - concatenated
  
  step_join_chimeric_metrics:
    run: concatenate.cwl
    in:
      files: step_find_chimeric_candidates/metrics_file
      concatenated_output: chimeric_metrics_filename
    out:
      - concatenated
      
doc: |
  This workflow used to be a single find_chimeric_candidates step, but 
  due to the inefficiency of the script, I need to first split into 
  several smaller files first. 
