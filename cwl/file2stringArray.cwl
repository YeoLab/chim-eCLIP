#!/usr/bin/env cwltool

### doc: "Returns string array expression based on lines in a file" ###

cwlVersion: v1.0
class: ExpressionTool

requirements:
  - class: InlineJavascriptRequirement

inputs:
  file:
    type: File
    inputBinding:
      loadContents: true

outputs:
  output:
    type: string[]

expression: "${var lines=inputs.file.contents.split('\\n');
  var seqs = [];
  for(var line = 0; line < lines.length; line++) {
    if(lines[line][0] != '>') {
      if (!lines[line] || 0 === lines[line].length) {

      }
      else {
        seqs.push(lines[line]);
      }
    }
  }
  return {'output':seqs};
}"

doc: |
  Returns string array expression based on lines in a fasta file (SKIPS >).