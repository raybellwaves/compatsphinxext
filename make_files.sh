#!/bin/sh

cat <<'EOF' >README.rst
compatsphinxext
===============

blah blah blah
EOF

cat <<'EOF' >compatsphinxext.py
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
    return pd.DataFrame({'ingredient': ingredients, 'meal': meals})


def create_meal_g(n: int = 5, country: str = "italy") -> nx.DiGraph:
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
    ingredients = ['eggs', 'tomato', 'pasta', 'beef', 'bell pepper']
    meals = ['omelette', 'pasta salad', 'spaghetti bolognese', 'spaghetti bolognese', 'stir fry']
    df = pd.DataFrame({'ingredient': ingredients, 'meal': meals})
    return nx.from_pandas_edgelist(df, source="ingredient", target="meal", create_using=nx.DiGraph)


def reindex(df: pd.DataFrame) -> pd.DataFrame:
    """
    Use :func:`pandas.DataFrame.reindex` and drop the first row of the
    :class:`pandas.DataFrame`.

    Parameters
    ----------
    df : pandas.DataFrame
        Pandas DataFrame.

    Returns
    -------
    pandas.DataFrame


    .. pandas-compat::
        **DataFrame.reindex**

        This is the current RAPIDS sphinx ext.
    """
    return df.reindex(range(1, len(df)))
EOF

mkdir -p docs/source
mkdir -p docs/source/_static
mkdir -p docs/source/_templates
mkdir -p docs/source/_ext

# current cudf pandas compat sphinx extension
# https://github.com/rapidsai/cudf/blob/branch-24.06/docs/cudf/source/_ext/PandasCompat.py
cat <<'EOF' >docs/source/_ext/PandasCompat.py
# Copyright (c) 2021-2022, NVIDIA CORPORATION

# This file is adapted from official sphinx tutorial for `todo` extension:
# https://www.sphinx-doc.org/en/master/development/tutorials/todo.html

from docutils import nodes
from docutils.parsers.rst import Directive
from sphinx.locale import get_translation
from sphinx.util.docutils import SphinxDirective

translator = get_translation("sphinx")


class PandasCompat(nodes.Admonition, nodes.Element):
    pass


class PandasCompatList(nodes.General, nodes.Element):
    pass


def visit_PandasCompat_node(self, node):
    self.visit_admonition(node)


def depart_PandasCompat_node(self, node):
    self.depart_admonition(node)


class PandasCompatListDirective(Directive):
    def run(self):
        return [PandasCompatList("")]


class PandasCompatDirective(SphinxDirective):

    # this enables content in the directive
    has_content = True

    def run(self):
        targetid = "PandasCompat-%d" % self.env.new_serialno("PandasCompat")
        targetnode = nodes.target("", "", ids=[targetid])

        PandasCompat_node = PandasCompat("\n".join(self.content))
        PandasCompat_node += nodes.title(
            translator("Pandas Compatibility Note"),
            translator("Pandas Compatibility Note"),
        )
        self.state.nested_parse(
            self.content, self.content_offset, PandasCompat_node
        )

        if not hasattr(self.env, "PandasCompat_all_pandas_compat"):
            self.env.PandasCompat_all_pandas_compat = []

        self.env.PandasCompat_all_pandas_compat.append(
            {
                "docname": self.env.docname,
                "PandasCompat": PandasCompat_node.deepcopy(),
                "target": targetnode,
            }
        )

        return [targetnode, PandasCompat_node]


def purge_PandasCompats(app, env, docname):
    if not hasattr(env, "PandasCompat_all_pandas_compat"):
        return

    env.PandasCompat_all_pandas_compat = [
        PandasCompat
        for PandasCompat in env.PandasCompat_all_pandas_compat
        if PandasCompat["docname"] != docname
    ]


def merge_PandasCompats(app, env, docnames, other):
    if not hasattr(env, "PandasCompat_all_pandas_compat"):
        env.PandasCompat_all_pandas_compat = []
    if hasattr(other, "PandasCompat_all_pandas_compat"):
        env.PandasCompat_all_pandas_compat.extend(
            other.PandasCompat_all_pandas_compat
        )


