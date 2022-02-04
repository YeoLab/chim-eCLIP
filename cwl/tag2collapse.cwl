#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [tag2collapse.pl]

inputs:

  keep_tag_name:
    type:
      boolean
    inputBinding:
      position: 0
      prefix: --keep-tag-name
    default: true

  keep_max_score:
    type:
      boolean
    inputBinding:
      position: 1
      prefix: --keep-max-score
    default: true

  random_linker:
    type:
      boolean
    inputBinding:
      position: 2
      prefix: --random-linker
    default: true

  em:
    type:
      int
    inputBinding:
      position: 3
      prefix: -EM
    default: 30

  seq_error_model:
    type:
      string
    inputBinding:
      position: 4
      prefix: --seq-error-model
    default: em-local

  weight:
    type: boolean
    inputBinding:
      position: 5
      prefix: --weight
    default: true
  
  weight_in_name:
    type: boolean
    inputBinding:
      position: 6
      prefix: --weight-in-name
    default: true
  
  input_file:
    type: File
    inputBinding:
      position: 7
      
  output:
    type: string
    inputBinding:
      position: 8
      valueFrom: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".rmDup.tsv";
          }
          else {
            return inputs.output;
          }
        }
    default: ""

outputs:

  rmDup_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".rmDup.tsv";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "fasta"
