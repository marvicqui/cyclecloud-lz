# 90-second local demonstration

1. State the boundary: infrastructure scaffold, no deployed cluster.
2. Run `python3 examples/offline_demo.py`: dev and prod each show three synthetic
   subnets, with MySQL on its own `/26` subnet.
3. Show `main.bicep` → `rg.lz.bicep` → `modules/network.bicep`; explain why the
   MySQL name must match both the delegation and the consumed subnet ID.
4. Run the 20 network/compiled-graph tests and compile `main.bicep`.
   Show the private DNS link and MySQL dependencies; demonstrate that a public
   database mutation is rejected by the compiled contract check.
5. Open `docs/readiness.md` and explain what compilation cannot prove.

No cloud credentials, Azure resource operations or measured performance claims.
