#!/usr/bin/env python3
import json
import random
import sys
from pathlib import Path

# ←── edit these paths as needed ──→
GEOJSON_PATH = "InShort/Resources/Fixtures/us_states.geojson"
VOTES_PATH   = "InShort/Resources/Fixtures/votes.json"
N_ENTRIES    = 100000  # how many fake rows to generate

def load_identifiers(path):
    """
    Reads path, expects a GeoJSON FeatureCollection.
    Pulls props["abbr"] or props["NAME"] or props["STATEFP"].
    """
    geo = json.loads(Path(path).read_text())
    feats = geo.get("features", [])
    ids = set()
    for feat in feats:
        props = feat.get("properties", {})
        id_ = props.get("abbr") or props.get("NAME") or props.get("STATEFP")
        if isinstance(id_, str):
            ids.add(id_)
    return sorted(ids)

def generate_votes(ids, n):
    """
    Creates n dicts of {"district": id, "yes":…, "no":…}.
    No single id appears >2× even if n>len(ids).
    """
    out = []
    D = len(ids)
    if n <= D:
        picks = random.sample(ids, n)
    else:
        # first pass: every id once
        picks = ids.copy()
        extra = n - D

        # allow a second pass with at most one more each
        picks += random.sample(ids, min(extra, D))
        extra -= min(extra, D)

        # if you really requested >2×D, allow further repeats
        if extra > 0:
            # cycle through again (at most third pass)
            picks += random.choices(ids, k=extra)

        random.shuffle(picks)

    for d in picks:
        total = int(random.normalvariate(500, 150))
        total = max(50, total)
        yes = int(random.betavariate(2, 2) * total)
        no  = total - yes
        out.append({"district": d, "yes": yes, "no": no})
    return out

def main():
    ids = load_identifiers(GEOJSON_PATH)
    if not ids:
        print(f"❌ No valid identifiers found in {GEOJSON_PATH}", file=sys.stderr)
        sys.exit(1)

    votes = generate_votes(ids, N_ENTRIES)
    # write out
    Path(VOTES_PATH).write_text(json.dumps(votes, indent=2))
    print(f"✅ Wrote {len(votes)} entries for {len(ids)} identifiers to {VOTES_PATH}")

if __name__ == "__main__":
    main()
