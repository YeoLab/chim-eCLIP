#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool

# , $overlap_length_option
# , $g_adapters_option
# , $A_adapters_option
# , $a_adapters_option
# , -o, out_fastq.fastq.gz
# , -p, out_pair.fastq.gz
# , in_fastq.fastq.gz
# , in_pair.fastq.gz
# > report

#$namespaces:
#  ex: http://example.com/

requirements:
  - class: ResourceRequirement
    coresMin: 2
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement


baseCommand: [cutadapt]

inputs:

  input_trim_overlap_length:
    type: string
    default: "5"
    inputBinding:
      position: 0
      prefix: -O

  f:
    type: string
    default: "fastq"
    inputBinding:
      position: 1
      prefix: -f

  match_read_wildcards:
    type: boolean
    default: true
    inputBinding:
      position: 2
      prefix: --match-read-wildcards

  times:
    type: string
    default: "3"
    inputBinding:
      position: 3
      prefix: --times

  error_rate:
    type: string
    default: "0.1"
    inputBinding:
      position: 4
      prefix: -e

  quality_cutoff:
    type: string
    default: "6"
    inputBinding:
      position: 5
      prefix: --quality-cutoff

  minimum_length:
    type: string
    default: "18"
    inputBinding:
      position: 6
      prefix: -m

  output_r1:
    type: string
    inputBinding:
      position: 7
      prefix: -o
      valueFrom: |
        ${
          if (inputs.output_r1 == "") {
            return inputs.input_trim[0].nameroot + "Tr.fq";
          }
          else {
            return inputs.output_r1;
          }
        }
    default: ""

  input_trim_b_adapters:
    default: []
    type:
      type: array
      items: string
      inputBinding:
        prefix: "-b "
        separate: false
    inputBinding:
      position: 9

  input_trim_g_adapters:
    default: []
    type:
      type: array
      items: string
      inputBinding:
        prefix: "-g "
        separate: false
    inputBinding:
      position: 10

  input_trim_A_adapters:
    default: []
    type:
      type: array
      items: string
      inputBinding:
        prefix: "-A "
        separate: false
    inputBinding:
      position: 11


  input_trim_a_adapters:
    type:
      type: array
      items: string
      inputBinding:
        prefix: "-a "
        separate: false
    inputBinding:
      position: 12

  cores:
    type: int
    default: 8
    inputBinding:
      position: 13
      prefix: -j

  input_trim:
    type: File[]?
    inputBinding:
      position: 14


stdout: $(inputs.input_trim[0].nameroot)Tr.metrics

outputs:

  output_trim:
    type: File[]?
    outputBinding:
      glob: |
        ${
          if (inputs.output_r1 == "") {
            return [
              inputs.input_trim[0].nameroot + "Tr.fq"
            ];
          }
          else {
            return [
              inputs.output_r1
            ];
          }
        }

  output_trim_report:
    type: File
    outputBinding:
      glob: "*.metrics"

doc: |
  This tool wraps cutadapt with default parameters set to single-end eCLIP processing defaults.
    Usage: cutadapt -a ADAPT1 -A ADAPT2 [options] -o out1.fastq -p out2.fastq in1.fastq in2.fastq
