from __future__ import print_function
import sys

#TODO: Fix overlaps for transcripts with multiple SVs

def create_table(transcript_file, overlap_file):
    transcript_exons = {}
    transcript_overlap = {}

    with open(transcript_file, 'r') as f:
        for line in f:
            temp = line.rstrip().split("\t")
            transcript = temp[0]
            info = temp[2]
            info = info.split(";")
            transcript_exons[transcript] = info

    with open(overlap_file, 'r') as f:
        for line in f:
            temp = line.rstrip().split("\t")
            transcript = temp[0]
            sv = temp[1]
            info = temp[2]
            info = info.split(";")
            id = transcript + "-" + sv
            transcript_overlap[id] = info

    return(transcript_exons, transcript_overlap)

def main():
    transcript_filename = sys.argv[1]
    overlap_filename = sys.argv[2]
    exon_info, overlap_info = create_table(transcript_filename, overlap_filename)

    for transcript in overlap_info:
        overlaps = overlap_info[transcript]
        affected_exons = []

        for overlap in overlaps:
            exon = overlap.split(" ")[0]
            affected_exons.append(exon)

        (transcript, sv) = transcript.split("-")
        all_exons = exon_info[transcript]
        uneffected_exons = []

        for test_exon in all_exons:
            exon = test_exon.split(" ")[0]
            if not (exon in affected_exons):
                uneffected_exons.append(test_exon)

        print(transcript + "\t" + sv + "\t" + ";".join(overlaps) + "\t" + ";".join(uneffected_exons)) 

if __name__ == '__main__':
    main()
