#!/usr/bin/env cwltool

### doc: "Sorts fastq file by read name." ###

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: 1
    coresMax: 16
    ramMin: 16000
    tmpdirMin: 10000
    outdirMin: 10000

baseCommand: [fastq-sort]

inputs:

  input_fastqsort_fastq:
    type: File
    # format: http://edamontology.org/format_1930
    inputBinding:
      position: 1
      prefix: --id
    label: ""
    doc: "input fastq"

  output_fastqsort_fastq:
    type: string
    default: ""

stdout: ${
    if (inputs.output_fastqsort_fastq == "") {
      return inputs.input_fastqsort_fastq.basename + ".sorted.fq";
    }
  else {
      return inputs.output_fastqsort_fastq;
    }
  }

outputs:

  output_fastqsort_sortedfastq:
    type: File
    # format: http://edamontology.org/format_1930
    outputBinding:
      glob: |
        ${
          if (inputs.output_fastqsort_fastq == "") {
            return inputs.input_fastqsort_fastq.basename + ".sorted.fq";
          }
          else {
            return inputs.output_fastqsort_fastq;
          }
        }
    label: ""
    doc: "sorted fastq"

doc: |
  Sorts FASTQ files by their read name. Sorted fastq files are required to keep mapping steps
  deterministic.

    Usage: fastq-sort --id FASTQ_FILE > STDOUT
