#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

requirements:
  - class: ScatterFeatureRequirement
  - class: SchemaDefRequirement
    types:
      - $import: fastq_from_directory_types.yml

inputs:
    sample_dir: Directory
    database: Directory
    paired_reads: fastq_from_directory_types.yml#paired_end_options
    compressed_files: 
        - "null"
        - fastq_from_directory_types.yml#gzip_compressed
        - fastq_from_directory_types.yml#bzip2_compressed
        
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
    