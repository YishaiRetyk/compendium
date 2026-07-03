# src/compendium/brownfield.py  (STUB — Phase 24; filled in Phase 25 MIG-01)
import sys

NOT_IMPLEMENTED_EXIT = 70  # EX_SOFTWARE sentinel — distinct from every real tool code (0/1/2/3)


def main(argv=None):
    # Phase 24: not yet ported. The bin/ shim still runs its bash body;
    # this stub exists only so the entry point resolves at install time.
    # It exits NONZERO so an accidentally-activated unfinished module fails loudly
    # (REVIEWS MEDIUM: a stub that exits 0 could mask a missed Phase-25 port).
    print("compendium.brownfield: not yet implemented (Phase 25)", file=sys.stderr)
    return NOT_IMPLEMENTED_EXIT


if __name__ == "__main__":          # enables `python3 -m compendium.brownfield`
    sys.exit(main(sys.argv[1:]))
