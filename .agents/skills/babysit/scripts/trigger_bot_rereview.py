#!/usr/bin/env python3
"""
trigger_bot_rereview.py
Triggers re-review by posting bot-specific slash commands or requesting review from AI agents.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.request
import urllib.error

DEFAULT_BOT_COMMANDS = {
    "coderabbitai": "@coderabbitai full review",
    "coderabbitai[bot]": "@coderabbitai full review",
    "coderabbit": "@coderabbitai full review",
    "gemini": "@gemini-code-assist review",
    "gemini-code-assist[bot]": "@gemini-code-assist review",
    "copilot": "@github-copilot review",
    "greptile": "@greptile review",
    "greptile-ai[bot]": "@greptile review",
    "qodo": "@qodo-cover-agent review",
    "sourcery": "@sourcery-ai review"
}


def run_command(cmd, cwd=None):
    """Run shell command and return stdout string."""
    try:
        res = subprocess.run(
            cmd,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return res.stdout.strip()
    except subprocess.CalledProcessError:
        return None


def get_git_remote_info():
    """Extract owner and repo from git remote origin."""
    remote_url = run_command(["git", "config", "--get", "remote.origin.url"])
    if not remote_url:
        return None, None
    
    match = re.search(r"github\.com[:/]([^/]+)/([^/.]+)(?:\.git)?", remote_url)
    if match:
        return match.group(1), match.group(2)
    return None, None


def post_github_api(endpoint, payload, owner, repo, token=None):
    """Post payload to endpoint via gh cli or direct API."""
    json_payload = json.dumps(payload)
    gh_cmd = [
        "gh", "api",
        "--method", "POST",
        f"repos/{owner}/{repo}/{endpoint}",
        "--input", "-"
    ]
    try:
        res = subprocess.run(
            gh_cmd,
            input=json_payload,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return json.loads(res.stdout.strip())
    except Exception:
        pass

    headers = {
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json",
        "User-Agent": "Antigravity-Babysit-Skill"
    }
    if token:
        headers["Authorization"] = f"token {token}"
    elif "GITHUB_TOKEN" in os.environ:
        headers["Authorization"] = f"token {os.environ['GITHUB_TOKEN']}"
    elif "GH_TOKEN" in os.environ:
        headers["Authorization"] = f"token {os.environ['GH_TOKEN']}"

    url = f"https://api.github.com/repos/{owner}/{repo}/{endpoint}"
    try:
        req = urllib.request.Request(url, data=json_payload.encode("utf-8"), headers=headers, method="POST")
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        sys.stderr.write(f"Error calling {url}: {e}\n")
        return None


def request_reviewers(owner, repo, pr_number, reviewers, token=None):
    """Request review from specific reviewers."""
    endpoint = f"pulls/{pr_number}/requested_reviewers"
    payload = {"reviewers": reviewers}
    return post_github_api(endpoint, payload, owner, repo, token)


def post_comment(owner, repo, pr_number, body, token=None):
    """Post comment on PR issue."""
    endpoint = f"issues/{pr_number}/comments"
    payload = {"body": body}
    return post_github_api(endpoint, payload, owner, repo, token)


def main():
    parser = argparse.ArgumentParser(description="Trigger AI Reviewer re-review on PR")
    parser.add_argument("--pr", type=int, required=True, help="Pull Request number")
    parser.add_argument("--bot", type=str, help="Bot name (e.g. coderabbitai, gemini)")
    parser.add_argument("--command", type=str, help="Custom command to post (e.g. '@coderabbitai full review')")
    parser.add_argument("--request-review", action="store_true", help="Also request review via GitHub API")
    parser.add_argument("--owner", type=str, help="GitHub repository owner")
    parser.add_argument("--repo", type=str, help="GitHub repository name")
    parser.add_argument("--token", type=str, help="GitHub Personal Access Token")
    args = parser.parse_args()

    owner = args.owner
    repo = args.repo
    if not owner or not repo:
        detected_owner, detected_repo = get_git_remote_info()
        owner = owner or detected_owner
        repo = repo or detected_repo

    if not owner or not repo:
        sys.stderr.write("Error: Could not detect repository owner and name. Specify --owner and --repo.\n")
        sys.exit(1)

    command_to_post = args.command
    if not command_to_post and args.bot:
        bot_key = args.bot.lower()
        command_to_post = DEFAULT_BOT_COMMANDS.get(bot_key, f"@{args.bot} please re-review this PR.")

    if command_to_post:
        res = post_comment(owner, repo, args.pr, command_to_post, args.token)
        if res:
            print(f"Trigger command posted: '{command_to_post}' (Comment ID: {res.get('id')})")
        else:
            sys.stderr.write(f"Failed to post trigger command: '{command_to_post}'\n")

    if args.request_review and args.bot:
        # Clean [bot] suffix for requested_reviewers if needed
        reviewer_name = args.bot.replace("[bot]", "")
        res_req = request_reviewers(owner, repo, args.pr, [reviewer_name], args.token)
        if res_req:
            print(f"Requested re-review from {reviewer_name}")


if __name__ == "__main__":
    main()
