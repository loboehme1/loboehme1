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

    def in_ch = Channel
        .fromPath('../day_02/fetchngs-out/samplesheet/samplesheet.csv')
        .splitCsv(header: true, sep: ',', quote: '"')
        .filter { row -> row.fastq_1 && row.fastq_2 }
        .map { row ->
            def meta  = row.findAll { k, v -> k != 'fastq_1' && k != 'fastq_2' }
            def files = [ file(row.fastq_1), file(row.fastq_2) ]
            [ meta, files ]
        }

    // 🧠 Debug what .branch() receives
    in_ch.map { pair ->
        println "\n--- DEBUG ITEM ---"
        println pair.getClass()
        println pair.inspect()
        return pair
    }
    .branch {
        // for now just send everything to 'auto' so we can confirm it works
        auto: true
    }
    .auto
    .view()
}






    // Task 4 - Group together all files with the same sample-id and strandedness value.

    if (params.step == 4) {
        
    }



}