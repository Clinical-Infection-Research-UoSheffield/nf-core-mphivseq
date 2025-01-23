<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-mphivseq_logo_dark.png">
    <img alt="nf-core/mphivseq" src="docs/images/nf-core-mphivseq_logo_light.png">
  </picture>
</h1>[![GitHub Actions CI Status](https://github.com/nf-core/mphivseq/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/mphivseq/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/mphivseq/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/mphivseq/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/mphivseq/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/mphivseq)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23mphivseq-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/mphivseq)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/mphivseq** is a bioinformatics pipeline designed to analyze HIV sequencing data for the presence of majority and minority variants of mutations as defined by the HIVdb Stanford database. The workflow includes steps for quality control, alignment, variant calling, and report generation using various bioinformatics tools, culminating in a comprehensive html report.

The mpileup HIV pipeline processes FASTQ files from sequencing to identify mutations in the PR, RT, and INT proteins using the Stanford consensus sequence for subtype B (download link: [![HXB2 x Consensus B](https://cms.hivdb.org/prod/downloads/HXB2_x_ConsensusB.fas)]) (source: [![Stanford HIVDB release notes](https://hivdb.stanford.edu/page/release-notes/#appendix.1.consensus.b.sequences)]). During processing, any variant bases with a frequency below 10% are discarded. The remaining mutations are then assembled into artificial alleles. The 1st allele is created by taking the most common base at each position, while the 2nd allele is built from the second most common base, with gaps filled by the reference sequence where no mutations are present. This process is repeated for the 3rd and 4th most common bases, resulting in four artificial alleles with varying mutation frequencies. These sequences are queried against Stanford HIVDB to receive information about drug susceptibility and subtype annotation. All the information is put into html reports which can be further printed or saved as pdf files. 


### Workflow Steps
1. **Run FastQC**: 
   - Input: `ch_samplesheet`
   - Output: `ch_multiqc_files`, `ch_versions`

2. **Collate and Save Software Versions**:
   - Input: `ch_versions`
   - Output: `ch_collated_versions`

3. **Align with Minimap2**:
   - Input: `ch_samplesheet`, `params.reference`
   - Output: `ch_aligned`

4. **Filter and View BAM Files**:
   - Input: `ch_aligned`
   - Output: `ch_filtered`

5. **Run BCFTOOLS Mpileup**:
   - Input: `ch_filtered`, `params.reference`
   - Output: `BCFTOOLS_MPILEUP.out.vcf`

6. **Process VCF Files**:
   - Input: `BCFTOOLS_MPILEUP.out.vcf`
   - Output: `VCF_PROCESS.out.csv`
   - Description: Reformats the VCF file to extract allele information and frequencies for each gene position. It removes alleles with frequencies below 10%. This script converts raw VCF data into a more interpretable format for further analysis.

7. **Process Allele Sequences**:
   - Input: `VCF_PROCESS.out.csv`
   - Output: `ALLELE_SEQ.out.fasta`
   - Description: Takes columns from the VCF processing step (reference allele, allele 1, allele 2, allele 3, and allele 4) and constructs nucleotide sequences. Where there is no nucleotide it takes the reference nucleotide. For alleles with frequencies below 10%, it uses the reference allele instead. The resulting sequences are written to a FASTA file, which is prepared for subsequent analysis by HIVDB.

8. **Run SierraPy**:
   - Input: `ALLELE_SEQ.out.fasta`
   - Output: `SIERRAPY.out.json`
   - Description: Analyses the FASTA file using Stanford HIVDB to identify mutation calls. Outputs the results in JSON format. HIVDB web server available at https://hivdb.stanford.edu/hivdb/by-sequences/

9. **Combine JSON and CSV Results**:
    - Input: `SIERRAPY.out.json`, `VCF_PROCESS.out.csv`
    - Output: `ch_json_process`

10. **Process JSON Results**:
    - Input: `ch_json_process`
    - Output: `JSON_PROCESS.out.results`
    - Description: Reformats the JSON output from HIVDB. It looks up frequency of a mutation in the following ways:
      - looks for 3 rows which constitute the codon of a mutation 
      - looks at the allele column that corresponds to the variant the mutation came from 
      - double checks that the allele is different than the reference 
      - takes the frequency of the allele 
      - transforms it into percentage value

11. **Generate Reports**:
    - Input: `JSON_PROCESS.out.results`
    - Output: `REPORTS.out`
    - Description: Runs R script to combine information and output a html report

12. **Run MultiQC**:
    - Input: `ch_multiqc_files`, `ch_multiqc_config`, `ch_multiqc_custom_config`, `ch_multiqc_logo`
    - Output: `MULTIQC.out.report`

### Channels
- **ch_samplesheet**: Channel containing the input samplesheet, which lists the sequencing data files to be processed. Derived from params.input.
- **ch_versions**: Channel containing the software versions used in the workflow, ensuring reproducibility.
- **ch_multiqc_files**: Channel containing files to be aggregated by MultiQC for a comprehensive quality control report.
- **ch_collated_versions**: Channel containing the collated software versions, compiled into a single file.
- **ch_aligned**: Channel containing aligned BAM files, which are the result of mapping sequencing reads to the reference genome via minimap2.
- **ch_filtered**: Channel containing filtered BAM files, which have been processed to remove unmapped reads.
- **ch_json_process**: Channel containing combined JSON and CSV results, which are used for downstream analysis and report generation.

### Parameters
- **params.reference**: Path to the reference genome file used for aligning sequencing reads (HXB2).
- **params.intervals**: Specific genomic intervals to be used for filtering during bcftools mpileup, allowing for targeted analysis.
- **params.multiqc_config**: Path to a custom configuration file for MultiQC, enabling tailored quality control reports.
- **params.multiqc_logo**: Path to a custom logo file for MultiQC reports, allowing for branding and customization.
- **params.multiqc_methods_description**: Custom methods description text for MultiQC reports, providing detailed information about the analysis methods used.


## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq,AEG588A1_S1_L002_R2_001.fastq
```
Each row represents a pair of fastq files (paired-end sequencing data). The input files should be in fastq or fastq.gz format.

Now, you can run the pipeline using:

```bash
nextflow run nf-core/mphivseq \
  -profile <docker/singularity/.../institute> \
  --input samplesheet.csv \
  --reference <path_to_reference_genome>.fasta \
  --intervals <path_to_intervals_file>.bed \
  --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/mphivseq/usage) and the [parameter documentation](https://nf-co.re/mphivseq/parameters).

## Pipeline output

The pipeline generates several output files, with the most important being the HTML report. This report provides a detailed summary of the analysis results, including the presence of majority and minority variants of mutations as defined by the HIVdb Stanford database.

### Key Outputs

- **HTML Report**: The main output of the pipeline, providing a comprehensive summary of the analysis results. This report includes:
  - Sample Information (runID, timestamps, sampleID)
  - HIV Subtype 
  - Protease mutations (Major, Accessory, Other)
  - Reverse Transcriptase mutations (Major, Accessory, Other)
  - Integrase mutations (Major, Accessory, Other)
  - Inhibitor susceptibility and drug effectivness
  - Additional information on inhibitor susceptibility scoring
  - **Location**: `report/`

- **MultiQC Report**: A summary report generated by MultiQC, aggregating quality control metrics from various steps in the pipeline.
  - **Location**: `multiqc/`

- **Aligned BAM Files**: Files containing sequencing reads aligned to the reference genome.
  - **Location**: `minimap2/`

- **Filtered BAM Files**: Aligned BAM files that have been processed to remove unwanted reads.
  - **Location**: `samtools/`

- **Variant Call Files (VCF)**: Files containing the called variants from the sequencing data.
  - **Location**: `bcftools/`

- **Allele FASTA Files**: FASTA files containing 4 artificial alleles for each sample.
  - **Location**: `allele/`

- **FastQC Reports**: Quality control reports generated by FastQC for the input sequencing data.
  - **Location**: `fastqc/`

- **JSON Files**: Folder containing two CSV files for each sample:
  - One with scores for each drug
  - One with mutations for each allele and their frequencies
  - **Location**: `json/`

- **SierraPy JSON Report**: A JSON report generated by Sierra after running it against the HIVdb database
  - **Location**: `sierrapy/`

- **Software Versions**: A YAML file listing the software versions used in the workflow, ensuring reproducibility.
  - **Location**: `pipeline_info/`

To see the results of an example test run with a full-size dataset, refer to the [results](https://nf-co.re/mphivseq/results) tab on the nf-core website pipeline page. For more details about the output files and reports, please refer to the [output documentation](https://nf-co.re/mphivseq/output).

## Credits

nf-core/mphivseq was originally written by Magdalena Dabrowska at the University of Sheffield.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#mphivseq` channel](https://nfcore.slack.com/channels/mphivseq) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/mphivseq for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) --><!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
