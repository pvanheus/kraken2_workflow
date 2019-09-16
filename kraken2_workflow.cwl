#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement
  - class: SchemaDefRequirement
    types:
      - $import: paired_end_record.yml

inputs:
    sample_dir: Directory
    database: Directory
    paired_reads: paired_end_record.yml#paired_end_options
outputs:
    fastq_files: 
        type: 
            type: array
            items: 
                type: array
                items: File
        outputSource: [gather_files/fastq_files]

steps:
    gather_files:
        run: fastq_files_from_directory.cwl
        in:
            dir: sample_dir
            paired_reads: paired_reads
        out: 
          - fastq_files
          - sample_names
    kraken2:
        run: kraken2.cwl
        scatter: 
          - input_sequences
          - output
        scatterMethod: dotproduct
        in:
            database: database
            input_sequences: gather_files/fastq_files
            output: gather_files/sample_names
        out: [kraken_output]
    