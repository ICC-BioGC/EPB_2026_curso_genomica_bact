#!/bin/bash

mkdir -p resultados/05_mob logs/05_mob

for sample in pc1 pc2 pc3 pc4
do
    mob_recon \
        --infile genomas_completos/spades/${sample}_scaffolds.fasta \
        --outdir resultados/05_mob/${sample} \
        --num_threads 4 \
        --run_overhang \
        > logs/05_mob/${sample}.log 2>&1 &

done

wait

echo "MOB-recon finalizado!"
