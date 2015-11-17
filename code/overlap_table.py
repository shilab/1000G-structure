from __future__ import print_function
import sys

def create_table(file):
    transcript_overlaps= {}

    with open(file, 'r') as f:
        for line in f:
            temp = line.rstrip().split("\t")
            transcript = temp[3]
            exon_num = temp[4]
            type = temp[6]
            percent = temp[9]
            sv = temp[5]

            id = transcript + "\t" + sv

            if id in transcript_overlaps:
                old = transcript_overlaps[id]
                old.append(str(exon_num) + " " + type + " " + str(percent))
                transcript_overlaps[id] = old
            else:
                transcript_overlaps[id] = [str(exon_num) + " " + type + " " + str(percent)]

    return transcript_overlaps

def main():
    filename = sys.argv[1]
    overlap_info = create_table(filename)
    
    for id in overlap_info:
        print(id + "\t" + ";".join(overlap_info[id]))

if __name__ == '__main__':
    main()
