//
// This file holds several functions specific to the workflow/rsv_ampseq.nf in the nf-core/rsv_ampseq pipeline
//

import groovy.text.SimpleTemplateEngine

class WorkflowRsv_ampseq {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
		if (!params.ref_RSVA) {
			log.error "RSVA reference genome fasta file not specified. Use '--ref_RSVA RSVA_ref.fa' to specify."
			System.exit(1)
		}
		if (!params.ref_RSVB) {
			log.error "RSVB reference genome fasta file not specified. Use '--ref_RSVB RSVB_ref.fa' to specify."
			System.exit(1)
		}
		if (!params.primer_bed_RSVA) {
			log.error "RSVA primer bed file not specified. Use '--primer_bed_RSVA RSVA.primer.bed' to specify."
			System.exit(1)
		}
		if (!params.primer_bed_RSVB) {
			log.error "RSVB primer bed file not specified. Use '--primer_bed_RSVB RSVB.primer.bed' to specify."
			System.exit(1)
		}
		if (!params.ref_gff_RSVA) {
			log.error "RSVA reference gff file not specified. Use '--ref_gff_RSVA RSVA_ref.gff' to specify."
			System.exit(1)
		}
		if (!params.ref_gff_RSVB) {
			log.error "RSVB reference gff file not specified. Use '--ref_gff_RSVB RSVB_ref.gff' to specify."
			System.exit(1)
		}
		if (!params.RSVA_F_coord) {
			log.error "RSVA fusion gene coordinates (1-based) not specified. Use '--RSVA_F_coord xxxx-yyyy' to specify."
			System.exit(1)
		}
		if (!params.RSVB_F_coord) {
			log.error "RSVB fusion gene coordinates (1-based) not specified. Use '--RSVB_F_coord xxxx-yyyy' to specify."
			System.exit(1)
		}
		if (!params.RSVA_F_length) {
			log.error "RSVA fusion gene length not specified. Use '--RSVA_F_length xxxx' to specify."
			System.exit(1)
		}
		if (!params.RSVB_F_length) {
			log.error "RSVB fusion gene length not specified. Use '--RSVB_F_length xxxx' to specify."
			System.exit(1)
		}

    }

    //
    // Get workflow summary for MultiQC
    //
    public static String paramsSummaryMultiqc(workflow, summary) {
        String summary_section = ''
        for (group in summary.keySet()) {
            def group_params = summary.get(group)  // This gets the parameters of that particular group
            if (group_params) {
                summary_section += "    <p style=\"font-size:110%\"><b>$group</b></p>\n"
                summary_section += "    <dl class=\"dl-horizontal\">\n"
                for (param in group_params.keySet()) {
                    summary_section += "        <dt>$param</dt><dd><samp>${group_params.get(param) ?: '<span style=\"color:#999999;\">N/A</a>'}</samp></dd>\n"
                }
                summary_section += "    </dl>\n"
            }
        }

        String yaml_file_text  = "id: '${workflow.manifest.name.replace('/','-')}-summary'\n"
        yaml_file_text        += "description: ' - this information is collected when the pipeline is started.'\n"
        yaml_file_text        += "section_name: '${workflow.manifest.name} Workflow Summary'\n"
        yaml_file_text        += "section_href: 'https://github.com/${workflow.manifest.name}'\n"
        yaml_file_text        += "plot_type: 'html'\n"
        yaml_file_text        += "data: |\n"
        yaml_file_text        += "${summary_section}"
        return yaml_file_text
    }

    public static String methodsDescriptionText(run_workflow, mqc_methods_yaml) {
        // Convert  to a named map so can be used as with familar NXF ${workflow} variable syntax in the MultiQC YML file
        def meta = [:]
        meta.workflow = run_workflow.toMap()
        meta["manifest_map"] = run_workflow.manifest.toMap()

        meta["doi_text"] = meta.manifest_map.doi ? "(doi: <a href=\'https://doi.org/${meta.manifest_map.doi}\'>${meta.manifest_map.doi}</a>)" : ""
        meta["nodoi_text"] = meta.manifest_map.doi ? "": "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

        def methods_text = mqc_methods_yaml.text

        def engine =  new SimpleTemplateEngine()
        def description_html = engine.createTemplate(methods_text).make(meta)

        return description_html
    }
}
