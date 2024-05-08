# compatsphinxext

Goal: Create a generic sphinx extention similar to https://github.com/rapidsai/cudf/blob/branch-24.06/docs/cudf/source/_ext/PandasCompat.py
That allows linking back to upstream API.
i.e. for cudf it can link to the API of pandas and for cugraph it can link to the API of networkx.
Host on rapids-contrib, Publish it on pypi then it can be used across cudf and cugraph.

cudf and cugraph uses "numpydoc" (https://github.com/rapidsai/cudf/blob/branch-24.06/docs/cudf/source/conf.py#L72C6-L72C14)

