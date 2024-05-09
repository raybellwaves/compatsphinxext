# compatsphinxext

Goal: Create a generic sphinx extention similar to https://github.com/rapidsai/cudf/blob/branch-24.06/docs/cudf/source/_ext/PandasCompat.py
That allows linking back to upstream API.
i.e. for cudf it can link to the API of pandas and for cugraph it can link to the API of networkx.
Host on rapids-contrib, Publish it on pypi then it can be used across cudf and cugraph.

cudf and cugraph uses "numpydoc" (https://github.com/rapidsai/cudf/blob/branch-24.06/docs/cudf/source/conf.py#L72C6-L72C14)

The only file to touch is the make_files.sh.

Current if you try and add :meth:`pandas.DataFrame.rename` for example into pandas-compat you get

```
/workspaces/compatsphinxext/compatsphinxext.py:docstring of compatsphinxext.rename:19: WARNING: unknown node type: <pending_xref: <literal...>>

Exception occurred:
  File "/home/vscode/.local/lib/python3.12/site-packages/docutils/nodes.py", line 2027, in unknown_departure
    raise NotImplementedError(
NotImplementedError: <class 'types.BootstrapHTML5Translator'> departing unknown node type: pending_xref
The full traceback has been saved in /tmp/sphinx-err-mvruu8cb.log, if you want to report the issue to the developers.
```

I've got a first draft passing.

TODO:
 - Add the source like into the Admonition like it is currently.
 - Add typing similar to the sphinx todo extention
 - Copy paste to create a networkx-compat.
