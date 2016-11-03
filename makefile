SHELL=/bin/bash

all: setup Data

setup: 
	mkdir -p data

Data: data/tdup_sequences_nonframeshift data/deletion_sequences_nonframeshift

data/Homo_sapiens.GRCh37.75.gtf:
	wget -P ./data ftp://ftp.ensembl.org/pub/release-75/gtf/homo_sapiens/Homo_sapiens.GRCh37.75.gtf.gz
	gunzip data/Homo_sapiens.GRCh37.75.gtf.gz

data/1KG_phase3_all_bkpts.v5.txt:
	wget -P ./data ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/integrated_sv_map/supporting/breakpoints/1KG_phase3_all_bkpts.v5.txt.gz
	gunzip data/1KG_phase3_all_bkpts.v5.txt.gz

data/protein_coding_cds.bed: data/Homo_sapiens.GRCh37.75.gtf
	awk '$$2=="protein_coding" && $$3=="CDS" {print}' data/Homo_sapiens.GRCh37.75.gtf | awk -F $$'\t' '{print $$1"\t"$$4"\t"$$5"\t"$$1,$$4,$$5,$$9}' | grep CCDS > data/protein_coding_cds.bed

data/breakpoints.bed: data/1KG_phase3_all_bkpts.v5.txt
	cut -f 1-4 data/1KG_phase3_all_bkpts.v5.txt > data/breakpoints.bed

data/cds_intersections: data/breakpoints.bed data/protein_coding_cds.bed
	bedtools intersect -a data/protein_coding_cds.bed -b data/breakpoints.bed -wb > data/cds_intersections

data/intersection_annotation: data/cds_intersections
	paste <(cut -f 1,2,3 data/cds_intersections) <(cut -f 4 data/cds_intersections | cut -d' ' -f 7 | sed 's/"\|;//g') <(cut -f 4 data/cds_intersections | cut -d' ' -f 9 | sed 's/"\|;//g') <(cut -f 8 data/cds_intersections) > data/intersection_annotation

data/intersection_annotation_size_svs: data/intersection_annotation_size data/1KG_phase3_all_bkpts.v5.txt
	join -1 6 -2 4 <(sort -k6,6 data/intersection_annotation_size) <(sort -k4,4 data/1KG_phase3_all_bkpts.v5.txt) | awk '{print $$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6"\t"$$1"\t"$$13"\t"$$7"\t"$$8"\t"$$9}' > data/intersection_annotation_size_svs

data/cds_intersection_sizes: data/cds_intersections
	paste <(awk '{print $$3-$$2+1}' data/cds_intersections) <(cut -f 4 data/cds_intersections | awk '{print $$3-$$2+1}') | awk '{print $$1"\t"$$2"\t"$$1/$$2*100}' > data/cds_intersection_sizes

data/intersection_annotation_size: data/cds_intersection_sizes data/intersection_annotation
	paste data/intersection_annotation data/cds_intersection_sizes > data/intersection_annotation_size

data/protein_coding: data/Homo_sapiens.GRCh37.75.gtf
	awk '$$2=="protein_coding" && $$3=="CDS" {print}' data/Homo_sapiens.GRCh37.75.gtf > data/protein_coding

data/transcript_info: data/protein_coding
	python code/transcript_table.py data/protein_coding > data/transcript_info

data/overlap_table: data/intersection_annotation_size_svs
	python code/overlap_table.py data/intersection_annotation_size_svs > data/overlap_table

data/affected_exons: data/overlap_table data/transcript_info
	python code/affected_exons.py data/transcript_info data/overlap_table > data/affected_exons

data/longest_transcript: data/Homo_sapiens.GRCh37.75.gtf
	python code/longest_transcript.py data/Homo_sapiens.GRCh37.75.gtf > data/longest_transcript

data/del_pos: data/transcript_info data/intersection_annotation_size_svs
	python code/del_pos.py data/transcript_info data/intersection_annotation_size_svs > data/del_pos

data/tdup_pos: data/transcript_info data/intersection_annotation_size_svs
	python code/tdup_pos.py data/transcript_info data/intersection_annotation_size_svs > data/tdup_pos

data/tdup_pos_longest_transcript: data/tdup_pos data/longest_transcript
	join -1 1 -2 2 <(sort -k1,1 data/tdup_pos) <(sort -k2,2 data/longest_transcript) -t $$'\t' > data/tdup_pos_longest_transcript

data/del_pos_longest_transcript: data/del_pos data/longest_transcript
	join -1 1 -2 2 <(sort -k1,1 data/del_pos) <(sort -k2,2 data/longest_transcript) -t $$'\t' > data/del_pos_longest_transcript

data/del_pos_longest_transcript_strand : data/transcript_strand data/del_pos_longest_transcript
	join -1 1 -2 1 <(sort -k1,1 data/transcript_strand) <(sort -k1,1 data/del_pos_longest_transcript) -t $$'\t' | awk -F $$'\t' '{print $$1"\t"$$7"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6}' > data/del_pos_longest_transcript_strand

data/deletion_sequences: data/del_pos_longest_transcript_strand
	Rscript --vanilla --no-save code/del_seq.R

data/transcript_strand : data/Homo_sapiens.GRCh37.75.gtf
	awk '{print $$12"\t"$$7}' data/Homo_sapiens.GRCh37.75.gtf | sed 's/;//g' | sed 's/"//g' | sort | uniq > data/transcript_strand

data/tdup_pos_longest_transcript_strand : data/tdup_pos_longest_transcript data/transcript_strand
	join -1 1 -2 1 <(sort -k1,1 data/transcript_strand) <(sort -k1,1 data/tdup_pos_longest_transcript) -t $$'\t' | awk -F $$'\t' '{print $$1"\t"$$7"\t"$$2"\t"$$3"\t"$$4"\t"$$5"\t"$$6}' > data/tdup_pos_longest_transcript_strand

data/tdup_sequences: data/tdup_pos_longest_transcript_strand
	Rscript --vanilla --no-save code/tdup_seq.R

data/deletion_sequences_nonframeshift: data/deletion_sequences
	python code/frameshift.py data/deletion_sequences | grep 'NFS' > data/deletion_sequences_nonframeshift

data/tdup_sequences_nonframeshift: data/tdup_sequences
	python code/frameshift.py data/tdup_sequences | grep 'NFS' > data/tdup_sequences_nonframeshift
