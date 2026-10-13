#!/usr/bin/env python3
"""
Read-only diagnostic: lists every sport the 1xBet partner API reports via
its own "Справочник спортов" (sports directory) endpoint --
GET /datafeed/directories/api/v2/sports -- the same endpoint the project
owner originally used to confirm sportId 1=Football, 2=Ice Hockey,
3=Basketball, 4=Tennis, 5=Baseball, 6=Volleyball, 7=Rugby (see
scripts/onexbet_odds.py's module docstring and SPORTS comment).

This script changes nothing on the site -- it only prints the API's answer
so we can see, with certainty instead of a guess, whether it lists a real
esports/cybersport category (distinct from the virtual/simulated games the
odds script already filters out) before deciding whether to build anything
for it.

Run via the "List 1xBet sports (diagnostic)" GitHub Actions workflow --
it reuses the same repository secrets as the regular odds-refresh job.
"""
import os
import sys
import json

sys.path.insert(0, os.path.join(os.path.dirname(__file__)))
import onexbet_odds as base  # reuse get_token/api_get/OnexbetError as-is

import requests


def main():
    client_id = os.environ.get("ONEXBET_CLIENT_ID")
    client_secret = os.environ.get("ONEXBET_CLIENT_SECRET")
    ref = os.environ.get("ONEXBET_REF")
    gr = os.environ.get("ONEXBET_GR")

    missing = [n for n, v in [("ONEXBET_CLIENT_ID", client_id), ("ONEXBET_CLIENT_SECRET", client_secret), ("ONEXBET_REF", ref)] if not v]
    if missing:
        sys.exit(f"Missing required environment variable(s): {', '.join(missing)}")

    session = requests.Session()
    token = base.get_token(session, client_id, client_secret)

    params = {"ref": ref}
    if gr:
        params["gr"] = gr

    data = base.api_get(session, token, "/datafeed/directories/api/v2/sports", params)

    print("=== raw response ===")
    print(json.dumps(data, ensure_ascii=False, indent=2)[:8000])
    print()

    # try to pull out a flat id/name list regardless of the exact response
    # shape (list at top level, or nested under a common key)
    items = data if isinstance(data, list) else (
        data.get("items") or data.get("value") or data.get("result") or data.get("data") or []
    )
    print("=== id / name pairs ===")
    for item in items:
        if isinstance(item, dict):
            sid = item.get("id") or item.get("Id") or item.get("sportId")
            name = item.get("name") or item.get("Name")
            print(f"  {sid}: {name}")

    print()
    print("=== anything mentioning esport / cyber / counter-strike / dota / league of legends / valorant ===")
    blob = json.dumps(data, ensure_ascii=False).lower()
    for kw in ["esport", "cyber", "counter-strike", "cs2", "dota", "league of legends", "valorant", "overwatch"]:
        print(f"  {kw!r}: {'FOUND' if kw in blob else 'not found'}")


if __name__ == "__main__":
    main()
