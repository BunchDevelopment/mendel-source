#!/usr/bin/python3

from setuptools import setup, find_packages
from os import path
from io import open

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='mendel-development-tool',
    version='1.5.2',
    description='A command-line tool to manage Mendel Linux embedded systems',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://coral.googlesource.com/mdt.git',
    author='Mendel Linux Software Team',
    author_email='coral-support@google.com',
    license='Apache 2',
    classifiers = [
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Software Development',
        'Topic :: Utilities',
        'License :: OSI Approved :: Apache Software License',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 3',
    ],
    keywords='embedded development',
    packages=find_packages(),
    python_requires='>=3.5.0',
    install_requires=[
        'zeroconf>=0.27.0',
        'paramiko>=2.0.0'
    ],
    data_files=[('share/man/man1', ['man/mdt.1'])],
    entry_points={
        'console_scripts': [
            'mdt=mdt.main:main',
        ],
    },
)
