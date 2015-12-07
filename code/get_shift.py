size = {}
diff = {}

with open('data/transcript_trans', 'r') as f:
    for line in f:
        temp = line.rstrip().split('\t')
        size[temp[0]]=temp[1]

with open('data/cds_overlap_size', 'r') as f:
    for line in f:
        temp = line.rstrip().split('\t')
        id = temp[0] + '\t' + temp[1]
        diff[id] = temp[2]

for overlap in diff:
    transcript, sv = overlap.split('\t')
    length = size[transcript]
    affected = int(length) - int(diff[overlap])
    print transcript + '\t' + sv + '\t' + length + '\t' + str(affected) + '\t' + str(affected%3)
