# Copyright (c) 2021-2022, NVIDIA CORPORATION

# This file is adapted from official sphinx tutorial for `todo` extension:
# https://www.sphinx-doc.org/en/master/development/tutorials/todo.html

import functools
import operator
from typing import cast

from docutils import nodes
from docutils.nodes import Element
from docutils.parsers.rst import Directive
from sphinx import addnodes
from sphinx.domains import Domain
from sphinx.locale import _, get_translation
from sphinx.util.docutils import SphinxDirective, new_document

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
        print("running self.process")
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

                #ref = self.create_reference(pandascompat, docname)
                #content.append(ref)

            node.replace_self(content)

    def create_reference(self, pandascompat, docname):
        description = _("(The <<original entry>> is located in %s, line %d.)") % (
            pandascompat.source,
            pandascompat.line,
        )

        prefix = description[: description.find("<<")]
        suffix = description[description.find(">>") + 2 :]

        para = nodes.paragraph(classes=["pandascompat-source"])
        para += nodes.Text(prefix)

        # Create a reference
        linktext = nodes.emphasis(_("original entry"), _("original entry"))
        reference = nodes.reference("", "", linktext, internal=True)
        try:
            reference["refuri"] = self.builder.get_relative_uri(
                docname, pandascompat["docname"]
            )
            reference["refuri"] += "#" + todo["ids"][0]
        except NoUri:
            # ignore if no URI can be determined, e.g. for LaTeX output
            pass

        para += reference
        para += nodes.Text(suffix)

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
    print("running add_config_value")
    app.add_config_value("include_pandas_compat", False, "html")
    print("running add_node(PandasCompatList)")
    app.add_node(PandasCompatList)
    print("running add_node(PandasCompat)")
    app.add_node(
        PandasCompat,
        html=(visit_PandasCompat_node, depart_PandasCompat_node),
        latex=(visit_PandasCompat_node, depart_PandasCompat_node),
        text=(visit_PandasCompat_node, depart_PandasCompat_node),
        man=(visit_PandasCompat_node, depart_PandasCompat_node),
        texinfo=(visit_PandasCompat_node, depart_PandasCompat_node),
    )
    print("running add_directive('pandas-compat', PandasCompatDirective)")
    app.add_directive("pandas-compat", PandasCompatDirective)
    print("running add_directive('pandas-compat-list', PandasCompatListDirective)")
    app.add_directive("pandas-compat-list", PandasCompatListDirective)
    print("running add add_domain(PandasCompatdDomain)")
    app.add_domain(PandasCompatdDomain)
    print("running app.connect('doctree-resolved', PandasCompatListProcessor)")   
    app.connect("doctree-resolved", PandasCompatListProcessor)

    return {
        "version": "0.1",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
