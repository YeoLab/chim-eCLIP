#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool

requirements:
- class: InlineJavascriptRequirement

baseCommand: [fastq2collapse.pl]

inputs:

  input_file:
    type: File
    inputBinding:
      position: 1

  output:
    type: string
    inputBinding:
      position: 2
      valueFrom: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".collapsed.fa";
          }
          else {
            return inputs.output;
          }
        }
    default: ""

outputs:

  collapsed_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output == "") {
            return inputs.input_file.nameroot + ".collapsed.fa";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "fasta"
