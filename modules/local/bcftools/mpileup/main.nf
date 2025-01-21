process BCFTOOLS_MPILEUP {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.20--h8b25389_0':
        'biocontainers/bcftools:1.20--h8b25389_0' }"

    input:
    tuple val(meta), path(bam), path(intervals)
    tuple val(meta2), path(fasta)
    val save_mpileup

    output:
    tuple val(meta), path("*.vcf")       , emit: vcf
    tuple val(meta), path("*.mpileup.gz"), emit: mpileup, optional: true
    path  "versions.yml"                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def mpileup = save_mpileup ? "| tee ${prefix}.mpileup" : ""
    def bgzip_mpileup = save_mpileup ? "bgzip ${prefix}.mpileup" : ""
    def intervals = intervals ? "-T ${intervals}" : ""
    """
    echo "${meta.id}" > sample_name.list

    bcftools \\
        mpileup \\
        --fasta-ref $fasta \\
        $args \\
        $bam \\
        $intervals \\
        $mpileup > ${prefix}.mpileup.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bcftools_stats.txt
    echo "" | gzip > ${prefix}.vcf.gz
    touch ${prefix}.vcf.gz.tbi
    echo "" | gzip > ${prefix}.mpileup.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
