#!/bin/sh

cat <<'EOF' >README.rst
compatsphinxext
===============

See README.md
EOF

cat <<'EOF' >mylib.py
import networkx as nx
import pandas as pd


def create_meal_df(n: int = 5, country: str = "italy") -> pd.DataFrame:
    """
    Return a :class:`pandas.DataFrame` of ingredients and meals.

    Parameters
    ----------
    n : int
        Length of the data.
    country : str
        Home country of food.

    Returns
    -------
    pandas.DataFrame
    """
    ingredients = ['eggs', 'tomato', 'pasta', 'beef', 'bell pepper']
    meals = ['omelette', 'pasta salad', 'spaghetti bolognese', 'spaghetti bolognese', 'stir fry']
    data = {'Ingredient': ingredients, 'Meal': meals}
    return pd.DataFrame({'ingredient': ingredients, 'meal': meals})


def create_meal_g(n: int = 5, country: str = "italy") -> nx.DiGraph
    """
    Return a :class:`networkx.DiGraph` of ingredients and meals.

    Parameters
    ----------
    n : int
        Length of the data.
    country : str
        Home country of food.

    Returns
    -------
    networkx.DiGraph
    """
    df = create_meal_df()
    return nx.from_pandas_edgelist(df, source="ingredient", target="meal", create_using=nx.DiGraph)
EOF

mkdir -p docs/source
mkdir -p docs/source/_static
mkdir -p docs/source/_templates
mkdir -p docs/source/_ext

cat <<'EOF' >docs/source/conf.py
import os
import pathlib
import subprocess
import sys
sys.path.insert(0, pathlib.Path(__file__).parents[2].resolve().as_posix())
# sys.path.append(os.path.abspath("./_ext"))
print(f"{sys.path=}")
if "CONDA_DEFAULT_ENV" in os.environ or "conda" in sys.executable:
    print("conda environment:")
    subprocess.run([os.environ.get("CONDA_EXE", "conda"), "list"])
else:
    print("pip environment:")
    subprocess.run([sys.executable, "-m", "pip", "list"])
project = "compatsphinxext"
copyright = "2024, RAPIDS contrib"
author = "RAPIDS contrib"

extensions = [
    "numpydoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.githubpages",
    "sphinx.ext.intersphinx",
]

exclude_patterns = []
pygments_style = "sphinx"
html_theme = "pydata_sphinx_theme"
html_static_path = ["_static"]
templates_path = ["_templates"]

autosummary_generate = True

intersphinx_mapping = {
    "pandas": (
        "https://pandas.pydata.org/pandas-docs/stable/",
        "https://pandas.pydata.org/pandas-docs/stable/objects.inv",
    ),
    "python": (
        "https://docs.python.org/3",
        "https://docs.python.org/3/objects.inv",
    ),
    "networkx": (
        "https://networkx.org/documentation/stable/",
        "https://networkx.org/documentation/stable/objects.inv",
    ),
    "numpy": (
        "https://numpy.org/doc/stable",
        "https://numpy.org/doc/stable/objects.inv",
    ),
}
EOF

cat <<'EOF' >docs/source/api.rst
.. currentmodule:: compatsphinxext

.. _api:

#############
API reference
#############

Top-level functions
===================

.. autosummary::
   :toctree: generated/

   create_meal_df
   create_meal_g
EOF

cat <<'EOF' >docs/source/index.rst
Welcome to compatsphinxext's documentation!
===========================================

blah blah blah.

Check out the :doc:`usage` section for further information, including how to
:ref:`install <installation>` the project.

.. toctree::
   :maxdepth: 1
   :caption: Contents:

   Usasge <usage>
   API Reference <api>
EOF

cat <<'EOF' >docs/source/usage.rst
Usage
=====

.. _installation:

Installation
------------

blah blah blah.
EOF

cd docs

cat <<'EOF' >Makefile
SPHINXOPTS    ?=
SPHINXBUILD   ?= sphinx-build
SOURCEDIR     = source
BUILDDIR      = build

# Put it first so that "make" without argument is like "make help".
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

.PHONY: help Makefile

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: Makefile
	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
EOF

make html