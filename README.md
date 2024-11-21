# clash_seq_pipeline
Processing pipeline as first described in Moore et al. 2015, then later modified for eCLIP-like reads.

## Steps:
- Trim and extract UMIs
- 'reverse' map mature miRs against sample libraries with Bowtie (-n 1 -l 8 -e 35 -k -1)
- Reads mapping to more than one miR are 'family mapped' and are collapsed into single hit.
- Chimeric sequences (upstream and downstream) are extracted and filtered
- Chimeric sequences are filtered for a min length of 18 and mapped to genome
- Dedup UMIs

# Outputs:
- umi-extracted reads: `.umi.r1.fq.gz`
- adapter-trimmed fastq/fasta:
    - `.umi.r1.fqTrTr.sorted.fa.gz`
    - `.umi.r1.fqTrTr.sorted.fq.gz`
- unique reads only: `.umi.r1.fqTrTr.sorted.collapsed.fa.gz`
- miR-mapped output from bowtie: `.umi.r1.fqTrTr.sorted.collapsed.tsv`
- priority-driven filtered miR-mapped output: `.umi.r1.fqTrTr.sorted.collapsed.filtered.tsv`
- re-align all reads -> miR-mapped output: `.umi.r1.fqTrTr.sorted.collapsed.filtered.metrics`
- fasta-file of chimeric candidates based on valid miR-mapped reads: `.umi.r1.fqTrTr.sorted.collapsed.filtered.chimeric_candidates.fa.gz`
- chimeric and non-chimeric repeat-mapped reads ("eclip" reads not captured in this version):
    - `.umi.r1.fqTrTr.sorted.repeat-mapped.bam`
- chimeric and non-chimeric ("eclip") mapped reads:
    - `.umi.r1.fqTrTr.sorted.genome-mappedSoSo.bam`
    - `.umi.r1.fqTrTr.sorted.eclip.genome-mappedSoSo.bam`
- pcr-deduped mapped reads:
    - `.umi.r1.fqTrTr.sorted.genome-mappedSoSo.rmDupSo.bam`
    - `.umi.r1.fqTrTr.sorted.eclip.genome-mappedSoSo.rmDupSo.bam`
- normalized bigwig densities (positive and negative signal):
    - `.umi.r1.fqTrTr.sorted.genome-mappedSoSo.rmDupSo.norm.pos.bw`
    - `.umi.r1.fqTrTr.sorted.genome-mappedSoSo.rmDupSo.norm.neg.bw`
    - `.umi.r1.fqTrTr.sorted.eclip.genome-mappedSoSo.rmDupSo.norm.pos.bw`
    - `.umi.r1.fqTrTr.sorted.eclip.genome-mappedSoSo.rmDupSo.norm.neg.bw`
# Workflow in commandline form for TOTAL chimeric eCLIP:

