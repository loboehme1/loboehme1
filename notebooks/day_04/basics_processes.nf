params.step = 0
params.zip = 'zip'


process SAYHELLO {
    debug true

    script:
    """
    echo "Hello World!"
    """
}

process SAYHELLO_PYTHON {
    debug true

    script:
    """
    #!/usr/bin/env python3
    print("Hello World from Python!")
    """
}

process SAYHELLO_PARAM {
    debug true

    input:
    val greeting_ch

    script:
    """
    echo ${greeting_ch}
    """
}

process SAYHELLO_FILE {
    debug true

    input:
    val input_str

    output:
    path 'result.txt'

    script:
    """
    echo ${input_str} > result.txt
    """
}

process UPPERCASE {
    input:
    val input_str

    output:
    path 'uppercase.txt'

    script:
    """
    echo ${input_str} | tr '[:lower:]' '[:upper:]' > uppercase.txt
    """
}

process PRINTUPPER {
    debug true

    input:
    path upper_file

    script:
    """
    cat ${upper_file}
    """
}

process ZIP_FILE {
    debug true

    input:
    path file_to_zip
    val zip_type


    script:
    """
    if [ "${zip_type}" == "zip" ]; then
        zip ${file_to_zip}.zip ${file_to_zip}
    elif [ "${zip_type}" == "gzip" ]; then
        gzip -c ${file_to_zip} > ${file_to_zip}.gz
    elif [ "${zip_type}" == "bzip2" ]; then
        bzip2 -c ${file_to_zip} > ${file_to_zip}.bz2
    else
        echo "Unsupported zip type: ${zip_type}"
    fi
    """
}

process ZIP_FILES {
    debug true

    input:
    path file_to_zip

    output:
    path '*.zip'
    path '*.gz'
    path '*.bz2'

    script:
    """
    zip ${file_to_zip}.zip ${file_to_zip}
    gzip -c ${file_to_zip} > ${file_to_zip}.gz
    bzip2 -c ${file_to_zip} > ${file_to_zip}.bz2
    """
}

process WRITE_FILE {
    input:
    val records  // all maps in one list

    output:
    path "results/names.tsv"

    script:
    """
    mkdir -p results
    echo -e "name\ttitle" > results/names.tsv
    ${records.collect { "echo -e '${it.name}\t${it.title}' >> results/names.tsv" }.join('\n')}
    """
}







workflow {

    // Task 1 - create a process that says Hello World! (add debug true to the process 
    // right after initializing to be sable to print the output to the console)
    if (params.step == 1) {
        SAYHELLO()
    }

    // Task 2 - create a process that says Hello World! using Python
    if (params.step == 2) {
        SAYHELLO_PYTHON()
    }

    // Task 3 - create a process that reads in the string "Hello world!" from a channel and write it to command line
    if (params.step == 3) {
        greeting_ch = Channel.of("Hello world!")
        SAYHELLO_PARAM(greeting_ch)
    }

    // Task 4 - create a process that reads in the string "Hello world!" from a channel and write it to a file. WHERE CAN YOU FIND THE FILE?
    if (params.step == 4) {
        greeting_ch = Channel.of("Hello world!")
        SAYHELLO_FILE(greeting_ch)
    }

    // Task 5 - create a process that reads in a string and converts it to uppercase and saves it to a file as output. View the path to the file in the console
    if (params.step == 5) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)
        out_ch.view()
    }

    // Task 6 - add another process that reads in the resulting file from UPPERCASE and print the content to the console (debug true). WHAT CHANGED IN THE OUTPUT?
    if (params.step == 6) {
        greeting_ch = Channel.of("Hello world!")
        out_ch = UPPERCASE(greeting_ch)
        PRINTUPPER(out_ch)
    }

    
    // Task 7 - based on the paramater "zip" (see at the head of the file), create a process that zips the file created in the UPPERCASE process either in "zip", "gzip" OR "bzip2" format.
    //          Print out the path to the zipped file in the console
    if (params.step == 7) {
        greeting_ch = Channel.of("Hello world!")
        a = UPPERCASE(greeting_ch)
        out_ch = ZIP_FILE(a, params.zip)
        //out_ch.view()
    }

    // Task 8 - Create a process that zips the file created in the UPPERCASE process in "zip", "gzip" AND "bzip2" format. Print out the paths to the zipped files in the console

    if (params.step == 8) {
        greeting_ch = Channel.of("Hello world!")
        a = UPPERCASE(greeting_ch)
        def (zip_ch, gz_ch, bz2_ch) = ZIP_FILES(a)

        zip_ch.map { it.toString() }.view { "ZIP: $it" }
        gz_ch.map { it.toString() }.view { "GZ:  $it" }
        bz2_ch.map { it.toString() }.view { "BZ2: $it" }
    }

    // Task 9 - Create a process that reads in a list of names and titles from a channel and writes them to a file.
    //          Store the file in the "results" directory under the name "names.tsv"

    if (params.step == 9) {
        in_ch = Channel.of(
            ['name': 'Harry', 'title': 'student'],
            ['name': 'Ron', 'title': 'student'],
            ['name': 'Hermione', 'title': 'student'],
            ['name': 'Albus', 'title': 'headmaster'],
            ['name': 'Snape', 'title': 'teacher'],
            ['name': 'Hagrid', 'title': 'groundkeeper'],
            ['name': 'Dobby', 'title': 'hero']
        )

        out_ch = in_ch.collect() | WRITE_FILE
        out_ch.view { "Wrote file: $it" }

            
    }

}