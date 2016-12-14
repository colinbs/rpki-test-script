# Requirements

jq - command line parser for JSON. Necessary to parse the results of the RIPE validator.
bgpdump - RIB dump to BGP converter. Get it from http://www.ris.ripe.net/source/bgpdump/
bzip2 - Tool to decompress a RIB dump.
rpki-validator-app - RIPE RPKI Validator Download it from https://www.ripe.net/manage-ips-and-asns/resource-management/certification/tools-and-resources


# Containing Files

- rpki-validator.sh     The main script. Read the Usage section for more information.
- rtr-validator         Program that validates the RIB dump against three different library implementations.
- analysis.sh           Script to analyse the output data from the rpki-validator script.
- libs/                 Contains the three different RTRlib implementations: old, fix and trie.


# Description

The main script rpki-validator validates the decompressed RIB dump with three
different implementations of the RTRlib. To make sure that no asynchronous results due to
changes in the cache happen, a local, static cache is required. Use the RIPE RPKI
Validator with certain settings in this case.

The RIB dump will, after the main script filtered out unnecessary data, contain only two
columns: the prefix and the AS.

    101.0.64.0/18 55803
    101.0.7.0/24 55670
    101.0.8.0/24 132827
    101.0.9.0/24 132827
    101.0.94.0/24 55803

After the script ran its validation, three files will be there containing the validation
outcome. One for each RTRlib implementation:

    old-result.txt
    fix-result.txt
    trie-result.txt

All of them contain data in the same order as the formatted RIB dump, with the addition
of the validation outcome:

    101.0.64.0/18 55803 "Valid"
    101.0.7.0/24 55670 "NotFound"
    101.0.8.0/24 132827 "NotFound"
    101.0.9.0/24 132827 "Valid"
    101.0.94.0/24 55803 "Valid"


# Usage

To begin, first download and decompress a RIB dump from here http://archive.routeviews.org/bgpdata/
To decompress use the bzip2 tool:

    bzip2 -d filename.bz2

This command will get rid of the original dump. To preserve it add the -k option

The main script rpki-validator takes the decompressed RIB dump as a parameter.

    ./rpki-validator.sh rib.dump


# Analyzing the result

After the script successfully finished there will now be three new files with the results.
Compare them by executing the analysis.sh script:

    ./analysis.sh old-result.txt fix-result.txt

In this case, the output will be the statistics.txt file. It will contain the following
data (example values):

    Compared old-result.txt with fix-result.txt

    Prefixes...
    announced Invalid in old-result.txt -> announced NotFound in trie-result.txt: 0
    announced NotFound in old-result.txt -> announced Invalid in trie-result.txt: 279
    announced NotFound in old-result.txt -> announced Valid in trie-result.txt: 1286
    announced Invalid in old-result.txt -> announced Valid in trie-result.txt: 253

The order in which the script will receive its arguments is important for the outcome.
To compare into the other direction, switch the order of the arguments.
