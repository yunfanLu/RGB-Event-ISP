#!/bin/bash
#SBATCH -p i64m512u
#SBATCH -J 20240424145150540
#SBATCH --ntasks-per-node=1
#SBATCH -n 1
#SBATCH -o log/job.%j.out
#SBATCH -e log/job.%j.err

module load matlab

root="./dataset/Event-Video-Color-Dataset/20240421/20240421162310787/APS/quadbayer_bit8_3264_2448_20240421162310787/"

matlab -nodisplay -nosplash -nodesktop -r "TASK_VIDEO_FOLDER_RGBE_ISP_LIMITED_BBOX('$root',20, 0.45, 1, false); exit;"

echo "Job finished at: `date`"