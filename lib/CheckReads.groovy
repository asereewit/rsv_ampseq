//
// This file holds functions to check the number of reads after trimming and mapping
//

import groovy.json.JsonSlurper

class CheckReads {

	//
	// Function that parses and returns the number of mapped reasds from flagstat files
	//
	public static ArrayList getFlagstatMappedReads(flagstat_file, params) {
        def mapped_reads = 0
        flagstat_file.eachLine { line ->
            if (line.contains(' mapped (')) {
                mapped_reads = line.tokenize().first().toInteger()
            }
        }

        def pass = false
        def logname = flagstat_file.getBaseName() - 'flagstat'
        if (mapped_reads > params.min_mapped_reads.toInteger()) {
            pass = true
        }
        return [ mapped_reads, pass ]
    }

	//
	// Function that parses fastp json output file to get total number of reads after trimming
	//
	public static Integer getFastpReadsAfterFiltering(json_file) {
        def Map json = (Map) new JsonSlurper().parseText(json_file.text).get('summary')
        return json['after_filtering']['total_reads'].toInteger()
    }

	//
	// Function that parses fastp json output file to get total number of reads before trimming
	//
	public static Integer getFastpReadsBeforeFiltering(json_file) {
        def Map json = (Map) new JsonSlurper().parseText(json_file.text).get('summary')
        return json['before_filtering']['total_reads'].toInteger()
    }

	//
	// Append summary stats for failed (trimming/mapping) samples
	//
	public static String tsvFromList(tsv_data) {
		def default_header = ["sample_name","rsv_subtype","raw_reads","trimmed_reads","pct_reads_trimmed","mapped_reads","pct_reads_mapped","pct_genome_covered","mean_genome_coverage","pct_fusion_covered","mean_fusion_coverage","pct_fusion_50x","pct_fusion_100x","consensus_length","num_ns","num_ambiguous"]
        def tsv_string = ""
        if (tsv_data.size() > 0 ){
            tsv_string += "${default_header.join('\t')}\n"
            tsv_string += "${tsv_data.join('\n')}\n"
        }
        return tsv_string
    }

}