def process_PandasCompat_nodes(app, doctree, fromdocname):
    if not app.config.include_pandas_compat:
        for node in doctree.traverse(PandasCompat):
            node.parent.remove(node)

    # Replace all PandasCompatList nodes with a list of the collected
    # PandasCompats. Augment each PandasCompat with a backlink to the
    # original location.
    env = app.builder.env

    if not hasattr(env, "PandasCompat_all_pandas_compat"):
        env.PandasCompat_all_pandas_compat = []

    for node in doctree.traverse(PandasCompatList):
        if not app.config.include_pandas_compat:
            node.replace_self([])
            continue

        content = []

        for PandasCompat_info in env.PandasCompat_all_pandas_compat:
            para = nodes.paragraph()

            # Create a reference back to the original docstring
            newnode = nodes.reference("", "")
            innernode = nodes.emphasis(
                translator("[source]"), translator("[source]")
            )
            newnode["refdocname"] = PandasCompat_info["docname"]
            newnode["refuri"] = app.builder.get_relative_uri(
                fromdocname, PandasCompat_info["docname"]
            )
            newnode["refuri"] += "#" + PandasCompat_info["target"]["refid"]
            newnode.append(innernode)
            para += newnode

            # Insert the reference node into PandasCompat node
            # Note that this node is a deepcopy from the original copy
            # in the docstring, so changing this does not affect that in the
            # doc.
            PandasCompat_info["PandasCompat"].append(para)

            # Insert the PandasCompand node into the PandasCompatList Node
            content.append(PandasCompat_info["PandasCompat"])

        node.replace_self(content)


def setup(app):
    app.add_config_value("include_pandas_compat", False, "html")

    app.add_node(PandasCompatList)
    app.add_node(
        PandasCompat,
        html=(visit_PandasCompat_node, depart_PandasCompat_node),
        latex=(visit_PandasCompat_node, depart_PandasCompat_node),
        text=(visit_PandasCompat_node, depart_PandasCompat_node),
    )

    # Sphinx directives are lower-cased
    app.add_directive("pandas-compat", PandasCompatDirective)
    app.add_directive("pandas-compat-list", PandasCompatListDirective)
    app.connect("doctree-resolved", process_PandasCompat_nodes)
    app.connect("env-purge-doc", purge_PandasCompats)
    app.connect("env-merge-info", merge_PandasCompats)

    return {
        "version": "0.1",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
EOF

cat <<'EOF' >docs/source/conf.py
import os
import pathlib
import subprocess
import sys
sys.path.insert(0, pathlib.Path(__file__).parents[2].resolve().as_posix())
sys.path.append(os.path.abspath("./_ext"))
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
    "sphinx.ext.autodoc",
    "sphinx.ext.autosummary",
    "sphinx.ext.githubpages",
    "sphinx.ext.intersphinx",
    "PandasCompat",
]

exclude_patterns = []
pygments_style = "sphinx"
html_theme = "pydata_sphinx_theme"
html_static_path = ["_static"]
templates_path = ["_templates"]

include_pandas_compat = True

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

def setup(app):
    app.add_css_file("https://docs.rapids.ai/assets/css/custom.css")
    app.add_js_file(
        "https://docs.rapids.ai/assets/js/custom.js", loading_method="defer"
    )
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
   reindex
EOF

cat <<'EOF' >docs/source/compat.rst
.. currentmodule:: compatsphinxext

.. _compat:

#############
Compatability
#############

.. pandas-compat-list::

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
   Compatability <compat>
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

# One time creation
# cat <<'EOF' >Makefile
# SPHINXOPTS    ?=
# SPHINXBUILD   ?= sphinx-build
# SOURCEDIR     = source
# BUILDDIR      = build

# # Put it first so that "make" without argument is like "make help".
# help:
# 	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# .PHONY: help Makefile

# # Catch-all target: route all unknown targets to Sphinx using the new
# # "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
# %: Makefile
# 	@$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
# EOF

make html