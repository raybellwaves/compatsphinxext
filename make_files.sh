#!/bin/sh
# ./make_files.sh

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


    .. todo::
        Fix this and checkout :class:`pandas.DataFrame`.
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


    .. todo::
        Fix this and checkout :class:`networkx.DiGraph`.
    """
    ingredients = ['eggs', 'tomato', 'pasta', 'beef', 'bell pepper']
    meals = ['omelette', 'pasta salad', 'spaghetti bolognese', 'spaghetti bolognese', 'stir fry']
    df = pd.DataFrame({'ingredient': ingredients, 'meal': meals})
    return nx.from_pandas_edgelist(df, source="ingredient", target="meal", create_using=nx.DiGraph)


def reindex(df: pd.DataFrame) -> pd.DataFrame:
    """
    Use :meth:`pandas.DataFrame.reindex` and drop the first row of the
    :class:`pandas.DataFrame`.

    Parameters
    ----------
    df : pandas.DataFrame
        Pandas DataFrame.

    Returns
    -------
    pandas.DataFrame


    .. pandas-compat::
        :meth:`pandas.DataFrame.reindex`

        This function has no args or kwargs compared to the pandas version.
    """
    return df.reindex(range(1, len(df)))


def rename(df: pd.DataFrame) -> pd.DataFrame:
    """
    Use :meth:`pandas.DataFrame.rename` and rename the first
    column of :class:`pandas.DataFrame` "YO!".

    Parameters
    ----------
    df : pandas.DataFrame
        Pandas DataFrame.

    Returns
    -------
    pandas.DataFrame


    .. pandas-compat::
        :meth:`pandas.DataFrame.rename`

        Unlike pandas rename, which offers way more flexibility than this,
        This function simply renames your first columns to "YO!".
    """
    return df.rename(columns={df.columns[0]: "YO!"})
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
from __future__ import annotations

import functools
import operator
from typing import cast

from docutils import nodes
from docutils.nodes import Element
from docutils.parsers.rst import Directive
from docutils.parsers.rst.directives.admonitions import BaseAdmonition
from sphinx import addnodes
from sphinx.domains import Domain
from sphinx.errors import NoUri
from sphinx.locale import _ as get_translation_sphinx
from sphinx.util.docutils import SphinxDirective, new_document


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


class PandasCompatDirective(BaseAdmonition, SphinxDirective):

    # this enables content in the directive
    has_content = True

    def run(self):
        targetid = "PandasCompat-%d" % self.env.new_serialno("PandasCompat")
        targetnode = nodes.target("", "", ids=[targetid])

        PandasCompat_node = PandasCompat("\n".join(self.content))
        PandasCompat_node += nodes.title(
            get_translation_sphinx("Pandas Compatibility Note"),
            get_translation_sphinx("Pandas Compatibility Note"),
        )
        PandasCompat_node["docname"] = self.env.docname
        PandasCompat_node["target"] = targetnode        
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


class PandasCompatdDomain(Domain):
    name = "pandascompat"
    label = "pandascompat"

    @property
    def pandascompats(self):
        return self.data.setdefault("pandascompats", {})

    def clear_doc(self, docname):
        self.pandascompats.pop(docname, None)

    def merge_domaindata(self, docnames, otherdata):
        for docname in docnames:
            self.pandascompats[docname] = otherdata["pandascompats"][docname]

    def process_doc(self, env, docname, document):
        pandascompats = self.pandascompats.setdefault(docname, [])
        for pandascompat in document.findall(PandasCompat):
            env.app.emit("pandascompat-defined", pandascompat)
            pandascompats.append(pandascompat)


class PandasCompatListProcessor:
    def __init__(self, app, doctree, docname):
        self.builder = app.builder
        self.config = app.config
        self.env = app.env
        self.domain = cast(PandasCompatdDomain, app.env.get_domain("pandascompat"))
        self.document = new_document("")
        self.process(doctree, docname)

    def process(self, doctree: nodes.document, docname: str) -> None:
        pandascompats = functools.reduce(
            operator.iadd, self.domain.pandascompats.values(), []
        )
        for node in list(doctree.findall(PandasCompatList)):
            if not self.config.include_pandas_compat:
                node.parent.remove(node)
                continue

            if node.get("ids"):
                content: list[Element] = [nodes.target()]
            else:
                content = []

            for pandascompat in pandascompats:
                # Create a copy of the pandascompat node
                new_pandascompat = pandascompat.deepcopy()
                new_pandascompat["ids"].clear()

                self.resolve_reference(new_pandascompat, docname)
                content.append(new_pandascompat)

                ref = self.create_reference(pandascompat, docname)
                content.append(ref)

            node.replace_self(content)

    def create_reference(self, pandascompat, docname):
        para = nodes.paragraph()
        newnode = nodes.reference("", "")
        innernode = nodes.emphasis(
            get_translation_sphinx("[source]"), get_translation_sphinx("[source]")
        )
        newnode["refdocname"] = pandascompat["docname"]
        try:
            newnode["refuri"] = self.builder.get_relative_uri(
                docname, pandascompat["docname"]
            )
            newnode["refuri"] += "#" + pandascompat["target"]["refid"]
        except NoUri:
            # ignore if no URI can be determined, e.g. for LaTeX output
            pass        
        newnode.append(innernode)
        para += newnode
        return para

    def resolve_reference(self, todo, docname: str) -> None:
        """Resolve references in the todo content."""
        for node in todo.findall(addnodes.pending_xref):
            if "refdoc" in node:
                node["refdoc"] = docname

        # Note: To resolve references, it is needed to wrap it with document node
        self.document += todo
        self.env.resolve_references(self.document, docname, self.builder)
        self.document.remove(todo)


def setup(app):
    app.add_config_value("include_pandas_compat", False, "html")
    app.add_node(PandasCompatList)
    app.add_node(
        PandasCompat,
        html=(visit_PandasCompat_node, depart_PandasCompat_node),
        latex=(visit_PandasCompat_node, depart_PandasCompat_node),
        text=(visit_PandasCompat_node, depart_PandasCompat_node),
        man=(visit_PandasCompat_node, depart_PandasCompat_node),
        texinfo=(visit_PandasCompat_node, depart_PandasCompat_node),
    )
    app.add_directive("pandas-compat", PandasCompatDirective)
    app.add_directive("pandas-compat-list", PandasCompatListDirective)
    app.add_domain(PandasCompatdDomain) 
    app.connect("doctree-resolved", PandasCompatListProcessor)

    return {
        "version": "0.1",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
EOF

# current sphinx todo extension
# https://github.com/sphinx-doc/sphinx/blob/master/sphinx/ext/todo.py
# but blackened
cat <<'EOF' >docs/source/_ext/todo.py
"""Allow todos to be inserted into your documentation.

