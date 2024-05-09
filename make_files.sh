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

        This function has no args or kwargs compared to pandas.DataFrame.reindex
        This is the current RAPIDS sphinx ext.
    """
    return df.reindex(range(1, len(df)))


def rename(df: pd.DataFrame) -> pd.DataFrame:
    """
    Use :func:`pandas.DataFrame.rename` and rename the first
    column of :class:`pandas.DataFrame` "YO!".

    Parameters
    ----------
    df : pandas.DataFrame
        Pandas DataFrame.

    Returns
    -------
    pandas.DataFrame


    .. pandas-compat::
        **DataFrame.rename**

        Unlike pandas rename, which offers way more flexibility that,
        This function only renames your first columns to "YO!".
        This is the current RAPIDS sphinx ext.
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


class PandasCompatNode(nodes.Admonition, nodes.Element):
    pass


class PandasCompatList(nodes.General, nodes.Element):
    pass


class PandasCompat(BaseAdmonition, SphinxDirective):

    # this enables content in the directive
    node_class = PandasCompatNode
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
            self.options["class"] = ["admonition-pandas-compat"]

        (pandas_compat,) = super().run()
        if isinstance(pandas_compat, nodes.system_message):
            return [pandas_compat]
        elif isinstance(pandas_compat, PandasCompatNode):
            pandas_compat.insert(0, nodes.title(text=_("Pandas Compatibility Note")))
            pandas_compat["docname"] = self.env.docname
            self.add_name(pandas_compat)
            self.set_source_info(pandas_compat)
            self.state.document.note_explicit_target(pandas_compat)
            return [pandas_compat]
        else:
            raise RuntimeError  # never reached here


class PandasCompatDomain(Domain):
    name = "pandas-compat"
    label = "pandas-compat"    

    @property
    def pandas_compats(self) -> dict[str, list[PandasCompatNode]]:
        return self.data.setdefault("pandas-compats", {})

    def clear_doc(self, docname: str) -> None:
        self.pandas_compats.pop(docname, None)

    def merge_domaindata(self, docnames: list[str], otherdata: dict[str, Any]) -> None:
        for docname in docnames:
            self.pandas_compats[docname] = otherdata["todos"][docname]

    def process_doc(
        self, env: BuildEnvironment, docname: str, document: nodes.document
    ) -> None:
        pandas_compats = self.pandas_compats.setdefault(docname, [])
        for pandas_compat in document.findall(PandasCompatNode):
            env.app.emit("pandas-compat-defined", pandas_compat)
            pandas_compats.append(pandas_compat)

            if env.config.pandas_compat_emit_warnings:
                logger.warning(
                    __("pandas-compat entry found: %s"), pandas_compat[1].astext(), location=pandas_compat
                )

class PandasCompatList(SphinxDirective):
    """
    A list of all pandas-compat entries.
    """

    has_content = False
    required_arguments = 0
    optional_arguments = 0
    final_argument_whitespace = False
    option_spec: ClassVar[OptionSpec] = {}

    def run(self) -> list[Node]:
        # Simply insert an empty todolist node which will be replaced later
        # when process_todo_nodes is called
        return [PandasCompatList("")]


