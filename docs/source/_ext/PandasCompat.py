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