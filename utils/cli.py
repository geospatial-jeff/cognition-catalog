import click

from .config import ConfigLoader

@click.group()
def cognition_catalog():
    pass

@cognition_catalog.command(name="load_user_config")
def load_user_config():
    """
    Load user configuration in `config.yml` and update cognition-datasources, cognition-catalog, and sat-api configurations.
    """
    config = ConfigLoader()
    config.build_configs()
    config.write_configs()