params.step = 0


workflow{

    // Task 1 - Read in the samplesheet.

    if (params.step == 1) {
    channel.fromPath('../day_02/fetchngs-out/samplesheet/samplesheet.csv')
        .splitCsv(header: true, sep: ',', quote: '"')
        .map { row ->
            [ 
                sample: row.sample,
                fastq_1: row.fastq_1,
                fastq_2: row.fastq_2
            ]
        }
        .view()
        .set { in_ch }
    }



    // Task 2 - Read in the samplesheet and create a meta-map with all metadata and another list with the filenames ([[metadata_1 : metadata_1, ...], [fastq_1, fastq_2]]).
    //          Set the output to a new channel "in_ch" and view the channel. YOU WILL NEED TO COPY AND PASTE THIS CODE INTO SOME OF THE FOLLOWING TASKS (sorry for that).

    // Task 2 – Build [metadata, [fastq_1, fastq_2]] with null-safe handling
    if (params.step == 2) {
        channel.fromPath('../day_02/fetchngs-out/samplesheet/samplesheet.csv')
            .splitCsv(header: true, sep: ',', quote: '"')
            .filter { row -> row.fastq_1 && row.fastq_2 }   // skip rows missing fastqs
            .map { row ->
                def meta = row.findAll { k, v -> k != 'fastq_1' && k != 'fastq_2' }
                def files = [ file(row.fastq_1), file(row.fastq_2) ]
                [ meta, files ]
            }
            .view()
            .set { in_ch }
    }


    // Task 3 - Now we assume that we want to handle different "strandedness" values differently. 
    // Split the channel into the right amount of channels and write them all to stdout so that we can understand which is which.
    if( params.step == 3 ) {

    samples = Channel
        .fromPath('../day_02/fetchngs-out/samplesheet/samplesheet.csv')
        .splitCsv(header: true)
        .map { row ->
            def sid = row.sample?.toString()?.trim()
            def r1  = row.fastq_1?.toString()?.trim()
            def r2  = row.fastq_2?.toString()?.trim()
            def s   = row.strandedness?.toString()?.trim()
            if( !sid ) error "CSV: missing 'sample' in row: ${row}"
            if( !r1  ) error "CSV: missing 'fastq_1' for sample '${sid}'"
            tuple(sid, r1, r2, s)
        }

    // Branch by strandedness (case-insensitive), include 'auto'
    def byStrand = samples.branch { sid, r1, r2, s ->
        def st = (s ?: '').toLowerCase()
        auto : !st || st in ['auto']                       // your sheet
        fr   : st in ['fr','forward','fwd','sense','firststrand']
        rf   : st in ['rf','reverse','rev','antisense','secondstrand']
        none : st in ['none','unstranded','unstr','na']
        _    : true
    }

    // Print each branch (use static wiring)
    byStrand.auto.view { sid, r1, r2, s -> "auto\t${sid}\t${r1}\t${r2 ?: ''}\t(${s})" }
    byStrand.fr.view   { sid, r1, r2, s -> "fr\t${sid}\t${r1}\t${r2 ?: ''}\t(${s})" }
    byStrand.rf.view   { sid, r1, r2, s -> "rf\t${sid}\t${r1}\t${r2 ?: ''}\t(${s})" }
    byStrand.none.view { sid, r1, r2, s -> "none\t${sid}\t${r1}\t${r2 ?: ''}\t(${s})" }
    byStrand._.view    { sid, r1, r2, s -> "other\t${sid}\t${r1}\t${r2 ?: ''}\t(${s})" }
}





    // Task 4 - Group together all files with the same sample-id and strandedness value.

    if (params.step == 4) {
        
    }



}