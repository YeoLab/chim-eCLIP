#!/usr/bin/env cwltool

cwlVersion: v1.0

class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: 1
    ramMin: 8000
    
hints:
  - class: DockerRequirement
    dockerPull: brianyee/bedtools:2.27.1
    
baseCommand: [bedtools, intersect]

arguments: [
  "-v",
  "-s",
  ]

inputs:

  input_bed:
    type: File
    inputBinding:
      position: 1
      prefix: -a
      
  exclude_regions_file:
    type: File
    inputBinding:
      position: 2
      prefix: -b

stdout: $(inputs.input_bed.nameroot).exclude-regions.bed

outputs:

  output_excluded_regions_bed:
    type: File
    outputBinding:
      glob: $(inputs.input_bed.nameroot).exclude-regions.bed

doc: |
  Given a list of 'blacklist' regions, remove those regions from an input BED file
  This tool wraps bedtools intersect -v to remove blacklist regions
