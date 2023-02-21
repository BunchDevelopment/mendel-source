from setuptools import setup, find_packages
from os import path
from io import open

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='vitalsd',
    version='1.0',
    description='A vital statistics monitor that outputs to serial consoles for embedded systems',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://coral.googlesource.com/vitalsd.git',
    author='Mendel Linux Software Team',
    author_email='coral-support@google.com',
    license='Apache 2',
    classifiers = [
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Topic :: Software Development',
        'Topic :: Utilities',
        'License :: OSI Approved :: Apache License',
        'Operating System :: POSIX',
        'Programming Language :: Python :: 3',
    ],
    keywords='embedded development',
    packages=find_packages(exclude=['contrib', 'docs', 'tests']),
    python_requires='>=3.5.0',
    install_requires=[
    ],
    data_files=[('share/man/man1', ['man/vitalsd.1'])],
    package_data={
    },
    entry_points={
        'console_scripts': [
            'vitalsd=vitalsd.main:main',
        ],
    },
)
