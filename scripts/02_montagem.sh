#!/bin/bash

mkdir -p resultados/02_spades
mkdir -p logs/02_spades

for sample in pc1 pc2 pc3 pc4
do
    spades.py \
        --isolate \
        -1 fastp_output/${sample}_R1.clean.fastq.gz \
        -2 fastp_output/${sample}_R2.clean.fastq.gz \
        -o resultados/02_spades/${sample} \
        -t 4 \
        -m 8 \
        > logs/02_spades/${sample}.log 2>&1 &

done

wait

echo "Montagens finalizadas!"
