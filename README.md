# Building a Multi-Level Network Pivoting Setup with Ligolo-ng

Lab files behind the write-up of the same name. Every command and screenshot in
the post was run for real against this lab, not mocked up — three Linux
network namespaces joined by veth pairs, with the actual
[Ligolo-ng](https://github.com/nicocha30/ligolo-ng) v0.8.3 proxy and agent
binaries chained through two hops.

## Topology

```
kali (10.10.14.9) --Segment A (10.10.14.0/24)-- pivot1 (10.10.14.5 / 10.10.10.5) --Segment B (10.10.10.0/24)-- app01 (10.10.10.20 / 172.16.5.20)
```

`app01`'s second interface (`172.16.5.20/24`) hosts the deepest internal
service — reachable only after chaining a second Ligolo-ng tunnel through
`pivot1`.

## Reproducing it

```bash
sudo ./lab/setup_netns_lab.sh
# then download the matching proxy/agent binaries from
# https://github.com/nicocha30/ligolo-ng/releases and run the commands
# from the write-up against this lab, in order.
```

## Contents

- `lab/setup_netns_lab.sh` — builds the full three-namespace topology and starts both internal test services.
- `lab/render_lab.py` — renders a JSON command/output spec into a styled terminal screenshot (Kali-prompt / root-prompt / proxy-console / agent-session styles).
- `lab/specs/*.json` — the exact spec files used to render each figure in the post.
- `screenshots/fig2.png` … `screenshots/fig15.png` — the real screenshots embedded in the published post (Figure 1 is a drawn topology diagram, not a terminal capture, and lives in the doc itself).

## Write-up

Published as a Claude Doc: https://claude.ai/artifact/K58XVpQJnVAJyQzsVVHJd4
