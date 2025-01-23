process JSON_PROCESS {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mbdabrowska1/mpileup_python:1.1' :
        'docker.io/mbdabrowska1/mpileup_python:1.1' }"

    input:
    tuple val(meta), path(json), path(csv)

    output:
    tuple val(meta), path("*_drug_scores.csv"), path("*_mutations_report.csv")       , emit: results
    path  "versions.yml"                                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    python /app/json_process.py ${json} --drug_scores_output "${prefix}_drug_scores.csv" --mutations_report_output "${prefix}_mutations_report.csv" --allele_frequencies ${csv}


    cat <<-END_VERSIONS > versions.yml
        python-packages:
            biopython: \$(pip show biopython 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            numpy: \$(pip show numpy 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            pandas: \$(pip show pandas 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            pysam: \$(pip show pysam 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            python-dateutil: \$(pip show python-dateutil 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            pytz: \$(pip show pytz 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            vcfpy: \$(pip show vcfpy 2>/dev/null | grep '^Version:' | awk '{print \$2}')
    END_VERSIONS

    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_drug_scores.csv
    touch ${prefix}_mutations_report.csv

    cat <<-END_VERSIONS > versions.yml
        python-packages:
            biopython: \$(pip show biopython 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            numpy: \$(pip show numpy 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            pandas: \$(pip show pandas 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            pysam: \$(pip show pysam 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            python-dateutil: \$(pip show python-dateutil 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            pytz: \$(pip show pytz 2>/dev/null | grep '^Version:' | awk '{print \$2}')
            vcfpy: \$(pip show vcfpy 2>/dev/null | grep '^Version:' | awk '{print \$2}')
    END_VERSIONS
    """
}