Inclusion of todos can be switched of by a configuration variable.
The todolist directive collects all todos of your project and lists them along
with a backlink to the original location.
"""

from __future__ import annotations

import functools
import operator
from typing import TYPE_CHECKING, Any, ClassVar, cast

from docutils import nodes
from docutils.parsers.rst import directives
from docutils.parsers.rst.directives.admonitions import BaseAdmonition

import sphinx
from sphinx import addnodes
from sphinx.domains import Domain
from sphinx.errors import NoUri
from sphinx.locale import _, __
from sphinx.util import logging, texescape
from sphinx.util.docutils import SphinxDirective, new_document

if TYPE_CHECKING:
    from docutils.nodes import Element, Node

    from sphinx.application import Sphinx
    from sphinx.environment import BuildEnvironment
    from sphinx.util.typing import ExtensionMetadata, OptionSpec
    from sphinx.writers.html import HTML5Translator
    from sphinx.writers.latex import LaTeXTranslator

logger = logging.getLogger(__name__)


class todo_node(nodes.Admonition, nodes.Element):
    pass


class todolist(nodes.General, nodes.Element):
    pass


class Todo(BaseAdmonition, SphinxDirective):
    """
    A todo entry, displayed (if configured) in the form of an admonition.
    """

    node_class = todo_node
    has_content = True
    required_arguments = 0
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec: ClassVar[OptionSpec] = {
        "class": directives.class_option,
        "name": directives.unchanged,
    }

    def run(self) -> list[Node]:
        if not self.options.get("class"):
            self.options["class"] = ["admonition-todo"]

        (todo,) = super().run()
        if isinstance(todo, nodes.system_message):
            return [todo]
        elif isinstance(todo, todo_node):
            todo.insert(0, nodes.title(text=_("Todo")))
            todo["docname"] = self.env.docname
            self.add_name(todo)
            self.set_source_info(todo)
            self.state.document.note_explicit_target(todo)
            return [todo]
        else:
            raise RuntimeError  # never reached here


class TodoDomain(Domain):
    name = "todo"
    label = "todo"

    @property
    def todos(self) -> dict[str, list[todo_node]]:
        return self.data.setdefault("todos", {})

    def clear_doc(self, docname: str) -> None:
        self.todos.pop(docname, None)

    def merge_domaindata(self, docnames: list[str], otherdata: dict[str, Any]) -> None:
        for docname in docnames:
            self.todos[docname] = otherdata["todos"][docname]

    def process_doc(
        self, env: BuildEnvironment, docname: str, document: nodes.document
    ) -> None:
        todos = self.todos.setdefault(docname, [])
        for todo in document.findall(todo_node):
            env.app.emit("todo-defined", todo)
            todos.append(todo)

            if env.config.todo_emit_warnings:
                logger.warning(
                    __("TODO entry found: %s"), todo[1].astext(), location=todo
                )


class TodoList(SphinxDirective):
    """
    A list of all todo entries.
    """

    has_content = False
    required_arguments = 0
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec: ClassVar[OptionSpec] = {}

    def run(self) -> list[Node]:
        # Simply insert an empty todolist node which will be replaced later
        # when process_todo_nodes is called
        return [todolist("")]


class TodoListProcessor:
    def __init__(self, app: Sphinx, doctree: nodes.document, docname: str) -> None:
        self.builder = app.builder
        self.config = app.config
        self.env = app.env
        self.domain = cast(TodoDomain, app.env.get_domain("todo"))
        self.document = new_document("")

        self.process(doctree, docname)

    def process(self, doctree: nodes.document, docname: str) -> None:
        todos: list[todo_node] = functools.reduce(
            operator.iadd, self.domain.todos.values(), []
        )
        for node in list(doctree.findall(todolist)):
            if not self.config.todo_include_todos:
                node.parent.remove(node)
                continue

            if node.get("ids"):
                content: list[Element] = [nodes.target()]
            else:
                content = []

            for todo in todos:
                # Create a copy of the todo node
                new_todo = todo.deepcopy()
                new_todo["ids"].clear()

                self.resolve_reference(new_todo, docname)
                content.append(new_todo)

                todo_ref = self.create_todo_reference(todo, docname)
                content.append(todo_ref)

            node.replace_self(content)

    def create_todo_reference(self, todo: todo_node, docname: str) -> nodes.paragraph:
        if self.config.todo_link_only:
            description = _("<<original entry>>")
        else:
            description = _("(The <<original entry>> is located in %s, line %d.)") % (
                todo.source,
                todo.line,
            )

        prefix = description[: description.find("<<")]
        suffix = description[description.find(">>") + 2 :]

        para = nodes.paragraph(classes=["todo-source"])
        para += nodes.Text(prefix)

        # Create a reference
        linktext = nodes.emphasis(_("original entry"), _("original entry"))
        reference = nodes.reference("", "", linktext, internal=True)
        try:
            reference["refuri"] = self.builder.get_relative_uri(
                docname, todo["docname"]
            )
            reference["refuri"] += "#" + todo["ids"][0]
        except NoUri:
            # ignore if no URI can be determined, e.g. for LaTeX output
            pass

        para += reference
        para += nodes.Text(suffix)

        return para

    def resolve_reference(self, todo: todo_node, docname: str) -> None:
        """Resolve references in the todo content."""
        for node in todo.findall(addnodes.pending_xref):
            if "refdoc" in node:
                node["refdoc"] = docname

        # Note: To resolve references, it is needed to wrap it with document node
        self.document += todo
        self.env.resolve_references(self.document, docname, self.builder)
        self.document.remove(todo)


def visit_todo_node(self: HTML5Translator, node: todo_node) -> None:
    if self.config.todo_include_todos:
        self.visit_admonition(node)
    else:
        raise nodes.SkipNode


def depart_todo_node(self: HTML5Translator, node: todo_node) -> None:
    self.depart_admonition(node)


def latex_visit_todo_node(self: LaTeXTranslator, node: todo_node) -> None:
    if self.config.todo_include_todos:
        self.body.append("\n\\begin{sphinxadmonition}{note}{")
        self.body.append(self.hypertarget_to(node))

        title_node = cast(nodes.title, node[0])
        title = texescape.escape(title_node.astext(), self.config.latex_engine)
        self.body.append("%s:}" % title)
        node.pop(0)
    else:
        raise nodes.SkipNode


def latex_depart_todo_node(self: LaTeXTranslator, node: todo_node) -> None:
    self.body.append("\\end{sphinxadmonition}\n")


def setup(app: Sphinx) -> ExtensionMetadata:
    app.add_event("todo-defined")
    app.add_config_value("todo_include_todos", False, "html")
    app.add_config_value("todo_link_only", False, "html")
    app.add_config_value("todo_emit_warnings", False, "html")

    app.add_node(todolist)
    app.add_node(
        todo_node,
        html=(visit_todo_node, depart_todo_node),
        latex=(latex_visit_todo_node, latex_depart_todo_node),
        text=(visit_todo_node, depart_todo_node),
        man=(visit_todo_node, depart_todo_node),
        texinfo=(visit_todo_node, depart_todo_node),
    )

    app.add_directive("todo", Todo)
    app.add_directive("todolist", TodoList)
    app.add_domain(TodoDomain)
    app.connect("doctree-resolved", TodoListProcessor)
    return {
        "version": sphinx.__display_version__,
        "env_version": 2,
        "parallel_read_safe": True,
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
    "todo",
]

exclude_patterns = []
pygments_style = "sphinx"
html_theme = "pydata_sphinx_theme"
html_static_path = ["_static"]
templates_path = ["_templates"]

include_pandas_compat = True

todo_include_todos = True

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
   rename
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

TODOS
-----

.. todolist::
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
# if building and testing locally comment these out
make clean
# this will build with a debugger
#sphinx-build -b html docs/source docs/build/html -T -a -E -P