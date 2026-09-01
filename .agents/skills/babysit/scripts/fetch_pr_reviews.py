#!/usr/bin/env python3
"""
fetch_pr_reviews.py
Fetches PR reviews, inline comments, and top-level comments from GitHub.
Identifies AI reviewer bot comments, groups them into threads, and determines resolution state.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import urllib.request
import urllib.error

KNOWN_AI_BOT_PATTERNS = [
    r"coderabbit.*",
    r"gemini.*",
    r"copilot.*",
    r"greptile.*",
    r"qodo.*",
    r"codeclimate.*",
    r"sonar.*",
    r"sourcery.*",
    r"deepcode.*",
    r".*\[bot\]$",
    r".*-bot$",
    r"ai-reviewer.*"
]


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
    
    # Handle SSH (git@github.com:owner/repo.git) and HTTPS (https://github.com/owner/repo.git)
    match = re.search(r"github\.com[:/]([^/]+)/([^/.]+)(?:\.git)?", remote_url)
    if match:
        return match.group(1), match.group(2)
    return None, None


def get_current_branch():
    """Get current git branch."""
    return run_command(["git", "rev-parse", "--abbrev-ref", "HEAD"])


def get_pr_for_branch(owner, repo, branch, token=None):
    """Find open PR number for branch using gh cli or GitHub API."""
    # Try gh cli first
    gh_out = run_command(["gh", "pr", "view", "--json", "number,headRefName", "-q", ".number"])
    if gh_out and gh_out.isdigit():
        return int(gh_out)
    
    # API fallback
    headers = {"Accept": "application/vnd.github.v3+json", "User-Agent": "Antigravity-Babysit-Skill"}
    if token:
        headers["Authorization"] = f"token {token}"
    elif "GITHUB_TOKEN" in os.environ:
        headers["Authorization"] = f"token {os.environ['GITHUB_TOKEN']}"
    elif "GH_TOKEN" in os.environ:
        headers["Authorization"] = f"token {os.environ['GH_TOKEN']}"
    
    url = f"https://api.github.com/repos/{owner}/{repo}/pulls?head={owner}:{branch}&state=open"
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if data and len(data) > 0:
                return data[0]["number"]
    except Exception:
        pass
    return None


def is_ai_bot(user_login):
    """Check if user login matches known AI bot patterns."""
    if not user_login:
        return False
    login_lower = user_login.lower()
    for pattern in KNOWN_AI_BOT_PATTERNS:
        if re.search(pattern, login_lower):
            return True
    return False


def fetch_github_api(endpoint, owner, repo, token=None, paginate=False):
    """Fetch endpoint via gh cli if available, otherwise direct HTTPS request with pagination support."""
    # Try gh api first
    gh_cmd = ["gh", "api"]
    if paginate:
        gh_cmd.append("--paginate")
    gh_cmd.append(f"repos/{owner}/{repo}/{endpoint}")
    gh_res = run_command(gh_cmd)
    if gh_res:
        try:
            return json.loads(gh_res)
        except json.JSONDecodeError:
            pass

    # Direct HTTPS API
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "Antigravity-Babysit-Skill"
    }
    if token:
        headers["Authorization"] = f"token {token}"
    elif "GITHUB_TOKEN" in os.environ:
        headers["Authorization"] = f"token {os.environ['GITHUB_TOKEN']}"
    elif "GH_TOKEN" in os.environ:
        headers["Authorization"] = f"token {os.environ['GH_TOKEN']}"

    url = f"https://api.github.com/repos/{owner}/{repo}/{endpoint}"
    all_items = []
    while url:
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read().decode("utf-8"))
                if not paginate or not isinstance(data, list):
                    return data
                all_items.extend(data)

                # Check Link header for next page
                link_header = resp.headers.get("Link", "")
                next_url = None
                if link_header:
                    links = link_header.split(",")
                    for link in links:
                        parts = link.split(";")
                        if len(parts) >= 2 and 'rel="next"' in parts[1]:
                            next_url = parts[0].strip().strip("<>")
                            break
                url = next_url
        except urllib.error.HTTPError as e:
            sys.stderr.write(f"HTTP Error {e.code}: {e.reason} for {url}\n")
            return None
        except Exception as e:
            sys.stderr.write(f"Error fetching {url}: {e}\n")
            return None
    return all_items


def fetch_all_pr_feedback(owner, repo, pr_number, token=None, custom_bot_list=None):
    """Aggregate reviews, review comments, and issue comments for a PR."""
    pr_data = fetch_github_api(f"pulls/{pr_number}", owner, repo, token, paginate=False)
    reviews = fetch_github_api(f"pulls/{pr_number}/reviews?per_page=100", owner, repo, token, paginate=True) or []
    review_comments = fetch_github_api(f"pulls/{pr_number}/comments?per_page=100", owner, repo, token, paginate=True) or []
    issue_comments = fetch_github_api(f"issues/{pr_number}/comments?per_page=100", owner, repo, token, paginate=True) or []

    # Map bots
    def check_bot(login):
        if custom_bot_list and login in custom_bot_list:
            return True
        return is_ai_bot(login)

    # Group inline comments into threads
    threads = {}
    for c in review_comments:
        c_id = c.get("id")
        reply_to = c.get("in_reply_to_id")
        thread_root_id = reply_to if reply_to else c_id
        
        if thread_root_id not in threads:
            threads[thread_root_id] = {
                "root_id": thread_root_id,
                "path": c.get("path"),
                "line": c.get("line") or c.get("original_line"),
                "commit_id": c.get("commit_id"),
                "diff_hunk": c.get("diff_hunk"),
                "comments": []
            }
        threads[thread_root_id]["comments"].append({
            "id": c_id,
            "user": c.get("user", {}).get("login"),
            "is_bot": check_bot(c.get("user", {}).get("login")),
            "body": c.get("body"),
            "created_at": c.get("created_at"),
            "updated_at": c.get("updated_at"),
            "html_url": c.get("html_url")
        })

    # Filter threads that have active AI bot comments and no human resolution/reply
    ai_threads = []
    for root_id, thread in threads.items():
        bot_comments = [c for c in thread["comments"] if c["is_bot"]]
        if not bot_comments:
            continue
        
        # Check if the latest comment in thread is from bot (unresolved/unreplied)
        latest_comment = thread["comments"][-1]
        is_pending = latest_comment["is_bot"]

        ai_threads.append({
            "root_id": root_id,
            "path": thread["path"],
            "line": thread["line"],
            "diff_hunk": thread["diff_hunk"],
            "total_comments_in_thread": len(thread["comments"]),
            "latest_comment_author": latest_comment["user"],
            "is_pending_reply": is_pending,
            "bot_comments": bot_comments,
            "all_comments": thread["comments"]
        })

    # Filter top-level bot reviews and comments
    ai_reviews = []
    for r in reviews:
        reviewer = r.get("user", {}).get("login")
        if check_bot(reviewer):
            ai_reviews.append({
                "id": r.get("id"),
                "user": reviewer,
                "state": r.get("state"),  # APPROVED, CHANGES_REQUESTED, COMMENTED, DISMISSED
                "body": r.get("body"),
                "submitted_at": r.get("submitted_at"),
                "html_url": r.get("html_url")
            })

    ai_issue_comments = []
    for ic in issue_comments:
        author = ic.get("user", {}).get("login")
        if check_bot(author):
            ai_issue_comments.append({
                "id": ic.get("id"),
                "user": author,
                "body": ic.get("body"),
                "created_at": ic.get("created_at"),
                "html_url": ic.get("html_url")
            })

    # Summary states
    all_ai_reviewers = list(set([r["user"] for r in ai_reviews] + [c["latest_comment_author"] for c in ai_threads if c["is_pending_reply"]]))
    approved_bots = [r["user"] for r in ai_reviews if r["state"] == "APPROVED"]
    changes_requested_bots = [r["user"] for r in ai_reviews if r["state"] == "CHANGES_REQUESTED"]

    return {
        "pr_number": pr_number,
        "title": pr_data.get("title") if pr_data else None,
        "state": pr_data.get("state") if pr_data else None,
        "head_branch": pr_data.get("head", {}).get("ref") if pr_data else None,
        "base_branch": pr_data.get("base", {}).get("ref") if pr_data else None,
        "ai_reviewers": all_ai_reviewers,
        "approved_bots": approved_bots,
        "changes_requested_bots": changes_requested_bots,
        "pending_threads_count": len([t for t in ai_threads if t["is_pending_reply"]]),
        "total_ai_threads_count": len(ai_threads),
        "ai_threads": ai_threads,
        "ai_reviews": ai_reviews,
        "ai_issue_comments": ai_issue_comments
    }


def main():
    parser = argparse.ArgumentParser(description="Fetch PR review comments from AI agents")
    parser.add_argument("--pr", type=int, help="Pull Request number")
    parser.add_argument("--owner", type=str, help="GitHub repository owner")
    parser.add_argument("--repo", type=str, help="GitHub repository name")
    parser.add_argument("--token", type=str, help="GitHub Personal Access Token")
    parser.add_argument("--bots", nargs="+", help="Explicit list of bot usernames")
    parser.add_argument("--json", action="store_true", help="Output raw JSON")
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

    pr_number = args.pr
    if not pr_number:
        branch = get_current_branch()
        pr_number = get_pr_for_branch(owner, repo, branch, args.token)

    if not pr_number:
        sys.stderr.write("Error: Could not detect PR number. Specify --pr <number>.\n")
        sys.exit(1)

    result = fetch_all_pr_feedback(owner, repo, pr_number, args.token, args.bots)

    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
