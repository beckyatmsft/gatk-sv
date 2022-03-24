version 1.0

import "Structs.wdl"

# Workflow to run PE/SR collection on a single sample
workflow CollectSVEvidence {
  input {
    File cram
    File cram_index
    String sample_id
    String gatk_docker
    File reference_fasta
    File reference_index
    File reference_dict
    File? ld_locs_vcf # supply this vcf of biallelic sites to generate LocusDepth file
    File? gatk_jar_override
    RuntimeAttr? runtime_attr_override
  }

  call RunCollectSVEvidence {
    input:
      cram = cram,
      cram_index = cram_index,
      sample_id = sample_id,
      reference_fasta = reference_fasta,
      reference_index = reference_index,
      reference_dict = reference_dict,
      ld_locs_vcf = ld_locs_vcf,
      gatk_docker = gatk_docker,
      gatk_jar_override = gatk_jar_override,
      runtime_attr_override = runtime_attr_override
  }

  output {
    File disc_out = RunCollectSVEvidence.disc_out
    File disc_out_index = RunCollectSVEvidence.disc_out_index
    File split_out = RunCollectSVEvidence.split_out
    File split_out_index = RunCollectSVEvidence.split_out_index
    File? ld_out = RunCollectSVEvidence.ld_out
    File? ld_out_index = RunCollectSVEvidence.ld_out_index
  }
}

# Task to run collect-pesr on a single sample
task RunCollectSVEvidence {
  input {
    File cram
    File cram_index
    File reference_fasta
    File reference_index
    File reference_dict
    File? ld_locs_vcf
    String sample_id
    File? gatk_jar_override
    String gatk_docker
    RuntimeAttr? runtime_attr_override
  }

  parameter_meta {
      cram: {
        localization_optional: true
      }
  }

  Float cram_size = size(cram, "GiB")
  Int vm_disk_size = ceil(cram_size + 50)

  RuntimeAttr default_attr = object {
    cpu_cores: 1,
    mem_gb: 3.75,
    disk_gb: vm_disk_size,
    boot_disk_gb: 10,
    preemptible_tries: 3,
    max_retries: 1
  }
  RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])

  Float mem_gb = select_first([runtime_attr.mem_gb, default_attr.mem_gb])
  Int command_mem_mb = ceil(mem_gb * 1000 - 500)

  output {
    File split_out = "${sample_id}.sr.txt.gz"
    File split_out_index = "${sample_id}.sr.txt.gz.tbi"
    File disc_out = "${sample_id}.pe.txt.gz"
    File disc_out_index = "${sample_id}.pe.txt.gz.tbi"
    File? ld_out = "${sample_id}.ld.txt.gz"
    File? ld_out_index = "${sample_id}.ld.txt.gz.tbi"
  }
  command <<<

    set -euo pipefail

    export GATK_LOCAL_JAR=~{default="/root/gatk.jar" gatk_jar_override}
    sr_file="~{sample_id}.sr.txt.gz"
    pe_file="~{sample_id}.pe.txt.gz"
    ld_file="~{sample_id}.ld.txt.gz"

    /gatk/gatk --java-options "-Xmx~{command_mem_mb}m" CollectSVEvidence \
        -I ~{cram} \
        --pe-file "$pe_file" \
        --sr-file "$sr_file" \
        ~{"--allele-count-vcf " + ld_locs_vcf + " --allele-count-file " + "$ld_file"} \
        --sample-name ~{sample_id} \
        -R ~{reference_fasta}

    tabix -f -s1 -b2 -e2 "$pe_file"
    tabix -f -s1 -b2 -e2 "$sr_file"
    if [ -f "$ld_file" ]; then
      tabix -f -s1 -b2 -e2 "$ld_file"
    fi
  >>>
  runtime {
    cpu: select_first([runtime_attr.cpu_cores, default_attr.cpu_cores])
    memory: select_first([runtime_attr.mem_gb, default_attr.mem_gb]) + " GiB"
    disks: "local-disk " + select_first([runtime_attr.disk_gb, default_attr.disk_gb]) + " HDD"
    bootDiskSizeGb: select_first([runtime_attr.boot_disk_gb, default_attr.boot_disk_gb])
    docker: gatk_docker
    preemptible: select_first([runtime_attr.preemptible_tries, default_attr.preemptible_tries])
    maxRetries: select_first([runtime_attr.max_retries, default_attr.max_retries])
  }

}

