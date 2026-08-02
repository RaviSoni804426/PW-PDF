#!/usr/bin/env python

import sys
sys.path.append('../..')
import base
import os

def make():
  print("[fetch & build]: brotli")
  # PW PDF: invoke through the interpreter (see harfbuzz.py) — a bare "./make.py"
  # depends on the .py file association and can hang the build.
  base.cmd_in_dir(base.get_script_dir() + "/../../core/Common/3dParty/brotli", "python", ["./make.py"])
  return

if __name__ == '__main__':
  # manual compile
  make()
