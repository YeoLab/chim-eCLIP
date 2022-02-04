#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [collapse_bowtie_results.py]

inputs:

  bowtie_align:
    type: File
    inputBinding:
      position: 1
      prefix: --bowtie_align

  output:
    type: string
    inputBinding:
      position: 3
      prefix: --out_file
      valueFrom: |
        ${
          if (inputs.output == "") {
            return inputs.bowtie_align.nameroot + ".filtered.tsv";
          }
          else {
            return inputs.output;
          }
        }
    default: ""

outputs:

  filtered_bowtie_tsv:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output == "") {
            return inputs.bowtie_align.nameroot + ".filtered.tsv";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "filtered bowtie output tsv file. "

doc: |
  Takes the standard bowtie output (tabbed separated file) and
  1) removes any negative stranded alignments, which is done to 
  reduce the chance of one read aligning to both major product and 
  the minor antisense miR
  2) removes any alignment whose number of mismatches exceeds the 
  minimum for that read. 