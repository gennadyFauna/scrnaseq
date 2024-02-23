/* --    IMPORT LOCAL MODULES/SUBWORKFLOWS     -- */
include {KALLISTOBUSTOOLS_COUNT }             from '../../modules/nf-core/kallistobustools/count/main'

/* --    IMPORT NF-CORE MODULES/SUBWORKFLOWS   -- */
include { GUNZIP }                      from '../../modules/nf-core/gunzip/main'
include { KALLISTOBUSTOOLS_REF }        from '../../modules/nf-core/kallistobustools/ref/main'

def multiqc_report    = []

workflow KALLISTO_BUSTOOLS {
    take:
    genome_fasta
    gtf
    kallisto_index
    txp2gene
    t1c
    t2c
    protocol
    kb_workflow
    ch_fastq

    main:
    ch_versions = Channel.empty()

    assert (txp2gene && kallisto_index) || (genome_fasta && gtf):
        "Must provide a genome fasta file ('--fasta') and a gtf file ('--gtf') if no index is given!"

    /*
    * Generate kallisto index
    */
    if (!kallisto_index) {
        KALLISTOBUSTOOLS_REF( genome_fasta, gtf, kb_workflow )
        txp2gene = KALLISTOBUSTOOLS_REF.out.t2g.collect()
        kallisto_index = KALLISTOBUSTOOLS_REF.out.index.collect()
        ch_versions = ch_versions.mix(KALLISTOBUSTOOLS_REF.out.versions)
        t1c = KALLISTOBUSTOOLS_REF.out.cdna_t2c.ifEmpty{ [] }
        t2c = KALLISTOBUSTOOLS_REF.out.intron_t2c.ifEmpty{ [] }
    }

    /*
    * Quantification with kallistobustools count
    */
    KALLISTOBUSTOOLS_COUNT(
        ch_fastq,
        kallisto_index,
        txp2gene,
        t1c,
        t2c,
        protocol
    )

    ch_versions = ch_versions.mix(KALLISTOBUSTOOLS_COUNT.out.versions)

    emit:
    ch_versions
    counts = KALLISTOBUSTOOLS_COUNT.out.count
    txp2gene


}