### EXTRACT UMI AND TRIM 
```
umi_tools \
extract \
--random-seed \
1 \
--stdin \
/stage/293T-4kA-direct_S95_L000_R1_001.fastq.gz \
--bc-pattern \
NNNNNNNNNN \
--log \
yeo.4kA_direct.---.--.metrics \
--stdout \
yeo.4kA_direct.umi.r1.fq

gzip yeo.4kA_direct.umi.r1.fq

cutadapt \
-O 1 \
-f fastq \
--match-read-wildcards \
--times 3 \
-e 0.1 \
--quality-cutoff 6 \
-m 18 \
-o yeo.4kA_direct.umi.r1.fqTr.fq \
-a AGATCGGAAG \
-a GATCGGAAGA \
-a ATCGGAAGAG \
-a TCGGAAGAGC \
-a CGGAAGAGCA \
-a GGAAGAGCAC \
-a GAAGAGCACA \
-a AAGAGCACAC \
-a AGAGCACACG \
-a GAGCACACGT \
-a AGCACACGTC \
-a GCACACGTCT \
-a CACACGTCTG \
-a ACACGTCTGA \
-a CACGTCTGAA \
-a ACGTCTGAAC \
-a CGTCTGAACT \
-a GTCTGAACTC \
-a TCTGAACTCC \
-a CTGAACTCCA \
-a TGAACTCCAG \
-a GAACTCCAGT \
-a AACTCCAGTC \
-a ACTCCAGTCA \
-j 8 \
/stage/yeo.4kA_direct.umi.r1.fq.gz

cutadapt \
-u -10 \
-o yeo.4kA_direct.umi.r1.fqTrTr.fq \
-j 8 \
/stage/yeo.4kA_direct.umi.r1.fqTr.fq
```
### CONVERT TO FASTA AND COLLAPSE 
```

fastq-sort \
--id /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq > yeo.4kA_direct.umi.r1.fqTrTr.sorted.fq

seqtk seq \
-A /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.fq > yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.fa

fasta2collapse.pl \
/stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.fa \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.fa
```
### MAP MIR 
```
bowtie-build \
--offrate 2 \
--threads 8 \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.fa \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.bowtie_index

bowtie \
-a \
-e 35 \
-f \
-l 8 \
-n 1 \
-p 8 \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.bowtie_index \
mature.hsa.T.blacklist-removed.fa \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.tsv \
2> yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.tsv.log
```
##### Note: The CWL workflow now combines the previous two steps into a single "bowtie wrapper" step, to save I/O. All parameters remain the same as described above, except for slight name changes in log file name.
```
bowtie_wrapper.py \
--fasta /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.fa \
--mir /stage/mature.hsa.T.blacklist-removed.fa \
--output_tsv yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.tsv \
--output_index_log yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.bowtie_index.log \
--output_map_log yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.bowtie_map.log
```
### Filter Bowtie results and generate chimeric candidates (reads that map to miR and also contain long enough - 18nt downstream sequence) to map to the genome
```
collapse_bowtie_results.py \
--bowtie_align /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.tsv \
--out_file yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv

split_bowtie_outputs.py \
--in_file /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv

find_candidate_chimeric_seqs_from_mir_alignments.py \
--bowtie_align /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv.AA.tmp \
--fa_file /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.fa \
--metrics_file yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv.AA.metrics \
--out_file yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv.AA.chimeric_candidates.fa

...

cat /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv.AA.chimeric_candidates.fa .. NN.chimeric_candidates.fa > \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv.chimeric_candidates.fa

cat /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.tsv.AA.metrics ...
NN.metrics > \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.metrics
```
### MAP REPEAT (Chimeric Reads)
```
STAR \
--alignEndsType EndToEnd \
--genomeDir /stage/star_2_7_homo_sapiens_repbase_fixed_v2 \
--genomeLoad NoSharedMemory \
--outBAMcompression 10 \
--outFileNamePrefix yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.chimeric_candidates.STAR \
--outFilterMultimapNmax 30 \
--outFilterMultimapScoreRange 1 \
--outFilterScoreMin 10 \
--outFilterType BySJout \
--outReadsUnmapped Fastx \
--outSAMattrRGline ID:foo \
--outSAMattributes All \
--outSAMmode Full \
--outSAMtype BAM Unsorted \
--outSAMunmapped Within \
--outStd Log \
--readFilesIn /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.chimeric_candidates.fa \
--runMode alignReads \
--runThreadN 8

mv yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.chimeric_candidates.STARAligned.out.bam yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.repeat-mapped.bam
mv yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.collapsed.filtered.chimeric_candidates.STARUnmapped.out.mate1 yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.repeat-unmapped.fa
```
### MAP REPEAT (All Reads)
```
STAR \
--alignEndsType EndToEnd \
--genomeDir /stage/star_2_7_homo_sapiens_repbase_fixed_v2 \
--genomeLoad NoSharedMemory \
--outBAMcompression 10 \
--outFileNamePrefix yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.STAR \
--outFilterMultimapNmax 30 \
--outFilterMultimapScoreRange 1 \
--outFilterScoreMin 10 \
--outFilterType BySJout \
--outReadsUnmapped Fastx \
--outSAMattrRGline ID:foo \
--outSAMattributes All \
--outSAMmode Full \
--outSAMtype BAM Unsorted \
--outSAMunmapped Within \
--outStd Log \
--readFilesIn /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.fq \
--runMode alignReads \
--runThreadN 8

mv yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.STARAligned.out.bam \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.repeat-mapped.bam

mv yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.STARUnmapped.out.mate1 \
yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.repeat-unmapped.fa
```

