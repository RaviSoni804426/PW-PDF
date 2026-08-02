#!/usr/bin/env python

import sys
sys.path.append('../..')
import base
import os

def make():
  print("[fetch & build]: harfbuzz")
  # PW PDF: invoke through the interpreter — running "./make.py" relies on the
  # .py file association, and on a machine where .py opens in an editor the
  # build blocks forever waiting for that editor to close.
  base.cmd_in_dir(base.get_script_dir() + "/../../core/Common/3dParty/harfbuzz", "python", ["./make.py"])
  return

if __name__ == '__main__':
  # manual compile
  make()
