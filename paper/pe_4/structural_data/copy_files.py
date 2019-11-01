#! /usr/bin/env python
#
# Copyright (c) 2016 Jakub Krajniak <jkrajniak@gmail.com>
#
# Distributed under terms of the GNU GPLv3 license.
# 

import os
import shutil
import sys

input_dir = sys.argv[1]
pattern = sys.argv[2]
prefix = sys.argv[3]

print('{} <input_dir> <pattern> <prefix>'.format(sys.argv[0]))

file_idx = 0
for f in os.listdir(input_dir):
    if pattern in f:
        src_file = os.path.join(input_dir, f)
        output_file = '{}_{}_{}'.format(prefix, file_idx, f)
        print('Copy {} -> {}'.format(src_file, output_file))
        shutil.copyfile(src_file, output_file)
        file_idx += 1
