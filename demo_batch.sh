make vivado ARGS="-prfLogP 1 -prfLogQ 1 -useUram" PROJECT_NAME=demo_4_lanes_5MB
make vivado ARGS="-prfLogP 1 -prfLogQ 1 -useUram -hbm" PROJECT_NAME=demo_4_lanes_HBM

make vivado ARGS="-prfLogP 1 -prfLogQ 2 -useUram" PROJECT_NAME=demo_8_lanes_5MB
make vivado ARGS="-prfLogP 1 -prfLogQ 2 -useUram -hbm" PROJECT_NAME=demo_8_lanes_HBM

make vivado ARGS="-prfLogP 2 -prfLogQ 2 -useUram" PROJECT_NAME=demo_16_lanes_5MB
make vivado ARGS="-prfLogP 2 -prfLogQ 2 -useUram -hbm" PROJECT_NAME=demo_16_lanes_HBM

make vivado ARGS="-prfLogP 2 -prfLogQ 3 -useUram" PROJECT_NAME=demo_32_lanes_5MB
make vivado ARGS="-prfLogP 2 -prfLogQ 3 -useUram -hbm" PROJECT_NAME=demo_32_lanes_HBM
