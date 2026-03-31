#!/usr/bin/env python3
import sys
from pathlib import Path

BASE_DIR = Path('/Users/jyxc/.openclaw/workspace')
if str(BASE_DIR) not in sys.path:
    sys.path.insert(0, str(BASE_DIR))

from workbench_core.core import load_manifest, render_summary


if __name__ == '__main__':
    print(render_summary(load_manifest()))
