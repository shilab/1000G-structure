from __future__ import print_function
import urllib2

url = 'http://www.rcsb.org/pdb/rest/search'

queryPart1 = """
<orgPdbQuery>
  <queryType>org.pdb.query.simple.UniprotGeneNameQuery</queryType>
    <query>
"""
queryPart2 = """
    </query>
</orgPdbQuery>
"""

geneFile = "data/unique_exons_unique_genes"
with open(geneFile, 'r') as f:
    for line in f:
        geneName = line.rstrip().split(" ")[-1]
        query = queryPart1.rstrip() + geneName + queryPart2.lstrip()

        req = urllib2.Request(url, data=query)
        res = urllib2.urlopen(req)
        result = res.read()
        if result:
            result = ",".join(result.rstrip().split("\n"))
            print(geneName + "\t" + result)
        else:
            print(geneName + "\tNA")
