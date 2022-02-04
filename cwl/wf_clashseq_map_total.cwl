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
  
  reads:
    type: File[]?
  read_idx_name:
    type: string
  mirna_fasta:
    type: File
  speciesGenomeDir:
    type: Directory
  chrom_sizes:
    type: File
  repeatElementGenomeDir:
    type: Directory
    
outputs:
  
  output_fasta:
    type: File
    outputSource: step_fastq_to_fasta/output_fasta_file
  output_collapsed_fasta:
    type: File
    outputSource: step_fasta2collapse/collapsed_file
  
  output_bowtie_results:
    type: File
    outputSource: step_bowtie_wrapper/tsv
  output_bowtie_log:
    type: File
    outputSource: step_bowtie_wrapper/bowtie_map_log
  output_filtered_bowtie_results:
    type: File
    outputSource: step_filter_bowtie_output/filtered_bowtie_tsv
    
  output_chimeric_candidates:
    type: File
    outputSource: step_find_chimeric_candidates/chimeric_candidates_file
  output_chimeric_metrics:
    type: File
    outputSource: step_find_chimeric_candidates/metrics_file
  
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
    outputSource: step_gzip_repunmapped_fastq/gzipped
    
  output_mapgenome_mapped_to_genome:
    type: File
    outputSource: step_rename_mapped_genome/outfile
  output_mapgenome_stats:
    type: File
    outputSource: step_map_genome/mappingstats
  output_mapgenome_star_settings:
    type: File
    outputSource: step_map_genome/starsettings
  output_mapgenome_unmapped_chimeras:
    type: File
    outputSource: step_map_genome/output_map_unmapped_fwd
    
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
    
  output_eclip_repeats:
    type: File
    outputSource: step_map_eclip_repeats/aligned
  output_eclip_repeats_stats:
    type: File
    outputSource: step_map_eclip_repeats/mappingstats
  output_eclip_repeats_unmapped_fastq:
    type: File
    outputSource: step_gzip_eclip_repunmapped_fastq/gzipped
  
  output_eclip_genome:
    type: File
    outputSource: step_rename_eclip_mapped_genome/outfile
  output_eclip_sorted_genome:
    type: File
    outputSource: step_eclip_sort/output_sort_bam
  output_eclip_genome_stats:
    type: File
    outputSource: step_map_eclip_genome/mappingstats

  output_eclip_rmdup_bam:
    type: File
    outputSource: step_eclip_barcodecollapsese/output_barcodecollapsese_bam

  output_eclip_rmdup_sorted_bam:
    type: File
    outputSource: step_index_eclip_rmdup_bam/alignments_with_index
  
  output_eclip_pos_bw:
    type: File
    outputSource: step_make_eclip_bigwigs/posbw
  output_eclip_neg_bw:
    type: File
    outputSource: step_make_eclip_bigwigs/negbw
  
steps:

###########################################################################
# Collapse reads
###########################################################################

  step_fastq_to_fasta:
    run: fastq2fasta.cwl
    in:
      fastq_file:
        source: reads
        valueFrom: |
          ${
            return self[0];
          }
    out: [output_fasta_file]

  step_fasta2collapse:
    run: fasta2collapse.cwl
    in:
      input_file: step_fastq_to_fasta/output_fasta_file
    out: [collapsed_file]

###########################################################################
# Reverse-map miRs
###########################################################################
  step_bowtie_wrapper:
    run: bowtie-wrapper.cwl
    in:
      fasta: step_fasta2collapse/collapsed_file
      mir: mirna_fasta
    out: [
      tsv,
      bowtie_index_log,
      bowtie_map_log
    ]
  
  step_filter_bowtie_output:
    run: filter_bowtie_results.cwl
    in:
      bowtie_align: step_bowtie_wrapper/tsv
    out: [filtered_bowtie_tsv]
  
  step_find_chimeric_candidates:
    run: wf_find_chimeric_candidates.cwl
    in:
      filtered_bowtie_tsv: step_filter_bowtie_output/filtered_bowtie_tsv
      output_fasta_file: step_fastq_to_fasta/output_fasta_file
      chimeric_candidates_filename: 
        source: step_filter_bowtie_output/filtered_bowtie_tsv
        valueFrom: ${return self.nameroot + ".chimeric_candidates.fa"}
      chimeric_metrics_filename: 
        source: step_filter_bowtie_output/filtered_bowtie_tsv
        valueFrom: ${return self.nameroot + ".metrics"}
    out: [
      chimeric_candidates_file,
      metrics_file
    ]
      
