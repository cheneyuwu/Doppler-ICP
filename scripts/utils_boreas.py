# MIT License
#
# Copyright (c) 2022 Aeva, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

"""Utilities library."""

import copy
import glob
import json
import os
import csv

import numpy as np
import open3d as o3d
import transformations as tf

from pathlib import Path


def get_inverse_tf(T):
  """Returns the inverse of a given 4x4 homogeneous transform.
    Args:
        T (np.ndarray): 4x4 transformation matrix
    Returns:
        np.ndarray: inv(T)
    """
  T2 = T.copy()
  T2[:3, :3] = T2[:3, :3].transpose()
  T2[:3, 3:] = -1 * T2[:3, :3] @ T2[:3, 3:]
  return T2


def get_time_from_filename(file):
    """Retrieves an epoch time from a file name in seconds"""
    tstr = str(Path(file).stem)
    gpstime = float(tstr)
    timeconvert = 1e-6
    if len(tstr) != 16 and len(tstr) > 10:
        timeconvert = 10**(-1 * (len(tstr) - 10))
    return gpstime * timeconvert


def load_calibration():
    """Returns T_V_to_S (T_sv)"""
    T_applanix_aeva = np.array(
        [[ 0.0, -1.0,  0.0, -0.390],
         [ 1.0,  0.0,  0.0,  0.369],
         [ 0.0,  0.0,  1.0, -0.103],
         [ 0.0,  0.0,  0.0,  1.0  ]]
    )

    T_applanix_vehicle = np.array(
        [[ 0.0, -1.0,  0.0,  0.0  ],
         [ 1.0,  0.0,  0.0, -0.531],
         [ 0.0,  0.0,  1.0,  0.0  ],
         [ 0.0,  0.0,  0.0,  1.0  ]]
    )

    T_aeva_vehicle = get_inverse_tf(T_applanix_aeva) @ T_applanix_vehicle

    return T_aeva_vehicle


def load_point_cloud(path):
    """Loads a pointcloud (np.ndarray) (N, 6) from path [x, y, z, intensity, radial_velocity, time]"""
    # dtype MUST be float32 to load this properly!
    data = np.fromfile(path, dtype=np.float32).reshape((-1, 6))

    pcd = o3d.geometry.PointCloud()
    pcd.points = o3d.utility.Vector3dVector(data[:, :3].astype('float64'))
    pcd.dopplers = o3d.utility.DoubleVector(data[:, 4].astype('float64'))
    return pcd

def generate_results(filename, poses, T_sv):
    assert os.path.isdir(os.path.dirname(filename)), 'Invalid output filename'

    results = []
    T_v0_v = np.eye(4)
    for T_vm1_v in poses:
        T_v0_v = T_v0_v @ T_vm1_v
        T_s0_s = T_sv @ T_v0_v @ np.linalg.inv(T_sv)
        T_s0_s_trunc = T_s0_s.flatten().tolist()[:12]
        results.append(T_s0_s_trunc)

    with open(filename, 'w') as f:
        writer = csv.writer(f, delimiter=' ')
        writer.writerows(results)