import networkx as nx
import pandas as pd
import pyarrow as pa


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


def to_numeric(s: pd.Series) -> pd.Series:
    """
    Use :func:`pandas.to_numeric`.

    Parameters
    ----------
    s : pandas.Series
        Pandas Series.

    Returns
    -------
    pandas.Series


    .. pandas-compat::
        :func:`pandas.to_numeric`

        No differences.
    """
    return pd.to_numeric(s)


def empty(df: pd.DataFrame) -> bool:
    """
    Use :attr:`pandas.DataFrame.empty`.

    Parameters
    ----------
    s : pandas.Series
        Pandas Series.

    Returns
    -------
    pandas.Series


    .. pandas-compat::
        :attr:`pandas.DataFrame.empty`

        No differences.
    """
    return df.empty


def from_arrow(t: pa.Table) -> pd.DataFrame:
    """
    Use :meth:`pyarrow.Table.to_pandas`.

    Parameters
    ----------
    s : pandas.Series
        Pandas Series.

    Returns
    -------
    pandas.Series


    .. pandas-compat::
        :meth:`pyarrow.Table.to_pandas`

        No differences.
    """
    return t.to_pandas()


def ewm(df: pd.DataFrame) -> pd.core.window.ewm.ExponentialMovingWindow:
    """
    Uses :meth:`pandas.DataFrame.ewm`.

    Parameters
    ----------
    s : pandas.Series
        Pandas Series.

    Returns
    -------
    pandas.Series


    .. pandas-compat::
        :meth:`pandas.DataFrame.ewm`

        No differences.
    """
    return df.ewm(com=0.5)
