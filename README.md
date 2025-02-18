# RGB-Event ISP: MATLAB Implementation

## Overview of ISP
This repository contains the MATLAB implementation of the **RGB-Event ISP** pipeline, which processes RAW images into color-corrected RGB images. The codebase is developed as part of the **RGB-Event ISP Dataset and Benchmark**, which introduces the first event-RAW paired dataset for event-based image signal processing (ISP). The dataset and associated methods were presented in our ICLR 2025 paper.

## Features
- **RAW Image Processing**: Converts APS RAW images into RGB images using a predefined ISP pipeline.
- **Controllable ISP Pipeline**: Implements black level correction, demosaicing, white balancing, denoising, and color correction.
- **MATLAB-Based Processing**: Provides a structured and modular ISP framework for MATLAB users.
- **Dataset and Evaluation**: Supports the new RGB-Event ISP dataset with diverse scenes, lighting conditions, and event-RAW alignment.

**Note**: The ISP process described in our paper uses a ColorChecker as a prior for color correction and does not incorporate event data for RAW to RGB conversion.

## Repository Structure
```
├── BM3D-master                          # BM3D denoising implementation
├── color-checker-extraction-master       # Color checker extraction module
├── color-checker-location-master         # Color checker localization module
├── color-correction-toolbox-master       # Color correction utilities
├── Quad_Bayer_CFA_Modified_...          # Demosaicing module
├── npy-matlab-master                     # NPY file support for MATLAB
├── extract_error_in_log                  # Log analysis scripts
├── testdata-rawdata                      # Sample test data (RAW images and events)
├── apply_cmatrix.m                        # Apply color matrix transformation
├── cfa_pattern.m                          # CFA pattern handling
├── DEMO.m                                 # Main demonstration script
├── DEMO_EVENT.m                           # Demonstration with event integration
├── DEMO_EVENT_LABELME.m                   # LabelMe-based demonstration
├── DngToJpg.m                             # Convert RAW DNG images to JPG
├── DngToPng.m                             # Convert RAW DNG images to PNG
├── get_color_card_coords_from_json.m      # Extract color checker coordinates from JSON
├── Load_Data_and_Metadata_from_DNG.m      # Load RAW data and metadata from DNG files
├── Main.m                                 # Main processing pipeline
├── README.md                              # Documentation (this file)
├── RGBE_ISP.m                             # Core MATLAB function for ISP
├── TASK_VIDEO_FOLDER_RGBE_ISP.m           # Batch processing script
├── TASK_VIDEO_FOLDER_RGBE_ISP_LIMITED_BBOX.m  # Processing script with bounding box constraints
├── tone_curve.mat                         # Predefined tone curve for color correction
├── wbmask.m                               # White balance mask
├── demo.sh                                # Example batch job script for HPC
```

## Installation and Setup
1. Install **MATLAB (R2022a or later)** with Image Processing and Signal Processing toolboxes.
2. Clone the repository:
   ```sh
   git clone https://github.com/yunfanLu/RGB-Event-ISP.git
   cd RGB-Event-ISP
   ```
3. Add the repository to your MATLAB path:
   ```matlab
   addpath(genpath('RGB-Event-ISP'));
   ```
4. Ensure the necessary dependencies (BM3D, color correction toolbox) are included in the MATLAB path.

### Processing Frames
To process an entire folder of RAW data:
```matlab
TASK_VIDEO_FOLDER_RGBE_ISP('dataset/Event-Video-Color-Dataset', 20, 0.45, 1, false);
```

### Citation
If you use this code or dataset in your research, please cite our ICLR 2025 paper:
```bibtex
@inproceedings{lu2025rgb,
  title={RGB-Event ISP: The Dataset and Benchmark},
  author={Yunfan Lu and Yanlin Qian and Ziyang Rao and Junren Xiao and Liming Chen and Hui Xiong},
  booktitle={International Conference on Learning Representations (ICLR)},
  year={2025}
}
```

### License
This project is released under the Academic Research License. It is strictly for non-commercial, research purposes only. Any commercial usage, redistribution, or modification for profit-oriented activities is strictly prohibited.

We welcome researchers and students in the event-version community to use our dataset. Please send me an email using the school email and state the purpose of non-commercial use. I will reply to you within 24 hours!

### Contact
For any questions or inquiries, please contact **Yunfan Lu** at [ylu066@connect.hkust-gz.edu.cn](mailto:ylu066@connect.hkust-gz.edu.cn).

