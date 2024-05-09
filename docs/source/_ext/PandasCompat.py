# Copyright (c) 2021-2022, NVIDIA CORPORATION

# This file is adapted from official sphinx tutorial for `todo` extension:
# https://www.sphinx-doc.org/en/master/development/tutorials/todo.html

from typing import cast

from docutils import nodes
from docutils.parsers.rst import Directive
from sphinx import addnodes
from sphinx.domains import Domain
from sphinx.locale import get_translation
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


def process_PandasCompat_nodes(app, doctree, fromdocname):
    if not app.config.include_pandas_compat:
        for node in doctree.traverse(PandasCompat):
            node.parent.remove(node)

    # Replace all PandasCompatList nodes with a list of the collected
    # PandasCompats. Augment each PandasCompat with a backlink to the
    # original location.
    env = app.builder.env
    domain = cast(PandasCompatdDomain, app.env.get_domain("pandascompat"))
    document = new_document("")

    if not hasattr(env, "PandasCompat_all_pandas_compat"):
        env.PandasCompat_all_pandas_compat = []

    for node in doctree.traverse(PandasCompatList):
        if not app.config.include_pandas_compat:
            node.replace_self([])
            continue

        content = []

        for PandasCompat_info in env.PandasCompat_all_pandas_compat:
            para = nodes.paragraph()

            # Resolve reference
            # new_PandasCompat_info = PandasCompat_info.copy()
            # docname = new_PandasCompat_info["docname"]
            # for _node in new_PandasCompat_info.findall(addnodes.pending_xref):
            #     if "refdoc" in _node:
            #         _node["refdoc"] = docname
            # document += new_PandasCompat_info
            # env.resolve_references(document, docname,  app.builder)
            # document.remove(new_PandasCompat_info)

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
            # in the docstring, so changing this does not affect that in the doc.
            PandasCompat_info["PandasCompat"].append(para)

            # Insert the PandasCompant node into the PandasCompatList Node
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
        man=(visit_PandasCompat_node, depart_PandasCompat_node),
        texinfo=(visit_PandasCompat_node, depart_PandasCompat_node),
    )

    # Sphinx directives are lower-cased
    app.add_directive("pandas-compat", PandasCompatDirective)
    app.add_directive("pandas-compat-list", PandasCompatListDirective)
    app.add_domain(PandasCompatdDomain)
    app.connect("doctree-resolved", process_PandasCompat_nodes)
    app.connect("env-purge-doc", purge_PandasCompats)
    app.connect("env-merge-info", merge_PandasCompats)

    return {
        "version": "0.1",
        "parallel_read_safe": True,
        "parallel_write_safe": True,
    }
