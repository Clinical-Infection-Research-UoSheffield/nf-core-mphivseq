process REPORTS {
    tag "$meta.id"
    label 'process_medium'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mbdabrowska1/vs_r_reports:1.2' :
        'docker.io/mbdabrowska1/vs_r_reports:1.2' }"

    input:
    tuple val(meta), path(scores), path(mutations)

    output:
    tuple val(meta), path("*.html")     , emit: html
    path  "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    // Split by the last underscore
    def parts = prefix.split('_')
    def dataset = parts[0..-2].join('_')  // Everything except the last part
    def barcode = parts[-1]  // The last part

    """
    cp /app/r_reports2.Rmd ./
    cp /app/report-style.css ./
    cp /app/uos-logo.png ./
    
    Rscript -e "rmarkdown::render('r_reports2.Rmd', params = list(dataset ='${dataset}', barcode ='${barcode}', mutations_file = '${mutations}', drug_scores_file = '${scores}'), output_file = '${prefix}_report.html')"

    cat <<-END_VERSIONS > versions.yml
        r-packages:
            readr: \$(Rscript -e 'packageVersion("readr")')
            kableExtra: \$(Rscript -e 'packageVersion("kableExtra")')
            DT: \$(Rscript -e 'packageVersion("DT")')
            dplyr: \$(Rscript -e 'packageVersion("dplyr")')
            ggplot2: \$(Rscript -e 'packageVersion("ggplot2")')
        
        tools:
            pandoc: \$(pandoc --version | head -n1 | awk '{print \$2}')
    END_VERSIONS

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_report.html

    cat <<-END_VERSIONS > versions.yml
        r-packages:
            readr: \$(Rscript -e 'packageVersion("readr")')
            kableExtra: \$(Rscript -e 'packageVersion("kableExtra")')
            DT: \$(Rscript -e 'packageVersion("DT")')
            dplyr: \$(Rscript -e 'packageVersion("dplyr")')
            ggplot2: \$(Rscript -e 'packageVersion("ggplot2")')
        
        tools:
            pandoc: \$(pandoc --version | head -n1 | awk '{print \$2}')
    END_VERSIONS
    """
}
