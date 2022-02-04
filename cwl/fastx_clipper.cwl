#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [fastx_clipper]

inputs:

  discard_len:
    type: int
    inputBinding:
      position: 1
      prefix: -l
    default: 20

  adapter:
    type: string
    inputBinding:
      position: 2
      prefix: -a
    default: GTGTCAGTCACTTCCAGCGG

  keep:
    type: boolean
    inputBinding:
      position: 3
      prefix: -n
    default: true

  input_file:
    type: File
    inputBinding:
      position: 5
      prefix: -i

  output:
    type: string
    inputBinding:
      position: 6
      prefix: -o
      valueFrom: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".3trim.fa";
          }
          else {
            return inputs.output;
          }
        }
    default: ""

outputs:

  trimmed_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".3trim.fa";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "fasta"
