#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement

baseCommand: [find_candidate_chimeric_seqs_from_mir_alignments.py]

inputs:

  bowtie_align:
    type: File
    inputBinding:
      position: 1
      prefix: --bowtie_align

  fa_file:
    type: File
    inputBinding:
      position: 2
      prefix: --fa_file

  output:
    type: string
    inputBinding:
      position: 3
      prefix: --out_file
      valueFrom: |
        ${
          if (inputs.output == "") {
            return inputs.bowtie_align.nameroot + ".chimeric_candidates.fa";
          }
          else {
            return inputs.output;
          }
        }
    default: ""

  metrics:
    type: string
    inputBinding:
      position: 3
      prefix: --metrics_file
      valueFrom: |
        ${
          if (inputs.metrics == "") {
            return inputs.bowtie_align.nameroot + ".metrics";
          }
          else {
            return inputs.metrics;
          }
        }
    default: ""

outputs:

  chimeric_candidates_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.output == "") {
            return inputs.bowtie_align.nameroot + ".chimeric_candidates.fa";
          }
          else {
            return inputs.output;
          }
        }
    label: ""
    doc: "fasta"

  metrics_file:
    type: File
    outputBinding:
      glob: |
        ${
          if (inputs.metrics == "") {
            return inputs.bowtie_align.nameroot + ".metrics";
          }
          else {
            return inputs.metrics;
          }
        }
    label: ""
    doc: "tabbed file"

