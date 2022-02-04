#!/usr/bin/env cwltool

cwlVersion: v1.0

class: CommandLineTool

baseCommand: [split_bowtie_outputs.py]

requirements:
  - class: InlineJavascriptRequirement

inputs:

  bowtie_output:
    type: File
    inputBinding:
      position: 1
      prefix: --in_file

outputs:

  bowtie_splits:
    type:
      type: array
      items: File
    outputBinding:
      glob: "*.tmp"
