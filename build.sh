WORKING_DIR=${HOME}/ASRL/doppler_icp

## build docker image
docker build -t doppler_icp \
  --build-arg USERID=$(id -u) \
  --build-arg GROUPID=$(id -g) \
  --build-arg USERNAME=$(whoami) \
  --build-arg HOMEDIR=${HOME} .

## run docker image (example)
docker run -it --name doppler_icp \
  --privileged \
  --network=host \
  --gpus all \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v ${HOME}:${HOME}:rw \
  -v ${HOME}/ASRL:${HOME}/ASRL:rw \
  -v ${HOME}/ASRL/data/boreas:${HOME}/ASRL/data/boreas \
  -v /media/yuchen/T7/ASRL/data/doppler_icp_carla:${HOME}/ASRL/data/doppler_icp_carla \
  doppler_icp

## create virtualenv and upgrade pip
cd ${WORKING_DIR}
virtualenv venv
source venv/bin/activate
pip install --upgrade pip  # must update pip

## install open3d
cd ${WORKING_DIR}/Open3D
mcd build
cmake -DPython3_ROOT=${WORKING_DIR}/venv/bin/python \
      -DCMAKE_INSTALL_PREFIX=${WORKING_DIR}/Open3D/install ..
make -j$(nproc)
make install
make install-pip-package

## doppler icp python deps
cd ${WORKING_DIR}
pip install -r requirements.txt