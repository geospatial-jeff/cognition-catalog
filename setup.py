from setuptools import setup, find_packages

with open('./requirements.txt') as reqs:
    requirements = [line.rstrip() for line in reqs]

setup(name="cognition-catalog",
      version='0.1',
      author='Jeff Albrecht',
      author_email='geospatialjeff@gmail.com',
      packages=find_packages(exclude=['docs']),
      install_requires = requirements,
      entry_points= {
          "console_scripts": [
              "cognition-catalog=utils.cli:cognition_catalog"
          ]},
      include_package_data=True
      )