#!/usr/bin/env cwl-runner

### doc: "Extracts the first 9nt of R2 and appends to name of R1, consistent with Chimeric eCLIP read structure" ###

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement



baseCommand: [filter_primers.py]

inputs:

  read1:
    type: File
    inputBinding:
      position: 1
      prefix: --read1
  
  primer:
    type: string
    inputBinding:
      position: 2
      prefix: --primer
      
  output_file:
    type: string
    default: ""
    inputBinding:
      position: 3
      prefix: --output_file
      valueFrom: |
        ${
          if (inputs.output_file == "") {
            return inputs.read1.nameroot + ".primer.fq";
          }
          else {
            return inputs.output_file;
          }
        }

outputs:

  output_filtered:
    type: File
    outputBinding: 
      glob: |
        ${
          if (inputs.output_file == "") {
            return inputs.read1.nameroot + ".primer.fq";
          }
          else {
            return inputs.output_file;
          }
        }
    label: ""
