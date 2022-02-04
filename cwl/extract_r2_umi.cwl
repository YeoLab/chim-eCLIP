#!/usr/bin/env cwl-runner

### doc: "Extracts the first 9nt of R2 and appends to name of R1, consistent with Chimeric eCLIP read structure" ###

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement



baseCommand: [targeted_miR_umi.py]

inputs:

  read:
    type:
      type: record
      fields:
        read1:
          type: File
          inputBinding:
            position: 1
            prefix: --read1
        read2:
          type: File
          inputBinding:
            position: 2
            prefix: --read2
        name: 
          type: string
        primer:
          type: string
        adapters: 
          type: File
            
  output_file:
    type: string
    default: ""
    inputBinding:
      position: 3
      prefix: --output_file
      valueFrom: |
        ${
          if (inputs.output_file == "") {
            return inputs.dataset + "." + inputs.read.name + ".umi.r1.fq";
          }
          else {
            return inputs.output_file;
          }
        }

  dataset:
    type: string

outputs:

  output_read1:
    type: File
    outputBinding: 
      glob: |
        ${
          if (inputs.output_file == "") {
            return inputs.dataset + "." + inputs.read.name + ".umi.r1.fq";
          }
          else {
            return inputs.output_file;
          }
        }
    label: ""
    doc: "read1 with R2 umi header"
    
  output_dataset:
    type: string
    outputBinding:
      loadContents: true
      outputEval: $(inputs.dataset)
    doc: "just passes output dataset string to output"

  name:
    type: string
    outputBinding:
      loadContents: true
      outputEval: $(inputs.read.name)
    doc: "just passes output name string to output"
  
  primer:
    type: string
    outputBinding:
      loadContents: true
      outputEval: $(inputs.read.primer)
    doc: "just passes output primer string to output"