class PandasCompatListProcessor:
    def __init__(self, app: Sphinx, doctree: nodes.document, docname: str) -> None:
        self.builder = app.builder
        self.config = app.config
        self.env = app.env
        self.domain = cast(PandasCompatDomain, app.env.get_domain("todo"))
        self.document = new_document("")

        self.process(doctree, docname)

    def process(self, doctree: nodes.document, docname: str) -> None:
        todos: list[PandasCompatNode] = functools.reduce(
            operator.iadd, self.domain.pandas_compats.values(), []
        )
        for node in list(doctree.findall(PandasCompatList)):
            if not self.config.include_pandas_compat:
                node.parent.remove(node)
                continue

            if node.get("ids"):
                content: list[Element] = [nodes.target()]
            else:
                content = []

            for pandas_compat in pandas_compats:
                # Create a copy of the todo node
                new_pandas_compat = pandas_compat.deepcopy()
                new_pandas_compat["ids"].clear()

                self.resolve_reference(new_pandas_compat, docname)
                content.append(new_pandas_compat)

                pandas_compat_ref = self.create_pandas_compat_reference(new_pandas_compat, docname)
                content.append(pandas_compat_ref)

            node.replace_self(content)

    def create_pandas_compat_reference(self, pandas_compat: PandasCompatNode, docname: str) -> nodes.paragraph:
        if self.config.todo_link_only:
            description = _("<<original entry>>")
        else:
            description = _("(The <<original entry>> is located in %s, line %d.)") % (
                pandas_compat.source,
                pandas_compat.line,
            )

        prefix = description[: description.find("<<")]
        suffix = description[description.find(">>") + 2 :]

        para = nodes.paragraph(classes=["pandas-compat-source"])
        para += nodes.Text(prefix)

        # Create a reference
        linktext = nodes.emphasis(_("original entry"), _("original entry"))
        reference = nodes.reference("", "", linktext, internal=True)
        try:
            reference["refuri"] = self.builder.get_relative_uri(
                docname, pandas_compat["docname"]
            )
            reference["refuri"] += "#" + pandas_compat["ids"][0]
        except NoUri:
            # ignore if no URI can be determined, e.g. for LaTeX output
            pass

        para += reference
        para += nodes.Text(suffix)

        return para

    def resolve_reference(self, pandas_compat: PandasCompatNode, docname: str) -> None:
        """Resolve references in the todo content."""
        for node in pandas_compat.findall(addnodes.pending_xref):
            if "refdoc" in node:
                node["refdoc"] = docname

        # Note: To resolve references, it is needed to wrap it with document node
        self.document += pandas_compat
        self.env.resolve_references(self.document, docname, self.builder)
        self.document.remove(pandas_compat)

def visit_PandasCompatNode(self: HTML5Translator, node: PandasCompatNode) -> None:
    if self.config.include_pandas_compat:
        self.visit_admonition(node)
    else:
        raise nodes.SkipNode


def depart_PandasCompatNode(self: HTML5Translator, node: PandasCompatNode) -> None:
    self.depart_admonition(node)


def latex_visit_PandasCompatNode(self: LaTeXTranslator, node: PandasCompatNode) -> None:
    if self.config.todo_include_todos:
        self.body.append("\n\\begin{sphinxadmonition}{note}{")
        self.body.append(self.hypertarget_to(node))

        title_node = cast(nodes.title, node[0])
        title = texescape.escape(title_node.astext(), self.config.latex_engine)
        self.body.append("%s:}" % title)
        node.pop(0)
    else:
        raise nodes.SkipNode


def latex_depart_PandasCompatNode(self: LaTeXTranslator, node: PandasCompatNode) -> None:
    self.body.append("\\end{sphinxadmonition}\n")


def setup(app: Sphinx) -> ExtensionMetadata:
    app.add_event("todo-defined")
    app.add_config_value("include_pandas_compat", False, "html")
    app.add_config_value("pandas_compat_link_only", False, "html")
    app.add_config_value("tandas_compat_emit_warnings", False, "html")

    app.add_node(PandasCompatList)
    app.add_node(
        PandasCompatNode,
        html=(visit_PandasCompatNode, depart_PandasCompatNode),
        latex=(latex_visit_PandasCompatNode, latex_depart_PandasCompatNode),
        text=(visit_PandasCompatNode, depart_PandasCompatNode),
        man=(visit_PandasCompatNode, depart_PandasCompatNode),
        texinfo=(visit_PandasCompatNode, depart_PandasCompatNode),
    )

    app.add_directive("pandas-compat", PandasCompat)
    app.add_directive("todolist", PandasCompatList)
    app.add_domain(PandasCompatDomain)
    app.connect("doctree-resolved", PandasCompatListProcessor)
    return {
        "version": sphinx.__display_version__,
        "env_version": 2,
        "parallel_read_safe": True,
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