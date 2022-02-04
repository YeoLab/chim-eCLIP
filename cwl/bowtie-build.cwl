#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement
- class: ResourceRequirement
  coresMin: 8
  coresMax: 16
  tmpdirMin: 50000
  outdirMin: 50000
  
inputs:

  fasta_file:
    type:
      - File
      - type: array
        items: File
    inputBinding:
      itemSeparator: ","
      position: 25
    doc: |
      comma-separated list of files with ref sequences

  index_base_name:
    type: string
    inputBinding:
      position: 26
    doc: |
      write Ebwt data to files with this basename
  offrate:
    type: int
    inputBinding:
      position: 1
      prefix: --offrate
    default: 2
  threads:
    type: int
    inputBinding:
      position: 3
      prefix: --threads
    default: 8
    
outputs:

  indices:
    type: File[]
    outputBinding:
      glob: ${return inputs.index_base_name + "*"}

baseCommand:
  - bowtie-build