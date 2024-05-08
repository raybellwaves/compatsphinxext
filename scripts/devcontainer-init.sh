#!/bin/bash
set -euo pipefail

sudo apt-get update
sudo apt-get install make

pip install --user networkx numpydoc pandas pydata-sphinx-theme sphinx