version 1.0

import "Structs.wdl"

workflow BatchEvidenceMerging {
  input {
    Array[String] samples
    Array[File?]? BAF_files
    Array[File] PE_files
    Array[File] SR_files
    Array[File] LD_files
    File? ld_locs_vcf
    File genome_file
    String batch
    String gatk_docker
    RuntimeAttr? runtime_attr_override
  }

  call MergeEvidence as MergeSREvidence {
    input:
      files = SR_files,
      batch = batch,
      evidence = "sr",
      samples = samples,
      genome_file = genome_file,
      gatk_docker = gatk_docker,
      runtime_attr_override = runtime_attr_override
  }

  call MergeEvidence as MergePEEvidence {
    input:
      files = PE_files,
      batch = batch,
      evidence = "pe",
      samples = samples,
      genome_file = genome_file,
      gatk_docker = gatk_docker,
      runtime_attr_override = runtime_attr_override
  }

  if (defined(BAF_files)) {
    call MergeEvidence as MergeBAFEvidence {
      input:
        files = select_all(select_first([BAF_files])),
        batch = batch,
        evidence = "baf",
        samples = samples,
        genome_file = genome_file,
        gatk_docker = gatk_docker,
        runtime_attr_override = runtime_attr_override
    }
  }
  if (!defined(BAF_files)) {
    call LDtoBAF {
      input:
        LD_files = LD_files,
        ld_locs_vcf = select_first([ld_locs_vcf]),
        batch = batch,
        samples = samples,
        genome_file = genome_file,
        gatk_docker = gatk_docker,
        runtime_attr_override = runtime_attr_override
    }
  }

  output {
    File merged_BAF = select_first([MergeBAFEvidence.out, LDtoBAF.out])
    File merged_BAF_index = select_first([MergeBAFEvidence.out_index, LDtoBAF.out_index])
    File merged_SR = MergeSREvidence.out
    File merged_SR_index = MergeSREvidence.out_index
    File merged_PE = MergePEEvidence.out
    File merged_PE_index = MergePEEvidence.out_index
  }
}

task MergeEvidence {
  input {
    Array[File] files
    String batch
    String evidence
    Array[String] samples
    File genome_file
    String gatk_docker
    RuntimeAttr? runtime_attr_override
  }

  Int disk_size = 10 + ceil(size(files, "GiB") * 2)

  RuntimeAttr default_attr = object {
    cpu_cores: 1,
    mem_gb: 3.75,
    disk_gb: disk_size,
    boot_disk_gb: 10,
    preemptible_tries: 3,
    max_retries: 1
  }
  RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])

  output {
    File out = "~{batch}.~{evidence}.txt.gz"
    File out_index = "~{batch}.~{evidence}.txt.gz.tbi"
  }
  command <<<

    set -euo pipefail

    mv ~{write_lines(files)} evidence.list
    mv ~{write_lines(samples)} samples.list
    awk 'BEGIN{FS=OFS="\t"}{print "@SQ\tSN:"$1, "LN:"$2}' genome_file > dictionary

    /gatk/gatk PrintSVEvidence -F evidence.list --sample-names samples.list --dictionary dictionary -O "~{batch}.~{evidence}.txt.gz"

    tabix -f -s1 -b2 -e2 "~{batch}.~{evidence}.txt.gz"

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

task LDtoBAF {
  input {
    Array[File] LD_files
    File ld_locs_vcf
    String batch
    Array[String] samples
    File genome_file
    String gatk_docker
    RuntimeAttr? runtime_attr_override
  }

  Int disk_size = 10 + ceil(size(LD_files, "GiB") * 2)

  RuntimeAttr default_attr = object {
    cpu_cores: 1,
    mem_gb: 3.75,
    disk_gb: disk_size,
    boot_disk_gb: 10,
    preemptible_tries: 3,
    max_retries: 1
  }
  RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])

  output {
    File out = "~{batch}.baf.txt.gz"
    File out_index = "~{batch}.baf.txt.gz.tbi"
  }
  command <<<

    set -euo pipefail

    mv ~{write_lines(LD_files)} inputs.list
    mv ~{write_lines(samples)} samples.list
    awk 'BEGIN{FS=OFS="\t"}{print "@SQ\tSN:"$1, "LN:"$2}' genome_file > dictionary

    /gatk/gatk LocusDepthtoBAF -F inputs.list --sample-names samples.list --dictionary dictionary --baf-sites-vcf "~{ld_locs_vcf}" -O "~{batch}.baf.txt.gz"

    tabix -f -s1 -b2 -e2 "~{batch}.baf.txt.gz"

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
