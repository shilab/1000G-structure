from __future__ import print_function
import sys

def create_table(file):
    transcript_gene = {}
    transcript_exons = {}

    with open(file, 'r') as f:
        for line in f:
            if line.startswith("#!"):
                continue
            temp = line.split("\t")
            pos = str(temp[0]) + " " + str(temp[3]) + " " + str(temp[4])
            info = temp[8]
            info = info.split(" ")
            gene_name = info[1][1:-2]
            transcript_name = info[3][1:-2]
            exon_num = info[5][1:-2]

            if transcript_name in transcript_exons:
                old = transcript_exons[transcript_name]
                old.append(str(exon_num) + " " + pos)
                transcript_exons[transcript_name] = old
            else:
                transcript_gene[transcript_name] = gene_name
                transcript_exons[transcript_name] = [str(exon_num) + " " + pos]

    return(transcript_gene, transcript_exons)

def main():
    filename = sys.argv[1]
    gene_info, exon_info = create_table(filename)
    
    for transcript in exon_info:
        print(transcript + "\t" + gene_info[transcript] + "\t" + ";".join(exon_info[transcript]))

if __name__ == '__main__':
    main()
