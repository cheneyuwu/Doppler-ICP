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
python run.py -s 1 --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}/${SEQUENCE}

## dicp datasets (has motion distortion)
DATASET_DIR=${HOME}/ASRL/data/aeva
RESULT_DIR=${HOME}/ASRL/temp/doppler_odometry/dicp
# brisbane-lagoon-freeway
# bunker-road
# bunker-road-vehicles
# robin-williams-tunnel
# san-francisco-city
SEQUENCE=san-francisco-city
python run.py -r 1 --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}/${SEQUENCE}

## boreas(aeva)
DATASET_DIR=${HOME}/ASRL/data/boreas/sequences
RESULT_DIR=${HOME}/ASRL/temp/doppler_odometry/boreas/aeva/doppler_icp
# highway 7:    boreas-2022-05-13-09-23
# marc santi:   boreas-2022-05-13-10-30
# glen shields: boreas-2022-05-13-11-47
# cocksfield:   boreas-2022-05-18-17-23
SEQUENCE=boreas-2022-05-13-10-30
python run_boreas.py --sequence ${DATASET_DIR}/${SEQUENCE} -o ${RESULT_DIR}

################# evals #################
## for boreas dataset, use the eval scripts in ct_icp, e.g.,
cd ${HOME}/ASRL/ct_icp/ros2/ct_icp_slam/script
python generate_boreas_odometry_result.py --dataset ${DATASET_DIR} --path ${RESULT_DIR} --sensor aeva
python -m pyboreas.eval.odometry_aeva --gt ${DATASET_DIR} --pred ${RESULT_DIR}/boreas_odometry_result
