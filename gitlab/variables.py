#!/usr/bin/env python
"""
This script is used to import/export ci/cd variables. This is used in situations when moving a project.
Command structure:
- `./variables.py export` print ci/cd variables to stdout
- `./variables.py import` send environment variables from stdin
- `./variables.py export | ./variables.py import` transfer variables
"""
import sys


def main(argv: list):
    """
    Main/entrypoint

    :param argv: os arguments
    """
    pass


if __name__ == '__main__':
    main(sys.argv)
