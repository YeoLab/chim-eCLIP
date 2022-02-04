#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [fastx_trimmer]

inputs:

  first_base_to_keep:
    type: int
    inputBinding:
      position: 1
      prefix: -f
    default: 21

  input_file:
    type: File
    inputBinding:
      position: 2
      prefix: -i

  output:
    type: string
    inputBinding:
      position: 3
      prefix: -o
      valueFrom: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".5trim.fa";
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
            return inputs.input_file.nameroot + ".5trim.fa";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "fasta"
