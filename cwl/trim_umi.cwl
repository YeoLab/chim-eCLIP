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

  hard_trim_length:
    type: int
    inputBinding:
      position: 0
      prefix: -u

  output_r1:
    type: string
    inputBinding:
      position: 2
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
  This tool wraps cutadapt to trim off the 3' end of R1 (may be UMIs) for eCLASH reads
