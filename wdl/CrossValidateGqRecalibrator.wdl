version development

import "TrainGqRecalibrator.wdl" as TrainGqRecalibrator
import "RecalibrateGq.wdl" as RecalibrateGq
import "BenchmarkGqFilter.wdl" as BenchmarkGqFilter
import "PickleVcfProperties.wdl" as PickleVcfProperties

workflow CrossValidateGqRecalibrator {
    input {
        File train_vcf
        String train_vcf_label
        File? train_vcf_index
        Array[File] truth_vcfs
        Array[File]? truth_vcf_indices
        Map[String, File]? vapor_files
        File ped_file
        Array[File] genome_tracts
        File? optimal_overlap_cutoffs
        Boolean fix_vcf = true
        Int num_splits = 5
        String sv_utils_docker
        String gatk_docker
        String sv_base_mini_docker
        String sv_base_docker
        # optional arguments for overriding default tool behaviors
        Array[String] fix_vcf_args = []
        Array[String] train_args = []
        Array[String] recalibrate_gq_args = []
        Array[String] get_truth_overlap_args = []
        Array[String] benchmark_args = []
        Int new_pipeline_passing_score = 0
        String new_pipeline_score_property = "sl"
        Int old_pipeline_passing_score = 1
        String old_pipeline_score_property = "gq"
        # optional values that may be passed from previous runs to decrease runtime while iterating on a solution
        File? pickled_variant_properties
        File? pickled_original_scores
        Array[File]? cross_validation_train_vcfs
        Array[File]? cross_validation_test_vcfs
        Array[ScoresDataSet] comparison_scores = []
    }

    if(fix_vcf) {
        call TrainGqRecalibrator.FixVcf as FixVcf {
            input:
                vcf=train_vcf,
                fix_vcf_args=fix_vcf_args,
                sv_utils_docker=sv_utils_docker
        }
    }
    File train_vcf_ = select_first([FixVcf.fixed_vcf, train_vcf])
    File? train_vcf_index_ = if fix_vcf then FixVcf.fixed_vcf_index else train_vcf_index

     call TrainGqRecalibrator.TrainGqRecalibrator as TrainGqRecalibrator {
        input:
            train_vcf=train_vcf_,
            train_vcf_index=train_vcf_index_,
            truth_vcfs=truth_vcfs,
            truth_vcf_indices=truth_vcf_indices,
            vapor_files=vapor_files,
            ped_file=ped_file,
            genome_tracts=genome_tracts,
            optimal_overlap_cutoffs=optimal_overlap_cutoffs,
            fix_vcf=false,
            train_args=train_args,
            get_truth_overlap_args=get_truth_overlap_args,
            sv_utils_docker=sv_utils_docker,
            gatk_docker=gatk_docker,
            sv_base_docker=sv_base_docker
    }

    call RecalibrateGq.RecalibrateGq as DirectGqRecalibrator {
        input:
            vcf=train_vcf_,
            vcf_index=train_vcf_index_,
            genome_tracts=genome_tracts,
            gq_recalibrator_model_file=TrainGqRecalibrator.output_gq_recalibrator_model_file,
            fix_vcf=false,
            gatk_docker=gatk_docker,
            sv_utils_docker=sv_utils_docker,
            sv_base_docker=sv_base_docker
    }

    if(!defined(cross_validation_train_vcfs) || !defined(cross_validation_test_vcfs)) {
        call MakeCrossValidationVcfs {
            input:
                vcf=train_vcf_,
                ped_file=ped_file,
                truth_vcfs=truth_vcfs,
                vapor_samples=if defined(vapor_files) then keys(select_first([vapor_files])) else [],
                num_splits=num_splits,
                sv_utils_docker=sv_utils_docker
        }
    }
    Array[File] cross_validation_train_vcfs_ = select_first([MakeCrossValidationVcfs.train_vcfs,
                                                             cross_validation_train_vcfs])
    Array[File] cross_validation_test_vcfs_ = select_first([MakeCrossValidationVcfs.test_vcfs,
                                                            cross_validation_test_vcfs])

    scatter(train_test_pair in zip(cross_validation_train_vcfs_, cross_validation_test_vcfs_)) {
        call TrainGqRecalibrator.TrainGqRecalibrator as CrossTrainGqRecalibrator {
            input:
                train_vcf=train_test_pair.left,
                truth_vcfs=truth_vcfs,
                truth_vcf_indices=truth_vcf_indices,
                vapor_files=vapor_files,
                ped_file=ped_file,
                genome_tracts=genome_tracts,
                optimal_overlap_cutoffs=optimal_overlap_cutoffs,
                fix_vcf=false,
                train_args=train_args,
                get_truth_overlap_args=get_truth_overlap_args,
                sv_utils_docker=sv_utils_docker,
                gatk_docker=gatk_docker,
                sv_base_docker=sv_base_docker
        }

        call RecalibrateGq.RecalibrateGq as CrossGqRecalibrator {
            input:
                vcf=train_test_pair.right,
                genome_tracts=genome_tracts,
                gq_recalibrator_model_file=CrossTrainGqRecalibrator.output_gq_recalibrator_model_file,
                fix_vcf=false,
                gatk_docker=gatk_docker,
                sv_utils_docker=sv_utils_docker,
                sv_base_docker=sv_base_docker
        }
    }

    call MergeRecalibratedTestVcfs {
        input:
            filtered_vcfs=CrossGqRecalibrator.filtered_vcf,
            filtered_vcf_indices=CrossGqRecalibrator.filtered_vcf_index,
            merged_name=sub(sub(basename(train_vcf), ".gz$", ""), ".vcf$", "_cross_validated.vcf.gz"),
            sv_base_mini_docker=sv_base_mini_docker
    }

    # cromwell doesn't launch tasks until an entire workflow is ready, so can speed up wall-clock time by getting
    # variant properties and original scores as soon as train_vcf_ is resolved
    if(!defined(pickled_variant_properties)) {
        call PickleVcfProperties.PickleVcfProperties as PickleVariantData {
            input:
                vcf=train_vcf_,
                vcf_index=train_vcf_index_,
                wanted_properties=["svtype", "svlen", "gt"],
                sv_base_docker=sv_base_docker,
                sv_utils_docker=sv_utils_docker
        }
    }
    File pickled_variant_properties_ = select_first([pickled_variant_properties, PickleVariantData.pickled_properties])

    if(!defined(pickled_original_scores)) {
        call PickleVcfProperties.PickleVcfProperties as PickleTrainScores {
            input:
                vcf=train_vcf_,
                vcf_index=train_vcf_index_,
                wanted_properties=[old_pipeline_score_property],
                sv_base_docker=sv_base_docker,
                sv_utils_docker=sv_utils_docker
        }
    }
    File pickled_original_scores_ = select_first([pickled_original_scores, PickleTrainScores.pickled_properties])

    ScoresDataSet original_scores = {
        "label": "original",
        "vcf": train_vcf_,
        "vcf_index": train_vcf_index_,
        "pickled_scores_file": pickled_original_scores_,
        "property": old_pipeline_score_property,
        "passing_score": old_pipeline_passing_score
    }
    Array[ScoresDataSet] comparison_scores_ = flatten(
        [
            [
                {
                    "label": "recalibrated",
                    "vcf": DirectGqRecalibrator.filtered_vcf,
                    "vcf_index": DirectGqRecalibrator.filtered_vcf_index,
                    "property": new_pipeline_score_property,
                    "passing_score": new_pipeline_passing_score
                },
                {
                    "label": "cross-validated",
                    "vcf": MergeRecalibratedTestVcfs.merged_vcf,
                    "vcf_index": MergeRecalibratedTestVcfs.merged_vcf_index,
                    "property": new_pipeline_score_property,
                    "passing_score": new_pipeline_passing_score
                }
            ],
            comparison_scores
        ]
    )

    # actually call BenchmarkFilter workflow
    call BenchmarkGqFilter.BenchmarkGqFilter as BenchmarkGqFilter {
        input:
            data_label=train_vcf_label,
            original_scores=original_scores,
            pickled_variant_properties=pickled_variant_properties_,
            comparison_scores=comparison_scores_,
            truth_overlap_info=TrainGqRecalibrator.truth_overlap_info,
            ped_file=ped_file,
            benchmark_args=benchmark_args,
            sv_utils_docker=sv_utils_docker,
            sv_base_docker=sv_base_docker,
    }

    output {
        File clean_vcf = TrainGqRecalibrator.clean_vcf
        File clean_vcf_index = TrainGqRecalibrator.clean_vcf_index
        File truth_overlap_info = TrainGqRecalibrator.truth_overlap_info
        File output_optimal_overlap_cutoffs = TrainGqRecalibrator.output_optimal_overlap_cutoffs
        File output_gq_recalibrator_model_file = TrainGqRecalibrator.output_gq_recalibrator_model_file
        File filtered_vcf = DirectGqRecalibrator.filtered_vcf
        File filtered_vcf_index = DirectGqRecalibrator.filtered_vcf_index
        File cross_validated_filtered_vcf = MergeRecalibratedTestVcfs.merged_vcf
        File cross_validated_filtered_vcf_index = MergeRecalibratedTestVcfs.merged_vcf_index
        File benchmark_figure = BenchmarkGqFilter.benchmark_figure
        File variant_properties = BenchmarkGqFilter.variant_properties
        File original_scores = BenchmarkGqFilter.pickled_original_scores
        Array[File] pickled_comparison_scores=BenchmarkGqFilter.pickled_comparison_scores
        Array[File] cross_train_vcfs = cross_validation_train_vcfs_
        Array[File] cross_test_vcfs = cross_validation_test_vcfs_
    }
}


