WORKING_DIR=${HOME}/ASRL/doppler_icp

################# setup #################
source ${WORKING_DIR}/venv/bin/activate
cd ${WORKING_DIR}/scripts

################# tests #################
## carla (no motion distortion)
DATASET_DIR=${HOME}/ASRL/data/doppler_icp_carla
RESULT_DIR=${HOME}/ASRL/temp/doppler_icp/dicp_corrected
# carla-town04-straight-walls
# carla-town05-curved-walls
# bunker-road
# bunker-road-vehicles
# robin-williams-tunnel
SEQUENCE=bunker-road
python run.py -s 1 --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}

## dicp datasets (has motion distortion)
DATASET_DIR=${HOME}/ASRL/data/dicp
RESULT_DIR=${HOME}/ASRL/temp/doppler_odometry/dicp/doppler_icp
# SEQUENCE=brisbane-lagoon-freeway
# SEQUENCE=bunker-road
# SEQUENCE=bunker-road-vehicles
SEQUENCE=robin-williams-tunnel
# SEQUENCE=san-francisco-city
python run.py -r 1 --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}

## boreas(aeva)
DATASET_DIR=${HOME}/ASRL/data/boreas/sequences
RESULT_DIR=${HOME}/ASRL/temp/doppler_odometry/boreas/aeva/doppler_icp
# SEQUENCE=boreas-2022-07-19-16-06 # utias
# SEQUENCE=boreas-2022-08-05-12-59 # h7
# SEQUENCE=boreas-2022-08-05-13-30 # h404
# SEQUENCE=boreas-2022-08-05-13-54 # dvp
SEQUENCE=boreas-2022-08-05-15-01 # h427
python run_boreas.py --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}

################# evals #################
## for boreas dataset, use the eval scripts in ct_icp, e.g.,
cd ${HOME}/ASRL/ct_icp/ros2/ct_icp_slam/script
python generate_boreas_odometry_result.py --dataset ${DATASET_DIR} --path ${RESULT_DIR} --sensor aeva
python -m pyboreas.eval.odometry_aeva --gt ${DATASET_DIR} --pred ${RESULT_DIR}/boreas_odometry_result
