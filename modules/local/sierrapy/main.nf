process SIERRAPY {
    tag "$meta.id"
    label 'process_medium'
    errorStrategy { sleep(Math.pow(2, task.attempt) * 200 as long); return 'retry' }
    maxRetries 5
    

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker://mbdabrowska1/sierrapy:0.4.3.1' :
        'docker.io/mbdabrowska1/sierrapy:0.4.3.1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.json")      , emit: json
    path  "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def output = task.ext.outputname ?: "${meta.id}_sierrapy_output"
    """
    sierrapy fasta -o "${output}.json" "${fasta}"

    cat <<-END_VERSIONS > versions.yml
        tools:
            sierrapy: \$(sierrapy --version 2>/dev/null | awk '/SierraPy/ {print \$2}')
            sierra: \$(sierrapy --version 2>/dev/null | awk '/Sierra / {print \$4}')
            HIVdb: \$(sierrapy --version 2>/dev/null | awk '/HIVdb/ {print \$3}')
    END_VERSIONS

    """

    stub:
    def output = task.ext.outputname ?: "${meta.id}_allele_frequencies"
    """
    touch ${output}.0.json

    cat <<-END_VERSIONS > versions.yml
        tools:
            sierrapy: \$(sierrapy --version 2>/dev/null | awk '/SierraPy/ {print \$2}')
            sierra: \$(sierrapy --version 2>/dev/null | awk '/Sierra / {print \$4}')
            HIVdb: \$(sierrapy --version 2>/dev/null | awk '/HIVdb/ {print \$3}')
    END_VERSIONS
    """
}
