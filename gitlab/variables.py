#!/usr/bin/env python3
"""
This script is used to import/export ci/cd variables. This is used in situations when moving a project.
Command structure:
  - `./variables.py export` or `./variable.py export` print ci/cd variables to stdout
  - `./variables.py import` or ./variables import` send environment variables from stdin
  - `./variables.py export | ./variables.py import` transfer variables
Arguments:
  - `command` import or export
Options:
  - `--env-file` file contains variables
  - `--gitlab-private-token` required
  - `--gitlab-url` optional, default `https://gitlab.com`
  - `--gitlab-group` required
  - `--gitlab-project` optional
"""
import argparse
import enum
import inspect
import json
import sys
import typing
import urllib.request


class Command(enum.Enum):
    """Available commands"""
    cmd_import = 'import'
    cmd_export = 'export'

    def __str__(self):
        return self.value


class GitlabSettings:
    """Gitlab settings dataclass"""

    def __init__(self, *args, **kwargs):
        self.private_token: typing.Optional[str] = kwargs.get('private_token')
        self.url: typing.Optional[str] = kwargs.get('url')
        self.group: typing.Optional[str] = kwargs.get('group')
        self.project: typing.Optional[str] = kwargs.get('project')

        # Always remove trailing slash
        self.url = self.url.rstrip('/')


class GitlabVariable:
    """Gitlab variable dataclass"""

    def __init__(self, *args, **kwargs):
        self.variable_type = kwargs.get('variable_type')
        self.key: str = kwargs.get('key')
        self.value: str = kwargs.get('value')
        self.protected: bool = kwargs.get('protected') or False
        self.masked: bool = kwargs.get('masked') or False
        self.environment_scope: str = kwargs.get('environment_scope')


def cmd_import(gitlab_settings: GitlabSettings, gitlab_variables: typing.List[GitlabVariable]):
    """Import command"""
    for item in gitlab_variables:
        print(item.key, item.value)
    pass


def cmd_export(gitlab_settings: GitlabSettings) -> typing.List[GitlabVariable]:
    """Export command"""
    url = f'{gitlab_settings.url}/groups/{gitlab_settings.group}/variables'
    if gitlab_settings.project:
        url = f'{gitlab_settings.url}/projects/{gitlab_settings.project}/variables'
    request = urllib.request.Request(url, method='GET', headers={
        'PRIVATE-TOKEN': gitlab_settings.private_token,
    })
    response = urllib.request.urlopen(request)
    data = json.load(response)
    return [
        GitlabVariable(**item)
        for item in data
    ]


def param_gitlab_settings(args) -> GitlabSettings:
    """Gitlab settings builder"""
    return GitlabSettings(
        private_token=args.gitlab_private_token,
        url=args.gitlab_url,
        group=args.gitlab_group,
        project=args.gitlab_project,
    )


def param_gitlab_variables(args) -> typing.List[GitlabVariable]:
    """Gitlab variables builder"""
    data = json.load(args.input)
    if not isinstance(data, list):
        return []
    else:
        return [GitlabVariable(**item) for item in data]


def main(argv: list):
    """Main/entrypoint"""
    args_parser = argparse.ArgumentParser(prog='./variables.py', description='Gitlab Variables')
    args_parser.add_argument('command', type=Command, choices=list(Command), help='Command name')
    args_parser.add_argument('--input', type=argparse.FileType('r'), required=False, default=sys.stdin,
                             help='Input file')
    args_parser.add_argument('--output', type=argparse.FileType('w'), required=False, default=sys.stdout,
                             help='Output file')
    args_parser.add_argument('--gitlab-private-token', type=str, required=True, action='store',
                             help='Gitlab private token')
    args_parser.add_argument('--gitlab-url', type=str, required=False, default='https://gitlab.com/api/v4/',
                             action='store', help='Gitlab url address')
    args_parser.add_argument('--gitlab-group', type=str, required=False, action='store', help='Gitlab group ID or SLUG')
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
    result = handler(**handler_kwargs)
    if result is None:
        print('')
    if isinstance(result, str):
        print(result)
    else:
        args.output.write(json.dumps(result, ensure_ascii=False, indent='  ',
                         default=lambda obj: obj.__dict__ if isinstance(obj, (GitlabVariable,)) else str(obj)))


if __name__ == '__main__':
    main(sys.argv)
