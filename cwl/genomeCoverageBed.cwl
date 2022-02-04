#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [genomeCoverageBed]

inputs:

  input_bam:
    type: File
    inputBinding:
      position: 1
      prefix: -ibam

  chrom_sizes:
    type: File
    inputBinding:
      position: 2
      prefix: -g
  output_bedgraph:
    type: boolean
    inputBinding:
      position: 3
      prefix: -bg
    default: true
    
stdout: ${
    return inputs.input_bam.nameroot + ".bg";
  }
outputs:

  bedgraph_file:
    type: File
    outputBinding:
      glob: |
        ${
          return inputs.input_bam.nameroot + ".bg";
        }
    label: ""
    doc: "bedgraph file"
