version 1.0

import "Structs.wdl"

# Workflow to run PE/SR collection on a single sample
workflow CollectSVEvidence {
  input {
    File cram
    File cram_index
    String sample_id
    File reference_fasta
    File reference_index
    File reference_dict
    File sd_locs_vcf
    File? gatk_jar_override
    String gatk_docker
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
      sd_locs_vcf = sd_locs_vcf,
      gatk_jar_override = gatk_jar_override,
      gatk_docker = gatk_docker,
      runtime_attr_override = runtime_attr_override
  }

  output {
    File disc_out = RunCollectSVEvidence.disc_out
    File disc_out_index = RunCollectSVEvidence.disc_out_index
    File split_out = RunCollectSVEvidence.split_out
    File split_out_index = RunCollectSVEvidence.split_out_index
    File sd_out = RunCollectSVEvidence.sd_out
    File sd_out_index = RunCollectSVEvidence.sd_out_index
  }
}

# Task to run collect-pesr on a single sample
task RunCollectSVEvidence {
  input {
    File cram
    File cram_index
    String sample_id
    File reference_fasta
    File reference_index
    File reference_dict
    File sd_locs_vcf
    Int site_depth_min_mapq = 6
    Int site_depth_min_baseq = 10
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
    File sd_out = "${sample_id}.sd.txt.gz"
    File sd_out_index = "${sample_id}.sd.txt.gz.tbi"
  }
  command <<<

    set -euo pipefail

    export GATK_LOCAL_JAR=~{default="/root/gatk.jar" gatk_jar_override}

    /gatk/gatk --java-options "-Xmx~{command_mem_mb}m" CollectSVEvidence \
        -I ~{cram} \
        --sr-file "~{sample_id}.sr.txt.gz" \
        --pe-file "~{sample_id}.pe.txt.gz" \
        --sd-file "~{sample_id}.sd.txt.gz" \
        --site-depth-locs-vcf ~{sd_locs_vcf} \
        --sample-name ~{sample_id} \
        --site-depth-min-mapq "~{site_depth_min_mapq}" \
        --site-depth-min-baseq "~{site_depth_min_baseq}" \
        -R ~{reference_fasta}

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

