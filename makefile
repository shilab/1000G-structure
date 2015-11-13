all: setup Data

setup: 
	mkdir -p data

Data: data/gene_intersections data/breakpoint_intersections

data/Homo_sapiens.GRCh37.75.gtf:
	wget -P ./data ftp://ftp.ensembl.org/pub/release-75/gtf/homo_sapiens/Homo_sapiens.GRCh37.75.gtf.gz
	gunzip data/Homo_sapiens.GRCh37.75.gtf.gz

data/1KG_phase3_all_bkpts.v5.txt:
	wget -P ./data ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/integrated_sv_map/supporting/breakpoints/1KG_phase3_all_bkpts.v5.txt.gz
	gunzip data/1KG_phase3_all_bkpts.v5.txt.gz

data/protein_coding_genes.bed: data/Homo_sapiens.GRCh37.75.gtf
	awk '$$2=="protein_coding" && $$3=="CDS" {print}' data/Homo_sapiens.GRCh37.75.gtf | awk -F $$'\t' '{print $$1"\t"$$4"\t"$$5"\t"$$1,$$4,$$5,$$9}'> data/protein_coding_cds.bed

data/breakpoints.bed: data/1KG_phase3_all_bkpts.v5.txt
	cut -f 1-4 data/1KG_phase3_all_bkpts.v5.txt > data/breakpoints.bed

data/breakpoint_intersections: data/breakpoints.bed data/protein_coding_cds.bed
	bedtools intersect -a data/breakpoints.bed -b data/protein_coding_cds.bed > data/breakpoint_intersections

data/gene_intersections: data/breakpoints.bed data/protein_coding_genes.bed
	bedtools intersect -a data/protein_coding_cds.bed -b data/breakpoints.bed > data/cds_intersections
