#!/usr/bin/env cwltool

### space to remind me of what the metadata runner is ###

cwlVersion: v1.0
class: Workflow

requirements:
  - class: InlineJavascriptRequirement
  - class: StepInputExpressionRequirement
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement      # TODO needed?
  - class: MultipleInputFeatureRequirement


inputs:
  chrom_sizes:
    type: File
  speciesGenomeDir:
    type: Directory
  repeatElementGenomeDir:
    type: Directory
  reads:
    type: File[]?

outputs:
    
  output_maprepeats_mapped_to_genome:
    type: File
    outputSource: step_rename_mapped_repeats/outfile
  output_maprepeats_stats:
    type: File
    outputSource: step_map_repeats/mappingstats
  output_maprepeats_star_settings:
    type: File
    outputSource: step_map_repeats/starsettings
  output_sort_repunmapped_fastq:
    type: File
    outputSource: step_gzip_sort_repunmapped_fastq/gzipped

  output_mapgenome_mapped_to_genome:
    type: File
    outputSource: step_rename_mapped_genome/outfile
  output_mapgenome_stats:
    type: File
    outputSource: step_map_genome/mappingstats
  output_mapgenome_star_settings:
    type: File
    outputSource: step_map_genome/starsettings
  output_sorted_bam:
    type: File
    outputSource: step_sort/output_sort_bam

  output_rmdup_bam:
    type: File
    outputSource: step_barcodecollapsese/output_barcodecollapsese_bam
  # output_rmdup_metrics:
  #   type: File
  #   outputSource: step_barcodecollapsese/output_barcodecollapsese_metrics

  output_rmdup_sorted_bam:
    type: File
    outputSource: step_index_rmdup_bam/alignments_with_index
  
  output_pos_bw:
    type: File
    outputSource: step_make_bigwigs/posbw
  output_neg_bw:
    type: File
    outputSource: step_make_bigwigs/negbw
    
steps:
      
###########################################################################
# Mapping
###########################################################################

  step_map_repeats:
    run: star-repeatmapping.cwl
    in:
      readFilesIn: reads
      genomeDir: repeatElementGenomeDir
    out: [
      aligned,
      output_map_unmapped_fwd,
      starsettings,
      mappingstats
    ]
  step_rename_mapped_repeats:
    run: rename.cwl
    in:
      srcfile: step_map_repeats/aligned
      suffix:
        default: ".bam"
      newname:
        source: reads
        valueFrom: ${ return self[0].nameroot + ".repeat-mapped"; }
    out: [
      outfile
    ]
  rename_unmapped_repeats:
    run: rename.cwl
    in:
      srcfile: step_map_repeats/output_map_unmapped_fwd
      suffix:
        default: ".fq"
      newname:
        source: reads
        valueFrom: ${ return self[0].nameroot + ".repeat-unmapped"; }
    out: [
      outfile
    ]
  step_sort_repunmapped_fastq:
    run: fastqsort.cwl
    in:
      input_fastqsort_fastq: rename_unmapped_repeats/outfile
    out:
      [output_fastqsort_sortedfastq]
  
  step_gzip_sort_repunmapped_fastq:
    run: gzip.cwl
    in:
      input: step_sort_repunmapped_fastq/output_fastqsort_sortedfastq
    out:
      - gzipped
      
  step_map_genome:
    run: star-genome.cwl
    in:
      readFilesIn: 
        source: step_sort_repunmapped_fastq/output_fastqsort_sortedfastq
        valueFrom: ${ return [ self ]; }
      genomeDir: speciesGenomeDir
    out: [
      aligned,
      output_map_unmapped_fwd,
      starsettings,
      mappingstats
    ]
  step_rename_mapped_genome:
    run: rename.cwl
    in:
      srcfile: step_map_genome/aligned
      suffix: 
        default: ".bam"
      newname:
        source: reads
        valueFrom: ${ return self[0].nameroot + ".genome-mapped"; }
    out: [
      outfile
    ]

  step_sortlexico:
    run: namesort.cwl
    in:
      name_sort: 
        default: true
      input_sort_bam: step_rename_mapped_genome/outfile
    out: [output_sort_bam]
    
  step_sort:
    run: sort.cwl
    in:
      input_sort_bam: step_sortlexico/output_sort_bam
    out: [output_sort_bam]
      
  step_index:
    run: samtools-index.cwl
    in:
      alignments: step_sort/output_sort_bam
    out: [alignments_with_index]

  step_barcodecollapsese:
    run: barcodecollapse_se_nostats.cwl
    in:
      input_barcodecollapsese_bam: step_index/alignments_with_index
    out: [output_barcodecollapsese_bam] # , output_barcodecollapsese_metrics]

  step_sort_rmdup:
    run: sort.cwl
    in:
      input_sort_bam: step_barcodecollapsese/output_barcodecollapsese_bam
    out: [output_sort_bam]

  step_index_rmdup_bam:
    run: samtools-index.cwl
    in:
      alignments: step_sort_rmdup/output_sort_bam
    out: [alignments_with_index]

  step_make_bigwigs:
    run: makebigwigfiles.cwl
    in:
      chromsizes: chrom_sizes
      bam: step_index_rmdup_bam/alignments_with_index
    out:
      [posbw, negbw]

  
    
###########################################################################
# Downstream
###########################################################################

doc: |
  This workflow takes in appropriate trimming params and demultiplexed reads,
  and performs the following steps in order: filter repeat elements, fastq-sort, genomic mapping, sort alignment, index alignment, namesort, PCR dedup, sort alignment, index alignment, make bigwigs, 
  call peak clusters
