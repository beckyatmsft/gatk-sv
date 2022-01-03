version 1.0

import "GenotypePESRPart1.wdl" as gp1
import "GenotypePESRPart2.wdl" as gp2
import "GenotypeDepthPart1.wdl" as gd1
import "GenotypeDepthPart2.wdl" as gd2
import "GenotypeBatchMetrics.wdl" as metrics
import "TasksGenotypeBatch.wdl" as tasksgenotypebatch
import "Utils.wdl" as util
import "MergeBatchSites.wdl" as merge

workflow GenotypeBatch {
  input {
    File batch_pesr_vcf
    File batch_depth_vcf
    File cohort_pesr_vcf
    File cohort_depth_vcf
    String batch

    File original_batch_depth_vcf
    File original_batch_depth_vcf_index
    File original_batch_pesr_vcf
    File original_batch_pesr_vcf_index
    File original_regeno_coverage_medians

    Int n_per_split
    File coveragefile        # batch coverage file
    File? coveragefile_index # batch coverage index file
    File medianfile          # post-exclusion batch median file
    File ped_file            # cohort ped file
    File? rf_cutoffs         # Random forest cutoffs; required unless skipping training
    File? seed_cutoffs       # Required unless skipping training
    Int n_RD_genotype_bins   # number of RdTest bins
    File discfile
    File? discfile_index
    File? pesr_exclude_list  # Required unless skipping training
    File splitfile
    File? splitfile_index
    String? reference_build  #hg19 or hg38, Required unless skipping training
    File bin_exclude
    File ref_dict
    # If all specified, training will be skipped (for single sample pipeline)
    File? genotype_pesr_pesr_sepcutoff
    File? genotype_pesr_depth_sepcutoff
    File? genotype_depth_pesr_sepcutoff
    File? genotype_depth_depth_sepcutoff
    File? SR_metrics
    File? PE_metrics

    # Module metrics parameters
    # Run module metrics workflow at the end - on by default
    Boolean? run_module_metrics
    String? sv_pipeline_base_docker  # required if run_module_metrics = true
    File? primary_contigs_list  # required if run_module_metrics = true
    File? baseline_genotyped_depth_vcf  # baseline files are optional for metrics workflow
    File? baseline_genotyped_pesr_vcf

    String sv_base_mini_docker
    String sv_pipeline_docker
    String sv_pipeline_rdtest_docker
    String linux_docker

    # Common
    RuntimeAttr? runtime_attr_split_vcf
    RuntimeAttr? runtime_attr_merge_counts
    RuntimeAttr? runtime_attr_split_variants
    RuntimeAttr? runtime_attr_make_subset_vcf
    RuntimeAttr? runtime_attr_rdtest_genotype
    RuntimeAttr? runtime_attr_add_genotypes
    RuntimeAttr? runtime_attr_genotype_depths_concat_vcfs
    RuntimeAttr? runtime_attr_genotype_pesr_concat_vcfs

    # Master
    RuntimeAttr? runtime_attr_add_batch
    RuntimeAttr? runtime_attr_index_vcf
    RuntimeAttr? runtime_attr_ids_from_vcf
    RuntimeAttr? runtime_attr_subset_ped

    # PE train
    RuntimeAttr? runtime_attr_make_batch_bed
    RuntimeAttr? runtime_attr_count_pe
    RuntimeAttr? runtime_attr_pe_genotype

    # SR train
    RuntimeAttr? runtime_attr_count_sr
    RuntimeAttr? runtime_attr_sr_genotype

    # RD train
    RuntimeAttr? runtime_attr_training_bed
    RuntimeAttr? runtime_attr_genotype_train
    RuntimeAttr? runtime_attr_generate_cutoff
    RuntimeAttr? runtime_attr_update_cutoff
    RuntimeAttr? runtime_attr_merge_genotypes

    # PESR part 2
    RuntimeAttr? runtime_attr_genotype_pe
    RuntimeAttr? runtime_attr_genotype_sr
    RuntimeAttr? runtime_attr_integrate_gq
    RuntimeAttr? runtime_attr_integrate_pesr_gq
    RuntimeAttr? runtime_attr_triple_stream_cat

    # Depth part 2
    RuntimeAttr? runtime_attr_integrate_depth_gq
    RuntimeAttr? runtime_attr_merge_regeno_cov_med

    RuntimeAttr? runtime_attr_update_batch_depth_vcf
    RuntimeAttr? runtime_attr_update_regeno_cov_med

  }

  Boolean single_sample_mode = defined(genotype_pesr_pesr_sepcutoff) && defined(genotype_pesr_depth_sepcutoff) && defined(genotype_depth_depth_sepcutoff) && defined(genotype_depth_pesr_sepcutoff) && defined(SR_metrics) && defined(PE_metrics)
  call tasksgenotypebatch.AddBatchSamples as AddBatchSamplesPESR {
    input:
      batch_vcf = batch_pesr_vcf,
      cohort_vcf = cohort_pesr_vcf,
      prefix = "${batch}.pesr",
      sv_pipeline_docker = sv_pipeline_docker,
      runtime_attr_override = runtime_attr_add_batch
  }

  call tasksgenotypebatch.AddBatchSamples as AddBatchSamplesDepth {
    input:
      batch_vcf = batch_depth_vcf,
      cohort_vcf = cohort_depth_vcf,
      prefix = "${batch}.depth",
      sv_pipeline_docker = sv_pipeline_docker,
      runtime_attr_override = runtime_attr_add_batch
  }

  call util.GetSampleIdsFromVcf {
    input:
      vcf = batch_pesr_vcf,
      sv_base_mini_docker = sv_base_mini_docker,
      runtime_attr_override = runtime_attr_ids_from_vcf
  }

  call util.SubsetPedFile {
    input:
      ped_file = ped_file,
      sample_list = GetSampleIdsFromVcf.out_file,
      subset_name = batch,
      sv_base_mini_docker = sv_base_mini_docker,
      runtime_attr_override = runtime_attr_subset_ped
  }

  if (!single_sample_mode) {
    call gp1.GenotypePESRPart1 as GenotypePESRPart1 {
      input:
        bin_exclude=bin_exclude,
        samples = GetSampleIdsFromVcf.out_array,
        pesr_exclude_list = select_first([pesr_exclude_list]),
        discfile = discfile,
        discfile_index = discfile_index,
        n_RD_genotype_bins = n_RD_genotype_bins,
        batch_vcf = batch_pesr_vcf,
        seed_cutoffs = select_first([seed_cutoffs]),
        medianfile = medianfile,
        batch = batch,
        rf_cutoffs = select_first([rf_cutoffs]),
        coveragefile = coveragefile,
        coveragefile_index = coveragefile_index,
        reference_build = select_first([reference_build]),
        n_per_PE_split = n_per_split,
        famfile = SubsetPedFile.ped_subset_file,
        splitfile = splitfile,
        splitfile_index = splitfile_index,
        n_per_RD_split = n_per_split,
        n_per_SR_split = n_per_split,
        ref_dict = ref_dict,
        sv_base_mini_docker = sv_base_mini_docker,
        sv_pipeline_docker = sv_pipeline_docker,
        sv_pipeline_rdtest_docker = sv_pipeline_rdtest_docker,
        runtime_attr_split_vcf = runtime_attr_split_vcf,
        runtime_attr_merge_counts = runtime_attr_merge_counts,
        runtime_attr_make_batch_bed = runtime_attr_make_batch_bed,
        runtime_attr_count_pe = runtime_attr_count_pe,
        runtime_attr_pe_genotype = runtime_attr_pe_genotype,
        runtime_attr_count_sr = runtime_attr_count_sr,
        runtime_attr_sr_genotype = runtime_attr_sr_genotype,
        runtime_attr_training_bed = runtime_attr_training_bed,
        runtime_attr_genotype_train = runtime_attr_genotype_train,
        runtime_attr_generate_cutoff = runtime_attr_generate_cutoff,
        runtime_attr_update_cutoff = runtime_attr_update_cutoff,
        runtime_attr_split_variants = runtime_attr_split_variants,
        runtime_attr_rdtest_genotype = runtime_attr_rdtest_genotype,
        runtime_attr_merge_genotypes = runtime_attr_merge_genotypes
    }
  }

  call gp2.GenotypePESRPart2 as GenotypePESRPart2 {
    input:
      bin_exclude=bin_exclude,
      samples = GetSampleIdsFromVcf.out_array,
      discfile = discfile,
      discfile_index = discfile_index,
      PE_metrics = select_first([PE_metrics, GenotypePESRPart1.PE_metrics]),
      n_RdTest_bins = n_RD_genotype_bins,
      medianfile = medianfile,
      cohort_vcf = AddBatchSamplesPESR.updated_vcf,
      batch = batch,
      RD_depth_sepcutoff = select_first([genotype_pesr_depth_sepcutoff, GenotypePESRPart1.RD_depth_sepcutoff]),
      RD_pesr_sepcutoff = select_first([genotype_pesr_pesr_sepcutoff, GenotypePESRPart1.RD_pesr_sepcutoff]),
      coveragefile = coveragefile,
      coveragefile_index = coveragefile_index,
      SR_metrics = select_first([SR_metrics, GenotypePESRPart1.SR_metrics]),
      n_per_split = n_per_split,
      famfile = SubsetPedFile.ped_subset_file,
      splitfile = splitfile,
      splitfile_index = splitfile_index,
      ref_dict = ref_dict,
      sv_base_mini_docker = sv_base_mini_docker,
      sv_pipeline_docker = sv_pipeline_docker,
      sv_pipeline_rdtest_docker = sv_pipeline_rdtest_docker,
      linux_docker = linux_docker,
      runtime_attr_split_variants = runtime_attr_split_variants,
      runtime_attr_make_subset_vcf = runtime_attr_make_subset_vcf,
      runtime_attr_count_pe = runtime_attr_count_pe,
      runtime_attr_genotype_pe = runtime_attr_genotype_pe,
      runtime_attr_count_sr = runtime_attr_count_sr,
      runtime_attr_genotype_sr = runtime_attr_genotype_sr,
      runtime_attr_rdtest_genotype = runtime_attr_rdtest_genotype,
      runtime_attr_integrate_gq = runtime_attr_integrate_gq,
      runtime_attr_integrate_pesr_gq = runtime_attr_integrate_pesr_gq,
      runtime_attr_add_genotypes = runtime_attr_add_genotypes,
      runtime_attr_triple_stream_cat = runtime_attr_triple_stream_cat,
      runtime_attr_concat_vcfs = runtime_attr_genotype_pesr_concat_vcfs
  }

  if (!single_sample_mode) {
    call gd1.GenotypeDepthPart1 as GenotypeDepthPart1 {
      input:
        bin_exclude=bin_exclude,
        samples = GetSampleIdsFromVcf.out_array,
        n_RD_genotype_bins = n_RD_genotype_bins,
        batch_vcf = batch_depth_vcf,
        seed_cutoffs = select_first([seed_cutoffs]),
        medianfile = medianfile,
        batch = batch,
        rf_cutoffs = select_first([rf_cutoffs]),
        coveragefile = coveragefile,
        coveragefile_index = coveragefile_index,
        reference_build = select_first([reference_build]),
        famfile = SubsetPedFile.ped_subset_file,
        n_per_RD_split = n_per_split,
        ref_dict = ref_dict,
        sv_base_mini_docker = sv_base_mini_docker,
        sv_pipeline_docker = sv_pipeline_docker,
        sv_pipeline_rdtest_docker = sv_pipeline_rdtest_docker,
        runtime_attr_training_bed = runtime_attr_training_bed,
        runtime_attr_genotype_train = runtime_attr_genotype_train,
        runtime_attr_generate_cutoff = runtime_attr_generate_cutoff,
        runtime_attr_update_cutoff = runtime_attr_update_cutoff,
        runtime_attr_split_variants = runtime_attr_split_variants,
        runtime_attr_rdtest_genotype = runtime_attr_rdtest_genotype,
        runtime_attr_merge_genotypes = runtime_attr_merge_genotypes
    }
  }
  call gd2.GenotypeDepthPart2 as GenotypeDepthPart2 {
    input:
      bin_exclude=bin_exclude,
      samples = GetSampleIdsFromVcf.out_array,
      n_RdTest_bins = n_RD_genotype_bins,
      medianfile = medianfile,
      cohort_vcf = AddBatchSamplesDepth.updated_vcf,
      batch = batch,
      RD_depth_sepcutoff = select_first([genotype_depth_depth_sepcutoff, GenotypeDepthPart1.RD_depth_sepcutoff]),
      RD_pesr_sepcutoff = select_first([genotype_depth_pesr_sepcutoff, GenotypeDepthPart1.RD_pesr_sepcutoff]),
      coveragefile = coveragefile,
      coveragefile_index = coveragefile_index,
      n_per_split = n_per_split,
      famfile = SubsetPedFile.ped_subset_file,
      ref_dict = ref_dict,
      sv_base_mini_docker = sv_base_mini_docker,
      sv_pipeline_docker = sv_pipeline_docker,
      sv_pipeline_rdtest_docker = sv_pipeline_rdtest_docker,
      runtime_attr_split_variants = runtime_attr_split_variants,
      runtime_attr_rdtest_genotype = runtime_attr_rdtest_genotype,
      runtime_attr_make_subset_vcf = runtime_attr_make_subset_vcf,
      runtime_attr_integrate_depth_gq = runtime_attr_integrate_depth_gq,
      runtime_attr_add_genotypes = runtime_attr_add_genotypes,
      runtime_attr_concat_vcfs = runtime_attr_genotype_depths_concat_vcfs,
      runtime_attr_merge_regeno_cov_med = runtime_attr_merge_regeno_cov_med
  }

  Boolean run_module_metrics_ = if defined(run_module_metrics) then select_first([run_module_metrics]) else true
  if (run_module_metrics_) {
    call metrics.GenotypeBatchMetrics {
      input:
        name = batch,
        samples = GetSampleIdsFromVcf.out_array,
        genotyped_pesr_vcf = GenotypePESRPart2.genotyped_vcf,
        genotyped_depth_vcf = GenotypeDepthPart2.genotyped_vcf,
        cutoffs_pesr_pesr = select_first([GenotypePESRPart1.RD_pesr_sepcutoff]),
        cutoffs_pesr_depth = select_first([GenotypePESRPart1.RD_depth_sepcutoff]),
        cutoffs_depth_pesr = select_first([GenotypeDepthPart1.RD_pesr_sepcutoff]),
        cutoffs_depth_depth = select_first([GenotypeDepthPart1.RD_depth_sepcutoff]),
        sr_bothside_pass = GenotypePESRPart2.bothside_pass,
        sr_background_fail = GenotypePESRPart2.background_fail,
        baseline_genotyped_pesr_vcf = baseline_genotyped_pesr_vcf,
        baseline_genotyped_depth_vcf = baseline_genotyped_depth_vcf,
        contig_list = select_first([primary_contigs_list]),
        linux_docker = linux_docker,
        sv_pipeline_base_docker = select_first([sv_pipeline_base_docker])
    }
  }

  call merge.UpdateChromosomeX as UpdateBatchDepthVcf {
    input:
      original_vcf = original_batch_depth_vcf,
      original_vcf_index = original_batch_depth_vcf_index,
      chrx_vcf = GenotypeDepthPart2.genotyped_vcf,
      prefix = batch + ".chrX_rerun.full.genotyped.depth",
      create_index = true,
      sv_pipeline_docker = sv_pipeline_docker,
      runtime_attr_override = runtime_attr_update_batch_depth_vcf
  }

  call UpdateRegenoCoverageMedians {
    input:
      original_regeno_coverage_medians = original_regeno_coverage_medians,
      chrx_regeno_coverage_medians = GenotypeDepthPart2.regeno_coverage_medians,
      batch = batch,
      sv_base_mini_docker = sv_base_mini_docker,
      runtime_attr_override = runtime_attr_update_regeno_cov_med
  }

  output {
    File sr_bothside_pass = GenotypePESRPart2.bothside_pass
    File sr_background_fail = GenotypePESRPart2.background_fail

    File? trained_PE_metrics = GenotypePESRPart1.PE_metrics
    File? trained_SR_metrics = GenotypePESRPart1.SR_metrics

    File? trained_genotype_pesr_pesr_sepcutoff = GenotypePESRPart1.RD_pesr_sepcutoff
    File? trained_genotype_pesr_depth_sepcutoff = GenotypePESRPart1.RD_depth_sepcutoff
    File? trained_genotype_depth_pesr_sepcutoff = GenotypeDepthPart1.RD_pesr_sepcutoff
    File? trained_genotype_depth_depth_sepcutoff = GenotypeDepthPart1.RD_depth_sepcutoff
    
    File genotyped_depth_vcf = GenotypeDepthPart2.genotyped_vcf
    File genotyped_depth_vcf_index = GenotypeDepthPart2.genotyped_vcf_index
    File genotyped_pesr_vcf = GenotypePESRPart2.genotyped_vcf
    File genotyped_pesr_vcf_index = GenotypePESRPart2.genotyped_vcf_index
    File regeno_coverage_medians = UpdateRegenoCoverageMedians.updated_regeno_coverage_medians

    File full_genotyped_depth_vcf = UpdateBatchDepthVcf.updated_vcf
    File full_genotyped_depth_vcf_index = UpdateBatchDepthVcf.updated_vcf_index
    
    File? metrics_file_genotypebatch = GenotypeBatchMetrics.metrics_file
  }
}


