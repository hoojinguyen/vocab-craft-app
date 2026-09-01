#!/usr/bin/env python3
"""
reply_pr_thread.py
Replies to a specific inline review comment thread or posts an issue comment on a GitHub PR.
Ensures replies are posted directly inside the discussion thread.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.request
import urllib.error


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
    """Post payload to endpoint via gh cli if available, otherwise direct HTTPS request."""
    # Try gh api first
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

    # Direct HTTPS API
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
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        sys.stderr.write(f"HTTP Error {e.code}: {e.reason} - {error_body}\n")
        return None
    except Exception as e:
        sys.stderr.write(f"Error posting to {url}: {e}\n")
        return None


def reply_to_comment_thread(owner, repo, pr_number, comment_id, body, token=None):
    """Reply to an inline PR review comment thread."""
    endpoint = f"pulls/{pr_number}/comments/{comment_id}/replies"
    payload = {"body": body}
    return post_github_api(endpoint, payload, owner, repo, token)


def post_issue_comment(owner, repo, pr_number, body, token=None):
    """Post a top-level comment on PR."""
    endpoint = f"issues/{pr_number}/comments"
    payload = {"body": body}
    return post_github_api(endpoint, payload, owner, repo, token)


def main():
    parser = argparse.ArgumentParser(description="Reply to PR review comments on GitHub")
    parser.add_argument("--pr", type=int, required=True, help="Pull Request number")
    parser.add_argument("--comment-id", type=int, help="Comment ID to reply to (for inline thread reply)")
    parser.add_argument("--body", type=str, required=True, help="Reply text body")
    parser.add_argument("--owner", type=str, help="GitHub repository owner")
    parser.add_argument("--repo", type=str, help="GitHub repository name")
    parser.add_argument("--token", type=str, help="GitHub Personal Access Token")
    parser.add_argument("--top-level", action="store_true", help="Post as top-level PR comment instead of thread reply")
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

    if args.top_level or not args.comment_id:
        result = post_issue_comment(owner, repo, args.pr, args.body, args.token)
    else:
        result = reply_to_comment_thread(owner, repo, args.pr, args.comment_id, args.body, args.token)

    if result:
        print(f"Successfully posted reply. Comment ID: {result.get('id')}")
        print(f"URL: {result.get('html_url')}")
    else:
        sys.stderr.write("Failed to post reply.\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
