import click
import boto3

from .config import ConfigLoader, yaml_safe_load, yaml_safe_dump

s3 = boto3.resource('s3')

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

@cognition_catalog.command(name="add_environment_variable")
@click.argument('configfile', type=str)
@click.option('--key', type=str, required=True)
@click.option('--value', type=str, required=True)
def add_environment_variable(configfile, key, value):
    contents = yaml_safe_load(configfile)

    if 'environment' in list(contents['provider']):
        contents['provider']['environment'].update({key:value})
    else:
        contents['provider'].update({'environment': {key:value}})

    yaml_safe_dump(contents, configfile)