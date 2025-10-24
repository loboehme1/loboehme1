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
    if (params.step == 3) {
        in_ch = channel.fromPath('samplesheet.csv')
            | splitCsv(header: true, sep: ',')
            | map { row ->
                def meta = [:]
                def files = []
                
                // Extract metadata (everything except file paths)
                meta.id = row.sample
                meta.strandedness = row.strandedness
                
                // Extract file paths
                files = [row.fastq_1, row.fastq_2]
                
                return [meta, files]
            }
        
        // Branch based on strandedness
        branched = in_ch.branch {
            forward: it[0].strandedness == 'forward'
            reverse: it[0].strandedness == 'reverse'
            unstranded: it[0].strandedness == 'unstranded'
            auto: it[0].strandedness == 'auto'
        }
        
        // Display each branch with labels
        branched.forward.view { "FORWARD: $it" }
        branched.reverse.view { "REVERSE: $it" }
        branched.unstranded.view { "UNSTRANDED: $it" }
        branched.auto.view { "AUTO: $it" }
    }

    // Task 4 - Group together all files with the same sample-id and strandedness value.

    if (params.step == 4) {
        in_ch = channel.fromPath('samplesheet.csv')
            | splitCsv(header: true, sep: ',')
            | map { row ->
                def meta = [id: row.sample, strandedness: row.strandedness]
                def files = [row.fastq_1, row.fastq_2]
                return [meta, files]
            }
        
        // Group by sample ID and strandedness combination
        grouped = in_ch.groupTuple(by: [0])  // Group by the first element (meta map)
        grouped.view { meta, filesList ->
            "SAMPLE: ${meta.id}, STRANDEDNESS: ${meta.strandedness} -> FILES: ${filesList}"
        }
    }



}