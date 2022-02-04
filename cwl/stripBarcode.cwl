#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [stripBarcode.pl]

inputs:

  linker:
    type:
      int
    inputBinding:
      position: 0
      prefix: -len
    default: 5

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
            return inputs.input_file.nameroot + ".strip.fa";
          }
          else {
            return inputs.output;
          }
        }
    default: ""

outputs:

  stripped_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".strip.fa";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "fasta"
