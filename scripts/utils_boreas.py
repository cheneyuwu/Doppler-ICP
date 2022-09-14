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
import os.path as osp
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
    """Returns T_V_to_S (T_vs)"""
    T_applanix_aeva = np.array([
        [0.0, -1.0, 0.0, -0.390],
        [1.0, 0.0, 0.0, 0.369],
        [0.0, 0.0, 1.0, -0.103],
        [0.0, 0.0, 0.0, 1.0],
    ])

    T_applanix_vehicle = np.array([
        [0.0, -1.0, 0.0, 0.0],
        [1.0, 0.0, 0.0, -0.466],
        [0.0, 0.0, 1.0, 0.0],
        [0.0, 0.0, 0.0, 1.0],
    ])

    T_aeva_vehicle = get_inverse_tf(T_applanix_aeva) @ T_applanix_vehicle

    return get_inverse_tf(T_aeva_vehicle)


def load_velocity_calibration(path):
    rt_parts = np.loadtxt(osp.join(path, "rt_part.csv"), delimiter=",")
    azi_ranges = []
    for i in range(4):
        azi_ranges.append(np.loadtxt(osp.join(path, "azi_minmax_{}.csv".format(i)), delimiter=","))
    vel_means = []
    for i in range(4):
        vel_means.append(np.loadtxt(osp.join(path, "vel_mean_{}.csv".format(i)), delimiter=","))

    # flatten rt_parts
    for i in range(4):
        rt_parts[i, :] += i * 10.0
    rt_parts = rt_parts[:, :20].reshape(-1)
    azi_ranges = np.array(azi_ranges).reshape(rt_parts.shape[0], 2)
    vel_means = np.array(vel_means).reshape(rt_parts.shape[0], -1)
    vel_num_bins = vel_means.shape[-1]

    def _calibrate(pcd):
        """Calibrates a point cloud (np.ndarray) (N, 7) with the calibration parameters"""

        bs = pcd[:, 6].astype(np.int32)  # beam id

        max_time = np.max(pcd[:, 5])
        min_time = np.min(pcd[:, 5])
        rts = (pcd[:, 5] - min_time) / (max_time - min_time)  # relative time

        azis = np.arctan2(pcd[:, 1], pcd[:, 0])  # azimuth

        ps = np.clip(np.searchsorted(rt_parts, 10 * bs + rts) - 1, 0, rt_parts.shape[0] - 1)
        azi_ress = (azi_ranges[ps, 1] - azi_ranges[ps, 0]) / vel_num_bins
        bin_ids = np.floor((azis - azi_ranges[ps, 0]) / azi_ress)
        pcd[:, 4] -= vel_means[ps, np.clip(bin_ids, 0, vel_num_bins - 1).astype(np.int32)]

    return _calibrate


def load_point_cloud(path, calibrate=None):
    """Loads a pointcloud (np.ndarray) (N, 7) from path [x, y, z, intensity, radial_velocity, time, beam id]"""
    # dtype MUST be float32 to load this properly!
    data = np.fromfile(path, dtype=np.float32).reshape((-1, 7))
    # # limit range to 40m
    # data_range = np.linalg.norm(data[:, :3], axis=-1)
    # data = data[data_range < 40.0]

    if calibrate is not None:
        calibrate(data)

    pcd = o3d.geometry.PointCloud()
    pcd.points = o3d.utility.Vector3dVector(data[:, :3].astype('float64'))
    pcd.dopplers = o3d.utility.DoubleVector(data[:, 4].astype('float64'))
    return pcd


def generate_results(filename, poses, T_vs):
    assert os.path.isdir(os.path.dirname(filename)), 'Invalid output filename'

    results = []
    T_v0_v = np.eye(4)
    for T_vm1_v in poses:
        T_v0_v = T_v0_v @ T_vm1_v
        T_s0_s = get_inverse_tf(T_vs) @ T_v0_v @ T_vs
        T_s0_s_trunc = T_s0_s.flatten().tolist()[:12]
        results.append(T_s0_s_trunc)

    with open(filename, 'w') as f:
        writer = csv.writer(f, delimiter=' ')
        writer.writerows(results)
