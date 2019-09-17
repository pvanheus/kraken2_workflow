#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: ExpressionTool
id: fastq_files_from_directory

requirements:
  - class: InlineJavascriptRequirement
  - class: SchemaDefRequirement
    types:
      - $import: fastq_from_directory_types.yml
      - $import: compression_options.yml
inputs:
  dir:
    type: Directory
    streamable: true
    label: "Directory containing FASTQ files"
  fastq_suffix:
    type: string?
    label: "Filename suffice for FASTQ files"
    default: 'fastq'
  paired_reads:
    type:
      - "null"
      - fastq_from_directory_types.yml#paired_end_options
  compression_options:
    type: 
      - "null"
      - fastq_from_directory_types.yml#gzip_compressed
      - fastq_from_directory_types.yml#bzip2_compressed

outputs:
  sample_names:
    type: string[]
  fastq_files:
    type:
      type: array
      items: 
        type: array
        items: File

expression: |
        ${
          var is_gzip = inputs.compressed_files ? inputs.compressed_files.gzip_compressed : false;
          var is_bzip2 = inputs.compressed_files ? inputs.compressed_filesls.bzip2_compressed : false;
          var do_paired = inputs.paired_reads && inputs.paired_reads.paired;
          var paired_end_designator = '';
          if (inputs.paired_reads && inputs.paired_reads.paired) {
            if (inputs.paired_reads.paired_end_designator) {
              paired_end_designator = inputs.paired_reads.paired_end_designator;
            } else {
              paired_end_designator = '_[12]';
            }
          }

          var suffix = paired_end_designator + '.' + inputs.fastq_suffix + (is_gzip ? '.gz' : (is_bzip2 ? '.bz2' : ''));
          var suffixRe = new RegExp(suffix + '$');
          var samples_seen = {};
          console.log("GOT HERE: " + suffix);
          inputs.dir.listing.forEach(function (file) { 
            if (file.basename) {
              console.log("SAW BASENAME: " + file.basename);
              if (suffixRe.test(file.basename)) {
                file.format = 'edam:format_1930';
                console.log("MATCHED: " + file.basename);
                var sample_name = file.basename.replace(suffixRe, ''); 
                if (sample_name in samples_seen) {
                  samples_seen[sample_name].push(file);
                } else {
                  samples_seen[sample_name] = [file];
                }
              }
            }
          });
          var fastq_files = Object.keys(samples_seen).map(function (sample_name) {
            return samples_seen[sample_name].sort(function (a, b) { return (a.basename > b.basename) ? 1 : -1 });
          });
          return { 
            'sample_names': Object.keys(samples_seen),
            'fastq_files': fastq_files
          };
        }

$namespaces:
  edam: http://edamontology.org/