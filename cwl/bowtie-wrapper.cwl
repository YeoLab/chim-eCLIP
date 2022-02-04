#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: ResourceRequirement
    coresMin: 8
    coresMax: 16
  - class: InlineJavascriptRequirement

inputs:
  fasta:
    type: File
    inputBinding:
      position: 1
      prefix: --fasta
    doc: |
      fasta file generated from collapsing fastq reads
  mir:
    type: File
    inputBinding:
      position: 2
      prefix: --mir
    doc: "miRbase fasta file containing miRs to map"
  
  output_tsv:
    type: string
    default: ""
    inputBinding:
      position: 3
      prefix: --output_tsv
      valueFrom: |
        ${
          if (inputs.output_tsv == "") {
            return inputs.fasta.nameroot + ".tsv";
          }
          else {
            return inputs.output_tsv;
          }
        }
  output_index_log:
    type: string
    default: ""
    inputBinding:
      position: 4
      prefix: --output_index_log
      valueFrom: |
        ${
          if (inputs.output_index_log == "") {
            return inputs.fasta.nameroot + ".bowtie_index.log";
          }
          else {
            return inputs.output_index_log;
          }
        }
  output_map_log:
    type: string
    default: ""
    inputBinding:
      position: 5
      prefix: --output_map_log
      valueFrom: |
        ${
          if (inputs.output_map_log == "") {
            return inputs.fasta.nameroot + ".bowtie_map.log";
          }
          else {
            return inputs.output_map_log;
          }
        }
        
outputs:
  tsv:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output_tsv == "") {
            return inputs.fasta.nameroot + ".tsv";
          }
          else {
            return inputs.output_tsv;
          }
        }
  bowtie_index_log:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output_index_log == "") {
            return inputs.fasta.nameroot + ".bowtie_index.log";
          }
          else {
            return inputs.output_index_log;
          }
        }
  bowtie_map_log:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output_map_log == "") {
            return inputs.fasta.nameroot + ".bowtie_map.log";
          }
          else {
            return inputs.output_map_log;
          }
        }
baseCommand:
- bowtie_wrapper.py


