WORKING_DIR=${HOME}/ASRL/doppler_icp

################# setup #################
source ${WORKING_DIR}/venv/bin/activate
cd ${WORKING_DIR}/scripts


################# tests #################
## carla
DATASET_DIR=${HOME}/ASRL/data/doppler_icp_carla
RESULT_DIR=${HOME}/ASRL/temp/doppler_icp/doppler_icp_carla
SEQUENCE=carla-town05-curved-walls
python run.py --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}/${SEQUENCE}

## boreas(aeva)
DATASET_DIR=${HOME}/ASRL/data/boreas/sequences
RESULT_DIR=${HOME}/ASRL/temp/doppler_odometry/boreas/aeva/doppler_icp
# highway:     boreas-2022-05-13-09-23
# easy:        boreas-2022-05-13-10-30
# glen shield: boreas-2022-05-13-11-47
SEQUENCE=boreas-2022-05-13-11-47
python run_boreas.py --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}


################# evals #################
## for boreas dataset, use the eval scripts in ct_icp, e.g.,
cd ${HOME}/ASRL/ct_icp/ros2/ct_icp_slam/script
python generate_boreas_odometry_result.py --dataset ${DATASET_DIR} --path ${RESULT_DIR} --sensor aeva
python -m pyboreas.eval.odometry_aeva --gt ${DATASET_DIR} --pred ${RESULT_DIR}/boreas_odometry_result