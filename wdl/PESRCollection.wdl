version 1.0

import "Structs.wdl"

# Workflow to run PE/SR collection on a single sample
workflow PESRCollection {
  input {
    File cram
    File cram_index
    String sample_id
    String gatk_docker
    File reference_fasta
    File reference_index
    File reference_dict
    File? gatk_jar_override
    RuntimeAttr? runtime_attr_override
  }

  call RunPESRCollection {
    input:
      cram = cram,
      cram_index = cram_index,
      sample_id = sample_id,
      reference_fasta = reference_fasta,
      reference_index = reference_index,
      reference_dict = reference_dict,
      gatk_docker = gatk_docker,
      gatk_jar_override = gatk_jar_override,
      runtime_attr_override = runtime_attr_override
  }

  output {
    File disc_out = RunPESRCollection.disc_out
    File disc_out_index = RunPESRCollection.disc_out_index
    File split_out = RunPESRCollection.split_out
    File split_out_index = RunPESRCollection.split_out_index
  }
}

# Task to run collect-pesr on a single sample
task RunPESRCollection {
  input {
    File cram
    File cram_index
    File reference_fasta
    File reference_index
    File reference_dict
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
    disk_gb: vm_disk_size
  }
  RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])

  Float mem_gb = select_first([runtime_attr.mem_gb, default_attr.mem_gb])
  Int command_mem_mb = ceil(mem_gb * 1000 - 500)

  output {
    File split_out = "${sample_id}.sr.txt.gz"
    File split_out_index = "${sample_id}.sr.txt.gz.tbi"
    File disc_out = "${sample_id}.pe.txt.gz"
    File disc_out_index = "${sample_id}.pe.txt.gz.tbi"
  }
  command <<<

    set -euo pipefail

    export GATK_LOCAL_JAR=~{default="/root/gatk.jar" gatk_jar_override}

    /gatk/gatk --java-options "-Xmx~{command_mem_mb}m" CollectSVEvidence \
        -I ~{cram} \
        --pe-file ~{sample_id}.pe.txt.gz \
        --sr-file ~{sample_id}.sr.txt.gz \
        --sample-name ~{sample_id} \
        -R ~{reference_fasta}

    tabix -f -s1 -b 2 -e 2 ~{sample_id}.pe.txt.gz
    tabix -f -s1 -b 2 -e 2 ~{sample_id}.sr.txt.gz

  >>>
  runtime {
    cpu: select_first([runtime_attr.cpu_cores, default_attr.cpu_cores])
    memory: select_first([runtime_attr.mem_gb, default_attr.mem_gb]) + " GiB"
    disk: select_first([runtime_attr.disk_gb, default_attr.disk_gb]) + " GB"
    docker: gatk_docker
    preemptible: true
    maxRetries: 3
  }

}

