## enter virtualenv
cd ~/ASRL/Doppler-ICP
source venv/bin/activate
cd ~/ASRL/Doppler-ICP/scripts

################# carla #################
DATASET_DIR=/home/yuchen/ASRL/data/doppler_icp_carla
RESULT_DIR=/home/yuchen/ASRL/temp/doppler_icp/doppler_icp_carla
SEQUENCE=carla-town05-curved-walls
python run.py --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}/${SEQUENCE}


################# boreas(aeva) #################
DATASET_DIR=/home/yuchen/ASRL/data/BOREAS
RESULT_DIR=/home/yuchen/ASRL/temp/doppler_odometry/boreas/aeva/doppler_icp
SEQUENCE=boreas-2022-05-13-10-30
python run_boreas.py --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}

# this needs to be run outside the docker with the same result dir, sequence not needed
DATASET_DIR=/home/yuchen/ASRL/data/boreas/sequences
source /home/yuchen/ASRL/venv/bin/activate
cd /home/yuchen/ASRL/ct_icp/ros2/ct_icp_slam/script
python generate_boreas_odometry_result.py --dataset ${DATASET_DIR} --path ${RESULT_DIR} --sensor aeva
python -m pyboreas.eval.odometry_aeva --gt ${DATASET_DIR} --pred ${RESULT_DIR}/boreas_odometry_result