### MAP GENOME (Chimeric Reads)
```
STAR \
--alignEndsType EndToEnd \
--genomeDir /stage/star_2_7_gencode29_sjdb \
--genomeLoad NoSharedMemory \
--outBAMcompression 10 \
--outFileNamePrefix yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.repeat-unmapped.STAR \
--outFilterMatchNminOverLread 0.66 \
--outFilterMultimapNmax 1 \
--outFilterMultimapScoreRange 1 \
--outFilterScoreMin 10 \
--outFilterScoreMinOverLread 0.66 \
--outFilterType BySJout \
--outReadsUnmapped Fastx \
--outSAMattrRGline ID:foo \
--outSAMattributes All \
--outSAMmode Full \
--outSAMtype BAM Unsorted \
--outSAMunmapped Within \
--outStd Log \
--readFilesIn /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.repeat-unmapped.fa \
--runMode alignReads \
--runThreadN 8

mv yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.repeat-unmapped.STARAligned.out.bam yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mapped.bam

samtools sort \
-n \
-o yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSo.bam \
/stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mapped.bam

samtools sort \
-o yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.bam \
-m 3G \
/stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSo.bam

samtools index \
-b yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.bam
```
### MAP GENOME (Non-chimeric eCLIP Reads)
```
STAR \
--alignEndsType EndToEnd \
--genomeDir /stage/star_2_7_gencode29_sjdb \
--genomeLoad NoSharedMemory \
--outBAMcompression 10 \
--outFileNamePrefix yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.repeat-unmapped.STAR \
--outFilterMatchNminOverLread 0.66 \
--outFilterMultimapNmax 1 \
--outFilterMultimapScoreRange 1 \
--outFilterScoreMin 10 \
--outFilterScoreMinOverLread 0.66 \
--outFilterType BySJout \
--outReadsUnmapped Fastx \
--outSAMattrRGline ID:foo \
--outSAMattributes All \
--outSAMmode Full \
--outSAMtype BAM Unsorted \
--outSAMunmapped Within \
--outStd Log \
--readFilesIn /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.repeat-unmapped.fq \
--runMode alignReads \
--runThreadN 8

mv yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.repeat-unmapped.STARAligned.out.bam yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mapped.bam

samtools \
sort \
-n \
-o yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSo.bam \
/stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mapped.bam

samtools \
sort \
-o yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.bam \
-m 3G \
/stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSo.bam

samtools index yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.bam
```
### DEDUP (Chimeric Reads)
- (optional): include ```--output-stats```
```
umi_tools dedup \
--random-seed 1 \
-I /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.bam \
--method unique \
-S yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.rmDup.bam

samtools sort \
-o yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.rmDupSo.bam \
-m 3G \
/stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.rmDup.bam

samtools index \
-b yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.rmDupSo.bam

makebigwigfiles \
--bw_pos yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.rmDupSo.norm.pos.bw \
--bw_neg yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.rmDupSo.norm.neg.bw \
--bam /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.genome-mappedSoSo.rmDupSo.bam \
--genome /stage/chrNameLength.txt
```
### DEDUP (Non-chimeric eCLIP Reads)
```
umi_tools \
dedup \
--random-seed 1 \
-I /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.bam \
--method unique \
-S yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.rmDup.bam

samtools sort \
-o yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.rmDupSo.bam \
-m 3G \
/stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.rmDup.bam

samtools index \
-b yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.rmDupSo.bam

makebigwigfiles \
--bw_pos yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.rmDupSo.norm.pos.bw \
--bw_neg yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.rmDupSo.norm.neg.bw \
--bam /stage/yeo.4kA_direct.umi.r1.fqTrTr.fq.sorted.eclip.genome-mappedSoSo.rmDupSo.bam \
--genome /stage/chrNameLength.txt
```


# Targeted (pcr-enriched) miR workflow commands

