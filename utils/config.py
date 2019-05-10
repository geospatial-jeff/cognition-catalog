import yaml
import os

class ConfigLoader(object):

    @staticmethod
    def yaml_safe_load(yaml_file):
        with open(yaml_file, 'r') as stream:
            return yaml.safe_load(stream)

    @staticmethod
    def yaml_safe_dump(data, yaml_file):
        with open(yaml_file, 'w') as outfile:
            yaml.safe_dump(data, outfile, default_flow_style=False)

    def __init__(self):
        self.user_config = os.path.join(os.path.dirname(__file__), '..', 'config.yml')
        self.api_config = os.path.join(os.path.dirname(__file__), '..', 'sat-api-deployment', '.kes', 'config.yml')
        self.cd_config = os.path.join(os.path.dirname(__file__), '..', 'cognition-datasources', 'serverless.yml')
        self.catalog_config = os.path.join(os.path.dirname(__file__), '..', 'catalog', 'serverless.yml')
        self.configs = self.load_configs(['user_config', 'api_config', 'cd_config', 'catalog_config'])

    def load_configs(self, file_list):
        configs = {x:self.yaml_safe_load(getattr(self, x)) for x in file_list}
        return configs

    def build_configs(self):
        """Build cognition-datasources and sat-api configuration with values from catalog configuration"""

        # Update cognition-catalog configuration
        self.configs['catalog_config']['service'] = self.configs['user_config']['name']

        # Update sat-api configuration
        self.configs['api_config']['default']['system_bucket'] = self.configs['user_config']['sat-api']['bucket']
        self.configs['api_config']['default']['lambdas']['ingest']['envs']['SUBNETS'] = ' '.join(self.configs['user_config']['sat-api']['subnets'])
        self.configs['api_config']['default']['lambdas']['ingest']['envs']['SECURITY_GROUPS'] = self.configs['user_config']['sat-api']['security-group']

        # Update cognition-datsources configuration
        self.configs['cd_config']['custom']['service-name'] = self.configs['user_config']['cognition-datasources']['name']
        self.configs['cd_config']['custom']['stage'] = self.configs['user_config']['cognition-datasources']['stage']

    def write_configs(self):
        """Write configuration files"""
        print("Updating cognition-datasources configuration.")
        self.yaml_safe_dump(self.configs['cd_config'], self.cd_config)
        print("Updating sat-api configuration.")
        self.yaml_safe_dump(self.configs['api_config'], self.api_config)

if __name__ == "__main__":
    config = ConfigLoader()
    config.build_configs()
    config.write_configs()