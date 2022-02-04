#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement


inputs:

  fastq_file:
    type:
      File
    inputBinding:
      position: 0
      prefix: -A
      
  fasta:
    type: string
    default: ""
    inputBinding:
      position: 1
    
stdout: ${
    if (inputs.fasta == "") {
      return inputs.fastq_file.nameroot + ".fa";
    }
  else {
      return inputs.fasta;
    }
  }

outputs:

  output_fasta_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.fasta == "") {
            return inputs.fastq_file.nameroot + ".fa";
          }
          else {
            return inputs.fasta;
          }
        }
    label: ""
    doc: "fasta"

baseCommand:
  - seqtk
  - seq