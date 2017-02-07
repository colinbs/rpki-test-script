# Requirements

* [jq](https://stedolan.github.io/jq/) - command line parser for JSON. Necessary to parse the results of the RIPE validator.
* [bgpdump](http://www.ris.ripe.net/source/bgpdump/) - RIB dump to BGP converter.
* [bzip2](http://bzip.org/) - Tool to decompress a RIB dump.
<!--* [rpki-validator-app](https://www.ripe.net/manage-ips-and-asns/resource-management/certification/tools-and-resources) - RIPE RPKI Validator.-->
* [RTRTestsuite](https://github.com/rtrlib/rtr-testsuite/releases/tag/0.0.1) - RTR Test Suite based on the RPKI RIPE Validator.


# Containing Files

- _rpki-validator_ - The main script. Read the Usage section for more information.
- _rtr-validator_ - Program that validates the RIB dump against three different library implementations.
- _analysis_ - Script to analyse the output data from the rpki-validator script.
- _libs/_ - Contains the three different RTRlib implementations: old, fix and trie.


# Description

The main script rpki-validator validates the decompressed RIB dump with three different implementations of the RTRlib. To make sure that no asynchronous results due to changes in the cache happen, a local, static cache is required. Use the RIPE RPKI Validator with certain settings in this case.

The RIB dump will, after the main script filtered out unnecessary data, contain only two columns: the prefix and the AS.

    101.0.64.0/18 55803
    101.0.7.0/24 55670
    101.0.8.0/24 132827
    101.0.9.0/24 132827
    101.0.94.0/24 55803

After the script ran its validation, three files will be there containing the validation outcome. One for each RTRlib implementation:

    old-result.txt
    fix-result.txt
    trie-result.txt

All of them contain data in the same order as the formatted RIB dump, with the addition of the validation outcome:

    101.0.64.0/18 55803 "Valid"
    101.0.7.0/24 55670 "NotFound"
    101.0.8.0/24 132827 "NotFound"
    101.0.9.0/24 132827 "Valid"
    101.0.94.0/24 55803 "Valid"


# Usage

To begin, first download and decompress a RIB dump from [here](http://archive.routeviews.org/bgpdata/).
To decompress use the `bzip2` tool:

    bzip2 -d filename.bz2

This command will get rid of the original dump. To preserve it, add the -k option.

Next, download, extract and start the RTR Test Suite on a port of your choice, e.g. 8181:

    tar -xzf RTRTestsuite-0.0.1-SNAPSHOT-dist.tar.gz
    ./RTRTestsuite-0.0.1-SNAPSHOT/rtr-testsuite.sh 8181

You will be prompted with a CLI. Type `help` for all options. Now the ROAs must be added to the cache of the testing environment. There is a _roas_ file in the root of this repository which can be used. You can add additional entries to the file in the format '\[ASN\] \[Prefix\] \[MaxLen\]'. Then, enter into the CLI:

    addfile path/to/roa/file

Open a new Terminal. The main script _rpki-validator_ takes the decompressed RIB dump as a parameter, as well as the host and port of the cache. Use _localhost_ for <host> and the port used to start the RTRTestsuite for <port>:

    ./rpki-validator.sh rib.dump <host> <port>


# Analyzing the result

After the script successfully finished there will now be three new files with the results. Compare them by executing the _analysis_ script:

    ./analysis.sh lpfst-result.txt trie-result.txt rpki-result.txt

The output file _statistics.txt_ will contain all ROAs from which the validation result differs from each other and show the validation results for lpfst, trie and the RIPE RPKI validator.
