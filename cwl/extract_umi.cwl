#!/usr/bin/env cwltool

cwlVersion: v1.0
class: CommandLineTool

requirements:
  - class: InlineJavascriptRequirement
  - class: ResourceRequirement
    coresMin: 1
    # ramMin: 30000
    tmpdirMin: 8000
    outdirMin: 8000

baseCommand: [umi_tools, extract]
arguments: ["--random-seed", "1"]
inputs:

  bc_pattern:
    type: string
    default: "NNNNNNNNNN"
    inputBinding:
      position: 2
      prefix: --bc-pattern
    doc: "10 nt randomer"

  log:
    type: string
    default: ""
    inputBinding:
      position: 3
      prefix: --log
      valueFrom: |
        ${
          if (inputs.log == "") {
            return inputs.dataset + "." + inputs.reads.name + ".---.--.metrics";
          }
          else {
            return inputs.log;
          }
        }
        
  stdout:
    type: string
    default: ""
    inputBinding:
      position: 4
      prefix: --stdout
      valueFrom: |
        ${
          if (inputs.stdout == "") {
            return inputs.dataset + "." + inputs.reads.name + ".umi.r1.fq";
          }
          else {
            return inputs.stdout;
          }
        }

  reads:
    type:
      type: record
      fields:
        read1:
          type: File
          inputBinding:
            position: 1
            prefix: --stdin
        name:
          type: string
        adapters: 
          type: File

outputs:

  output_read1:
    type: File
    outputBinding:
      glob: $(inputs.dataset).$(inputs.reads.name).umi.r1.fq

  output_metrics:
    type: File
    outputBinding:
      glob: $(inputs.dataset).$(inputs.reads.name).---.--.metrics
    label: ""
    doc: "demuxed se metrics"

  output_dataset:
    type: string
    outputBinding:
      loadContents: true
      outputEval: $(inputs.dataset)
    doc: "just passes output dataset string to output to match with PE demux"

  name:
    type: string
    outputBinding:
      loadContents: true
      outputEval: $(inputs.reads.name)
    doc: "just passes output name string to output to match with PE demux"

doc: |
  Extract UMI barcode from a read and add it to the read name, leaving
  any sample barcode in place. Can deal with paired end reads and UMIs
  split across the paired ends. For eCLIP single-end processing, this step just
  trims the first 10 bases, but named as such to match the demux_pe step.

    Usage: umi_tools extract --bc-pattern=[PATTERN] -L extract.log [OPTIONS]
