process VCF_PROCESS {
    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mbdabrowska1/mpileup_python:1.1' :
        'docker.io/mbdabrowska1/mpileup_python:1.1' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.csv")       , emit: csv
    path  "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def output = task.ext.outputname ?: "${meta.id}_allele_frequencies"
    """
    python /app/vcf_process.py "${vcf}" --output_file "${output}.csv"

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
    def output = task.ext.outputname ?: "${meta.id}_allele_frequencies"
    """
    touch ${output}.csv

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
