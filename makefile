SHELL=/bin/bash

all: setup Data

setup: 
	mkdir -p data

Data: data/cds_intersections data/breakpoint_intersections data/affected_exons

data/Homo_sapiens.GRCh37.75.gtf:
	wget -P ./data ftp://ftp.ensembl.org/pub/release-75/gtf/homo_sapiens/Homo_sapiens.GRCh37.75.gtf.gz
	gunzip data/Homo_sapiens.GRCh37.75.gtf.gz

data/1KG_phase3_all_bkpts.v5.txt:
	wget -P ./data ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/integrated_sv_map/supporting/breakpoints/1KG_phase3_all_bkpts.v5.txt.gz
	gunzip data/1KG_phase3_all_bkpts.v5.txt.gz

data/protein_coding_cds.bed: data/Homo_sapiens.GRCh37.75.gtf
	awk '$$2=="protein_coding" && $$3=="CDS" {print}' data/Homo_sapiens.GRCh37.75.gtf | awk -F $$'\t' '{print $$1"\t"$$4"\t"$$5"\t"$$1,$$4,$$5,$$9}'> data/protein_coding_cds.bed

data/breakpoints.bed: data/1KG_phase3_all_bkpts.v5.txt
	cut -f 1-4 data/1KG_phase3_all_bkpts.v5.txt > data/breakpoints.bed

data/breakpoint_intersections: data/breakpoints.bed data/protein_coding_cds.bed
	bedtools intersect -a data/breakpoints.bed -b data/protein_coding_cds.bed > data/breakpoint_intersections

data/cds_intersections: data/breakpoints.bed data/protein_coding_cds.bed
	bedtools intersect -a data/protein_coding_cds.bed -b data/breakpoints.bed > data/cds_intersections

data/intersection_annotation: data/cds_intersections data/breakpoint_intersections
	paste <(cut -f 1,2,3 data/cds_intersections) <(cut -f 4 data/cds_intersections | cut -d' ' -f 7 | sed 's/"\|;//g') <(cut -f 4 data/cds_intersections | cut -d' ' -f 9 | sed 's/"\|;//g') <(cut -f 4 data/breakpoint_intersections) > data/intersection_annotation

data/intersection_annotation_svs: data/intersection_annotation data/1KG_phase3_all_bkpts.v5.txt
	join -1 6 -2 4 <(sort -k6,6 data/intersection_annotation) <(sort -k4,4 data/1KG_phase3_all_bkpts.v5.txt) | awk '{print $$2"\t"$$3"\t"$$3"\t"$$5"\t"$$6"\t"$$1"\t"$$10}' > data/intersection_annotation_svs

data/cds_intersection_sizes: data/cds_intersections
	paste <(awk '{print $$3-$$2+1}' data/cds_intersections) <(cut -f 4 data/cds_intersections | awk '{print $$3-$$2+1}') | awk '{print $$1"\t"$$2"\t"$$1/$$2*100}' > data/cds_intersection_sizes

data/intersection_annotation_svs_size: data/intersection_annotation_svs data/cds_intersection_sizes
	paste data/intersection_annotation_svs data/cds_intersection_sizes > data/intersection_annotation_svs_size

data/protein_coding: data/Homo_sapiens.GRCh37.75.gtf
	awk '$$2=="protein_coding" && $$3=="CDS" {print}' data/Homo_sapiens.GRCh37.75.gtf > data/protein_coding

data/transcript_info: data/protein_coding
	python code/transcript_table.py data/protein_coding > data/transcript_info

data/overlap_table: data/intersection_annotation_svs_size
	python code/overlap_table.py data/intersection_annotation_svs_size > data/overlap_table

data/affected_exons: data/overlap_table data/transcript_info
	python code/affected_exons.py data/transcript_info data/overlap_table > data/affected_exons
