#!/usr/bin/env cwltool

cwlVersion: v1.0
class: ExpressionTool
requirements:
  - class: InlineJavascriptRequirement
inputs:
  idx_files: File[]

  outdir: string
  
outputs:
  out: Directory
expression: |
  ${
    return {"out": {
      "class": "Directory", 
      "basename": inputs.outdir,
      "listing": inputs.idx_files,
      "location": inputs.idx_files[0].location.split('/').slice(0, -1).join('/')
    } };
  }