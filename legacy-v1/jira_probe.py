#!/usr/bin/env python3
"""Probe Jira REST API to validate auth, discover epic-related field IDs, and confirm project."""

import base64
import json
import os
import sys

import requests

TIMEOUT = 15


def get_env(name: str) -> str:
    val = os.environ.get(name, "").strip()
    if not val:
        print(f"ERROR: environment variable {name} is not set or empty")
        sys.exit(1)
    return val


def build_auth_header(email: str, token: str) -> dict:
    cred = base64.b64encode(f"{email}:{token}".encode()).decode()
    return {
        "Authorization": f"Basic {cred}",
        "Accept": "application/json",
    }


def api_get(domain: str, path: str, headers: dict) -> dict:
    url = f"https://{domain}{path}"
    resp = requests.get(url, headers=headers, timeout=TIMEOUT)
    if not resp.ok:
        print(f"ERROR: {resp.status_code} from {path}: {resp.text[:300]}")
        sys.exit(1)
    return resp.json()


def main() -> None:
    email = get_env("JIRA_EMAIL")
    token = get_env("JIRA_API_TOKEN")
    domain = get_env("JIRA_DOMAIN")
    project_key = get_env("JIRA_PROJECT_KEY")

    headers = build_auth_header(email, token)

    # --- 1. Validate auth ---
    print("── Validating authentication ──")
    me = api_get(domain, "/rest/api/3/myself", headers)
    display_name = me.get("displayName", "unknown")
    account_id = me.get("accountId", "unknown")
    print(f"  User:       {display_name}")
    print(f"  Account ID: {account_id}")

    # --- 2. Discover fields ---
    print("\n── Discovering fields ──")
    fields = api_get(domain, "/rest/api/3/field", headers)

    epic_name_id = None
    epic_link_id = None
    parent_link_id = None

    # Normalised names we look for
    epic_name_candidates = {"epic name"}
    epic_link_candidates = {"epic link"}
    parent_link_candidates = {"parent link", "parent"}

    for f in fields:
        name_lower = (f.get("name") or "").lower().strip()
        fid = f.get("id", "")
        schema = f.get("schema", {})
        custom_type = schema.get("custom", "")

        # Epic Name – often customfield_10011 / com.pyxis.greenhopper.jira:gh-epic-label
        if name_lower in epic_name_candidates or custom_type == "com.pyxis.greenhopper.jira:gh-epic-label":
            epic_name_id = fid
            print(f"  Epic Name field:   {fid}  (name=\"{f.get('name')}\")")

        # Epic Link (classic company-managed) – com.pyxis.greenhopper.jira:gh-epic-link
        if name_lower in epic_link_candidates or custom_type == "com.pyxis.greenhopper.jira:gh-epic-link":
            epic_link_id = fid
            print(f"  Epic Link field:   {fid}  (name=\"{f.get('name')}\")")

        # Parent Link (next-gen / team-managed) – com.atlassian.jpo:jpo-custom-field.parent
        if (
            name_lower in parent_link_candidates
            or "parent" in custom_type.lower()
            or custom_type == "com.atlassian.jpo:jpo-custom-field.parent"
        ):
            parent_link_id = fid
            print(f"  Parent Link field: {fid}  (name=\"{f.get('name')}\", custom=\"{custom_type}\")")

    if not epic_name_id:
        print("  WARNING: Epic Name field not found – epics may use the built-in Summary instead")
    if not epic_link_id and not parent_link_id:
        print("  WARNING: Neither Epic Link nor Parent Link field found – epic hierarchy may use the native 'parent' key")

    # --- 3. Confirm project ---
    print(f"\n── Confirming project {project_key} ──")
    project = api_get(domain, f"/rest/api/3/project/{project_key}", headers)
    print(f"  Project: {project.get('name')} ({project.get('key')})")
    print(f"  Type:    {project.get('projectTypeKey', 'unknown')}")
    print(f"  Style:   {project.get('style', 'unknown')}")

    # --- 4. Write field map ---
    field_map = {
        "domain": domain,
        "project_key": project_key,
        "project_name": project.get("name"),
        "project_style": project.get("style", "unknown"),
        "user_display_name": display_name,
        "user_account_id": account_id,
        "epic_name_field_id": epic_name_id,
        "epic_link_field_id": epic_link_id,
        "parent_link_field_id": parent_link_id,
    }

    out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "jira_field_map.json")
    with open(out_path, "w") as fh:
        json.dump(field_map, fh, indent=2)
    print(f"\n── Saved field map to {out_path} ──")

    # --- 5. Final validation ---
    missing = []
    if not epic_name_id:
        missing.append("epic_name_field_id")
    if not epic_link_id and not parent_link_id:
        missing.append("epic_link_field_id or parent_link_field_id")

    if missing:
        print(f"\nWARNING: could not resolve: {', '.join(missing)}")
        print("The field map was still written – review and adjust manually if needed.")
        sys.exit(1)

    print("\nAll checks passed ✓")


if __name__ == "__main__":
    main()
