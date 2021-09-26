# get issue title from issue id from altasian jira server by REST API
#

from os import environ
from atlassian import Jira
import requests
import json
import yaml
import argparse
import logging


class JiraConfig:
    def __init__(self, jira_config):
        self.protocol = jira_config["protocol"]
        self.url = jira_config["url"]
        self.user = jira_config["user"]
        self.password = jira_config["password"]
        
def _parse_args():
    parser = argparse.ArgumentParser(
        prog="createRelease",
        usage="%(prog)s ",
        description="Hifly release automation (only git repos)",
    )
    parser.add_argument('--yaml-input', required=True, type=str,
                        help='input configuration file (yaml format)')
    parser.add_argument('--output', required=True, type=str,
                        help='file which dumps issue information')

    # Getting arguments
    return parser.parse_args()

def _get_data_config(data_file_path: str):
    data_dict: dict = dict()
    for e in _get_dict_from_yaml(data_file_path):
        data_dict.update(e)
    return data_dict

def _get_release_config(config_file_path: str):
    return _get_dict_from_yaml(config_file_path)

def _get_dict_from_yaml(yaml_file_path: str):
    with open(yaml_file_path) as file:
        return yaml.full_load(file)

def to_file(issues_json, file_path: str):
    with open(file_path, "wt") as f:
        f.write(json.dumps(issues_json, indent=2))

def get_title_from_jira(jc: JiraConfig, issues: list) -> requests.Response:
    jira = Jira(
        url=f"{jc.protocol}://{jc.url}",
        username=jc.user,
        password=jc.password,
    )    
    # iterate over all issues in ISSUES, and get the title from jira (jira.get_issue(i))
    for i in issues:
        issue = jira.get_issue(i)
        print(issue)
        exit(1)

def get_summary_from_api(jc: JiraConfig, issues: list) -> requests.Response:
    url = f"{jc.protocol}://{jc.user}:{jc.password}@{jc.url}/rest/api/2/search"
        
    issues_str = ",".join(issues)
    data = {
        "jql": "key in (%s)" % issues_str,
        "startAt": 0,
        "maxResults": 10000000,
        "fields": [
            "summary",
        "status",
        "assignee",
        ]
    }
    headers = {"content-type": "application/json"}
    r = requests.post(url, json=data, headers=headers)
    return r

if __name__ == "__main__":

    # Setting the logging level. INFO|ERROR|DEBUG are the most common.
    logging.basicConfig(level=logging.INFO)

    args = _parse_args()

    # Reading configuration file
    output = args.output
    config = _get_release_config(args.yaml_input)
    jira = config["jira"]
    issues = config["issues"]

    jc = JiraConfig(jira)
    
    logging.info("get_title")
    # r = get_title_from_jira(jc, issues)
    r = get_summary_from_api(jc, issues)
    to_file(r.json(), output)
    
    # data_set = {"key1": [1, 2, 3], "key2": [4, 5, 6]}
    # issues_json = json.dumps(data_set)
    # to_file(issues_json, output)
    
