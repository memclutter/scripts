#!/usr/bin/env python3
"""
This script is used to import/export ci/cd variables. This is used in situations when moving a project.
Command structure:
  - `./variables.py export` print ci/cd variables to stdout
  - `./variables.py import` send environment variables from stdin
  - `./variables.py export | ./variables.py import` transfer variables
Arguments:
  - `command` import or export
Options:
  - `--gitlab-token` required
  - `--gitlab-url` optional, default `https://gitlab.com`
  - `--gitlab-group` required
  - `--gitlab-project` optional
"""
import argparse
import enum
import inspect
import sys
import typing


class Command(enum.Enum):
    """Available commands"""
    cmd_import = 'import'
    cmd_export = 'export'

    def __str__(self):
        return self.value


class GitlabSettings:
    """Gitlab settings dataclass"""
    def __init__(self):
        self.token: typing.Optional[str] = None
        self.url: typing.Optional[str] = None
        self.group: typing.Optional[str] = None
        self.project: typing.Optional[str] = None


class GitlabVariable:
    """Gitlab variable dataclass"""
    def __init__(self):
        self.name: str
        self.value: str
        self.is_protected: bool
        self.is_masked: bool
        self.environment: str


def cmd_import(gitlab_settings: GitlabSettings, gitlab_variables: typing.List[GitlabVariable]):
    """Import command"""
    pass


def cmd_export(gitlab_settings: GitlabSettings) -> typing.List[GitlabVariable]:
    """Export command"""
    pass


def param_gitlab_settings(args: list) -> GitlabSettings:
    """Gitlab settings builder"""
    return GitlabSettings()


def param_gitlab_variables(args: list) -> typing.List[GitlabVariable]:
    """Gitlab variables builder"""
    return []


def main(argv: list):
    """Main/entrypoint"""
    args_parser = argparse.ArgumentParser(prog='./variables.py', description='Gitlab Variables')
    args_parser.add_argument('command', type=Command, choices=list(Command), help='Command name')
    args_parser.add_argument('--gitlab-token', type=str, required=True, action='store', help='Gitlab access token')
    args_parser.add_argument('--gitlab-url', type=str, required=False, default='https://gitlab.com/', action='store',
                             help='Gitlab url address')
    args_parser.add_argument('--gitlab-group', type=str, required=True, action='store', help='Gitlab group ID or SLUG')
    args_parser.add_argument('--gitlab-project', type=str, required=False, action='store',
                             help='Gitlab project ID or SLUG')
    args = args_parser.parse_args()

    routing = {cmd.value: globals()[cmd.name] for cmd in Command}
    param_routing = {p: globals()[f'param_{p}'] for p in {'gitlab_settings', 'gitlab_variables'}}
    handler = routing.get(args.command.value)
    if handler is None:
        raise SystemExit(f'Handler {args.command} not defined')
    elif not callable(handler):
        raise SystemExit(f'Handler {args.command} incorrect defined')
    handler_kwargs = {}
    for param_type in inspect.signature(handler).parameters.values():
        param_getter = param_routing.get(param_type.name)
        if param_getter is None:
            raise SystemExit(f'Handler param {param_type.name} not define getter func')
        elif not callable(param_getter):
            raise SystemExit(f'Handler param {param_type.name} not callable getter func')
        handler_kwargs[param_type.name] = param_getter(args)
    handler(**handler_kwargs)


if __name__ == '__main__':
    main(sys.argv)
