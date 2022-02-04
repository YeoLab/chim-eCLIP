#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [fastq_filter.pl]

inputs:

  fastq_format:
    type:
      string
    inputBinding:
      position: 0
      prefix: -if
    default: sanger

  score_filter:
    type:
      string
    inputBinding:
      position: 1
      prefix: -f
    default: min:0-3:20,mean:20-40:20

  max_n:
    type:
      int
    inputBinding:
      position: 2
      prefix: -maxN
    default: -1

  verbose:
    type:
      boolean
    inputBinding:
      position: 3
      prefix: -v
    default: true

  output_format:
    type:
      string
    inputBinding:
      position: 4
      prefix: -of
    default: fasta

  input_file:
    type: File
    inputBinding:
      position: 5

  output:
    type: string
    inputBinding:
      position: 6
      valueFrom: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".filtered.fa";
          }
          else {
            return inputs.output;
          }
        }
    default: ""

outputs:

  filtered_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".filtered.fa";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "fasta"
