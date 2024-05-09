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
