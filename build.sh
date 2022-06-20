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
  -v ${HOME}/ASRL/data/boreas/sequences:${HOME}/ASRL/data/BOREAS \
  -v /media/yuchen/T7/ASRL/data/doppler_icp_carla:${HOME}/ASRL/data/doppler_icp_carla \
  doppler_icp

## create virtualenv and upgrade pip
cd ~/ASRL/Doppler-ICP
virtualenv venv
source venv/bin/activate
pip install --upgrade pip  # must update pip

## install open3d
cd ~/ASRL/Doppler-ICP/Open3D
mcd build
cmake -DPython3_ROOT=/ext0/ASRL/Doppler-ICP/venv/bin/python \
      -DCMAKE_INSTALL_PREFIX=/home/yuchen/ASRL/Doppler-ICP/Open3D/install ..
make -j$(nproc)
make install
make install-pip-package

## doppler icp python deps
pip install -r requirements.txt  # version required??