task UpdateRegenoCoverageMedians {
  input {
    File original_regeno_coverage_medians
    File chrx_regeno_coverage_medians
    String batch
    String sv_base_mini_docker
    RuntimeAttr? runtime_attr_override
  }

  RuntimeAttr default_attr = object {
    cpu_cores: 1,
    mem_gb: 3.75,
    disk_gb: 30,
    boot_disk_gb: 10,
    preemptible_tries: 3,
    max_retries: 1
  }
  RuntimeAttr runtime_attr = select_first([runtime_attr_override, default_attr])

  output {
    File updated_regeno_coverage_medians = "~{batch}.updated.regeno_coverage_medians.bed"
  }
  command <<<
    set -euxo pipefail
    grep -v ^chrX ~{original_regeno_coverage_medians} | grep -v ^chrY > before.bed
    grep ^chrY ~{original_regeno_coverage_medians} > after.bed
    cat before.bed ~{chrx_regeno_coverage_medians} after.bed > "~{batch}.updated.regeno_coverage_medians.bed"
  >>>
  runtime {
    cpu: select_first([runtime_attr.cpu_cores, default_attr.cpu_cores])
    memory: select_first([runtime_attr.mem_gb, default_attr.mem_gb]) + " GiB"
    disks: "local-disk " + select_first([runtime_attr.disk_gb, default_attr.disk_gb]) + " HDD"
    bootDiskSizeGb: select_first([runtime_attr.boot_disk_gb, default_attr.boot_disk_gb])
    docker: sv_base_mini_docker
    preemptible: select_first([runtime_attr.preemptible_tries, default_attr.preemptible_tries])
    maxRetries: select_first([runtime_attr.max_retries, default_attr.max_retries])
  }
}


