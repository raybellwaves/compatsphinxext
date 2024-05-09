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
        **DataFrame.reindex**

        This function has no args or kwargs compared to :meth:`pandas.DataFrame.reindex`
        This is the current RAPIDS sphinx ext.
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
        **DataFrame.rename**

        Unlike pandas rename, which offers way more flexibility that,
        This function only renames your first columns to "YO!".
        This is the current RAPIDS sphinx ext.
    """
    return df.rename(columns={df.columns[0]: "YO!"})