### EXTRACT UMI AND TRIM, EXTRACT PRIMER
```
targeted_miR_umi.py \
--read1 /stage/hsa-miR-301b-3p_merged.R1.fastq.gz \
--read2 /stage/hsa-miR-301b-3p_merged.R2.fastq.gz \
--output_file pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fq

gzip -c /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fq

cutadapt \
-O 1 \
-f fastq \
--match-read-wildcards \
--times 3 \
-e 0.1 \
--quality-cutoff 6 \
-m 18 \
-o pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTr.fq \
-a AGATCGGAAG \
-a GATCGGAAGA \
-a ATCGGAAGAG \
-a TCGGAAGAGC \
-a CGGAAGAGCA \
-a GGAAGAGCAC \
-a GAAGAGCACA \
-a AAGAGCACAC \
-a AGAGCACACG \
-a GAGCACACGT \
-a AGCACACGTC \
-a GCACACGTCT \
-a CACACGTCTG \
-a ACACGTCTGA \
-a CACGTCTGAA \
-a ACGTCTGAAC \
-a CGTCTGAACT \
-a GTCTGAACTC \
-a TCTGAACTCC \
-a CTGAACTCCA \
-a TGAACTCCAG \
-a GAACTCCAGT \
-a AACTCCAGTC \
-a ACTCCAGTCA \
-j 8 \
/stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fq.gz

gzip pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTr.fq

cutadapt \
-u -10 \
-o pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq \
-j 8 \
/stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTr.fq

gzip pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq

fastq-sort \
--id /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq > pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.sorted.fq

gzip -c /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq

fastqc \
-t 2 \
--extract \
-k 7 \
-o . \
/stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.gz

filter_primers.py \
--read1 /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.gz \
--primer AGTGCAATGATATTGTCAAAGC \
--output_file pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq

fastq-sort \
--id /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq > pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.sorted.fq
```
### MAP TO REPEAT ELEMENTS
```
STAR \
--alignEndsType EndToEnd \
--genomeDir /stage/star_2_7_homo_sapiens_repbase_fixed_v2 \
--genomeLoad NoSharedMemory \
--outBAMcompression 10 \
--outFileNamePrefix pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.STAR \
--outFilterMultimapNmax 30 \
--outFilterMultimapScoreRange 1 \
--outFilterScoreMin 10 \
--outFilterType BySJout \
--outReadsUnmapped Fastx \
--outSAMattrRGline ID:foo \
--outSAMattributes All \
--outSAMmode Full \
--outSAMtype BAM Unsorted \
--outSAMunmapped Within \
--outStd Log \
--readFilesIn /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.fq \
--runMode alignReads \
--runThreadN 8

mv pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.STARAligned.out.bam pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-mapped.bam

mv pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.STARUnmapped.out.mate1 pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-unmapped.fq

fastq-sort \
--id \
/stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-unmapped.fq > pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-unmapped.sorted.fq

gzip pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-unmapped.sorted.fq
```
### MAP TO GENOME
```
STAR \
--alignEndsType EndToEnd \
--genomeDir /stage/star_2_7_gencode29_sjdb \
--genomeLoad NoSharedMemory \
--outBAMcompression 10 \
--outFileNamePrefix pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-unmapped.fq.sorted.STAR \
--outFilterMatchNminOverLread 0.66 \
--outFilterMultimapNmax 1 \
--outFilterMultimapScoreRange 1 \
--outFilterScoreMin 10 \
--outFilterScoreMinOverLread 0.66 \
--outFilterType BySJout \
--outReadsUnmapped Fastx \
--outSAMattrRGline ID:foo \
--outSAMattributes All \
--outSAMmode Full \
--outSAMtype BAM Unsorted \
--outSAMunmapped Within \
--outStd Log \
--readFilesIn /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-unmapped.fq.sorted.fq \
--runMode alignReads \
--runThreadN 8

mv pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.repeat-unmapped.fq.sorted.STARAligned.out.bam pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mapped.bam

samtools sort \
-n \
-o pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSo.bam \
/stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mapped.bam

samtools sort \
-o pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.bam \
-m 3G \
/stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSo.bam

samtools index \
-b pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.bam
```
### PCR DEDUP
```
umi_tools dedup \
--random-seed 1 \
-I /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.bam \
--method unique \
-S pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDup.bam

samtools sort \
-o pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.bam \
-m 3G \
/stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDup.bam

samtools index \
-b pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.bam

makebigwigfiles \
--bw_pos pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.norm.pos.bw \
--bw_neg pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.norm.neg.bw \
--bam /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.bam \
--genome /stage/chrNameLength.txt
```
### CALL PEAK CLUSTERS
```
clipper \
--species GRCh38_v29e \
--bam /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.bam \
--outfile pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.peakClusters.bed

bedtools \
merge \
-i /stage/pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.peakClusters.bed \
-s \
-c 4,5,6 \
-o collapse,mean,distinct \
-d 1 > pcr_enriched.hsa-miR-301b-3p_F.umi.r1.fqTrTr.fq.sorted.fq.primer.fq.sorted.genome-mappedSoSo.rmDupSo.peakClusters.merged.bed
```
