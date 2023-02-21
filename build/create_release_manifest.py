#!/usr/bin/python3
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import subprocess
import xml.etree.ElementTree as ET

def main():
  parser = argparse.ArgumentParser(description='Check out the revisions belonging to a release build.')
  parser.add_argument('-input', type=str, required=True)
  parser.add_argument('-output', type=str, required=True)
  args = parser.parse_args()

  tree = ET.parse(args.input)
  root = tree.getroot()
  for project in root.findall('project'):
    if project.get('remote'):
      print('We don\'t currently handle projects with non-default remotes: ', project.get('name'))
      continue
    path = project.get('path')
    git_output = subprocess.check_output(['git', '-C', path, 'rev-parse', 'HEAD'])
    revision = git_output.decode('utf-8').strip()
    project.set('revision', revision)

  tree.write(args.output)

if __name__ == '__main__':
  main()
