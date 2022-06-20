## enter virtualenv
cd ~/ASRL/Doppler-ICP
source venv/bin/activate
cd ~/ASRL/Doppler-ICP/scripts

################# carla #################
DATASET_DIR=/home/yuchen/ASRL/data/doppler_icp_carla
RESULT_DIR=/home/yuchen/ASRL/temp/doppler_icp/doppler_icp_carla
SEQUENCE=carla-town05-curved-walls
python run.py --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}/${SEQUENCE}

