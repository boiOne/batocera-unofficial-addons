#!/usr/bin/env python3
import os, sys, runpy

# Path to extracted/real UMU runtime
base = os.path.dirname(__file__)
main = os.path.join(base, "umu_run_extracted", "__main__.py")

# Fix argv so UMU behaves correctly
sys.argv[0] = main

# Run UMU patched main
runpy.run_path(main, run_name="__main__")
