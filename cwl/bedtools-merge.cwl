#!/usr/bin/env cwltool

cwlVersion: v1.0

class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: 8
    ramMin: 32000

hints:
  - class: DockerRequirement
    dockerPull: brianyee/eclip:0.7.0
    
baseCommand: [bedtools, merge]

inputs:
  
  bed:
    type: File
    inputBinding:
      position: 1
      prefix: -i
  
  stranded:
    type: boolean
    default: true
    inputBinding:
      position: 2
      prefix: -s
  
  columns:
    type: string
    default: "4,5,6"
    inputBinding:
      position: 3
      prefix: -c
      
  overlap:
    type: int
    default: 1
    inputBinding:
      position: 4
      prefix: -d
      
  operations:
    type: string
    default: "collapse,mean,distinct"
    inputBinding:
      position: 4
      prefix: -o

stdout: $(inputs.bed.nameroot).merged.bed

outputs:

  merged_bed:
    type: File
    outputBinding:
      glob: $(inputs.bed.nameroot).merged.bed

doc: |
  bedtools merge (bookended features NOT merged). 