###########################################################################
# Map chimeric reads to genome
###########################################################################

  step_map_repeats:
    run: star-repeatmapping.cwl
    in:
      readFilesIn: 
        source: step_find_chimeric_candidates/chimeric_candidates_file
        valueFrom: ${ return [ self ]; }
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
        default: ".fa"
      newname:
        source: reads
        valueFrom: ${ return self[0].nameroot + ".repeat-unmapped"; }
    out: [
      outfile
    ]
  
  step_gzip_repunmapped_fastq:
    run: gzip.cwl
    in:
      input: rename_unmapped_repeats/outfile
    out:
      - gzipped
      
  step_map_genome:
    run: star-genome.cwl
    in:
      readFilesIn: 
        source: rename_unmapped_repeats/outfile
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
    out: [
      posbw, 
      negbw
    ]

###########################################################################
# Map NON CHIMERIC reads to genome
###########################################################################

  step_map_eclip_repeats:
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
    
  step_rename_eclip_mapped_repeats:
    run: rename.cwl
    in:
      srcfile: step_map_eclip_repeats/aligned
      suffix:
        default: ".bam"
      newname:
        source: reads
        valueFrom: ${ return self[0].nameroot + ".eclip.repeat-mapped"; }
    out: [
      outfile
    ]
    
  rename_eclip_unmapped_repeats:
    run: rename.cwl
    in:
      srcfile: step_map_eclip_repeats/output_map_unmapped_fwd
      suffix:
        default: ".fq"
      newname:
        source: reads
        valueFrom: ${ return self[0].nameroot + ".eclip.repeat-unmapped"; }
    out: [
      outfile
    ]
  
  step_gzip_eclip_repunmapped_fastq:
    run: gzip.cwl
    in:
      input: rename_eclip_unmapped_repeats/outfile
    out:
      - gzipped
      
  step_map_eclip_genome:
    run: star-genome.cwl
    in:
      readFilesIn: 
        source: rename_eclip_unmapped_repeats/outfile
        valueFrom: ${ return [ self ]; }
      genomeDir: speciesGenomeDir
    out: [
      aligned,
      output_map_unmapped_fwd,
      starsettings,
      mappingstats
    ]
    
  step_rename_eclip_mapped_genome:
    run: rename.cwl
    in:
      srcfile: step_map_eclip_genome/aligned
      suffix: 
        default: ".bam"
      newname:
        source: reads
        valueFrom: ${ return self[0].nameroot + ".eclip.genome-mapped"; }
    out: [
      outfile
    ]

  step_eclip_sortlexico:
    run: namesort.cwl
    in:
      name_sort: 
        default: true
      input_sort_bam: step_rename_eclip_mapped_genome/outfile
    out: [output_sort_bam]
    
  step_eclip_sort:
    run: sort.cwl
    in:
      input_sort_bam: step_eclip_sortlexico/output_sort_bam
    out: [output_sort_bam]
      
  step_eclip_index:
    run: samtools-index.cwl
    in:
      alignments: step_eclip_sort/output_sort_bam
    out: [alignments_with_index]
    
  step_eclip_barcodecollapsese:
    run: barcodecollapse_se_nostats.cwl
    in:
      input_barcodecollapsese_bam: step_eclip_index/alignments_with_index
    out: [output_barcodecollapsese_bam] # , output_barcodecollapsese_metrics]

  step_sort_eclip_rmdup:
    run: sort.cwl
    in:
      input_sort_bam: step_eclip_barcodecollapsese/output_barcodecollapsese_bam
    out: [output_sort_bam]
    
  step_index_eclip_rmdup_bam:
    run: samtools-index.cwl
    in:
      alignments: step_sort_eclip_rmdup/output_sort_bam
    out: [alignments_with_index]

  step_make_eclip_bigwigs:
    run: makebigwigfiles.cwl
    in:
      chromsizes: chrom_sizes
      bam: step_index_eclip_rmdup_bam/alignments_with_index
    out: [
      posbw, 
      negbw
    ]
    
###########################################################################
# Downstream
###########################################################################

doc: |
  This workflow takes in appropriate trimming params and demultiplexed reads,
  and performs the following steps in order: filter repeat elements, fastq-sort, genomic mapping, sort alignment, index alignment, namesort, PCR dedup, sort alignment, index alignment, make bigwigs, 
  call peak clusters