task MakeCrossValidationVcfs {
    input {
        File vcf
        File ped_file
        Array[File] truth_vcfs
        Array[String] vapor_samples
        Int num_splits = 5
        String sv_utils_docker
    }

    String fixed_vcf_name = sub(sub(basename(vcf), ".gz$", ""), ".vcf$", "_fixed.vcf.gz")
    String index_file_name = fixed_vcf_name + ".tbi"

    Int disk_gb = 1000 + round((1 + num_splits) * size(vcf, "GiB") + size(truth_vcfs, "GiB") + size(ped_file, "GiB"))
    Float mem_gb = 2.0

    runtime {
        docker: sv_utils_docker
        cpu: 1
        preemptible: 3
        max_retries: 0
        memory: mem_gb + " GiB"
        disks: "local-disk " + disk_gb + " HDD"
    }

    command <<<
        set -eu -o pipefail

        # create TRUTH_SAMPLES_FILE, with one sample ID per line that has VaPoR/PacBio data (duplicates are okay)
        # The cross-validated VCFs will attempt to distribute these truth samples evenly across batches
        TRUTH_SAMPLES_FILE=~{write_lines(vapor_samples)}
        cat ~{write_lines(truth_vcfs)} | while read TRUTH_VCF; do
            zgrep -m1 ^#[^#] "$TRUTH_VCF" | cut -f10- | tr '\t' '\n'
        done >> "$TRUTH_SAMPLES_FILE"

        sv_utils make_cross_validation_vcfs ~{vcf} \
            --ped-file ~{ped_file} \
            --truth-samples-file "$TRUTH_SAMPLES_FILE" \
            --num_splits ~{num_splits}
    >>>

    output {
        Array[File] train_vcfs = glob("train_*.vcf.gz")
        Array[File] test_vcfs = glob("test_*.vcf.gz")
    }
}


task MergeRecalibratedTestVcfs {
    input {
        Array[File] filtered_vcfs
        Array[File] filtered_vcf_indices
        String merged_name
        String sv_base_mini_docker
    }

    Int disk_gb = 1000 + 2 * round(size(filtered_vcfs, "GiB") + size(filtered_vcf_indices, "GiB"))
    Float mem_gb = 4.0
    String merged_index = merged_name + ".tbi"

    runtime {
        docker: sv_base_mini_docker
        cpu: 1
        preemptible: 3
        max_retries: 0
        memory: mem_gb + " GiB"
        disks: "local-disk " + disk_gb + " HDD"
    }

    command <<<
        set -eu -o pipefail

        bcftools merge --threads $(nproc) -m both -O z -o ~{merged_name} ~{sep=" " filtered_vcfs}

        bcftools index --tbi -o ~{merged_index} ~{merged_name}
    >>>

    output {
        File merged_vcf = merged_name
        File merged_vcf_index = merged_index
    }
}