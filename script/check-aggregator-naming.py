#!/usr/bin/env python3
"""Where an aggregator lives says which layer it is, and its name agrees.

    | layer         | lives in                 | name                |
    |---------------|--------------------------|---------------------|
    | abstract base | src/aggregators/         | never ends _<net>   |
    | formula       | src/aggregators/<net>/   | never ends _<net>   |
    | deployable    | src/<net>/               | always ends _<net>  |

These are READABILITY rules. They are not protection against two contracts sharing a name: solidity
resolves imports by path, forge writes each artifact to a distinct path, and `forge inspect` and
`vm.getCode` refuse a bare ambiguous name rather than guessing. What they buy is that depth alone
places a file, from either direction - abstract at the top, concrete under a network - and that a
deployable announces its chain. The second half is the one that matters in practice: `base` is both a
chain and the English word for what an abstract base is, and seven generic bases were filed inside
`src/aggregators/base/` for exactly that reason.

Whether a contract is abstract comes from the compiler's own AST rather than from matching text, so a
comment or a string containing "abstract contract" cannot change the answer, and neither can
formatting. That means a build must have run; this reads what it produced.

Prints nothing when every rule holds - `wtf` is invoked with --output-means-failure, so output IS the
verdict.
"""

import json
import sys
from collections import defaultdict
from pathlib import Path

SRC = Path("src")
AGGREGATORS = SRC / "aggregators"


def declarations(build_info_dir: Path) -> dict[str, list[tuple[str, bool, str]]]:
    """Every contract the build declared, as {source path: [(name, is_abstract, kind), ...]}.

    Sources that no longer exist are dropped: build-info accumulates across builds and is never
    pruned, so a file that has since moved is still described by an older entry and would be judged
    at a path it left.
    """
    found: dict[str, list[tuple[str, bool, str]]] = defaultdict(list)
    for info in sorted(build_info_dir.glob("*.json")):
        try:
            sources = json.loads(info.read_text()).get("output", {}).get("sources", {})
        except json.JSONDecodeError:
            continue
        for path, source in sources.items():
            if not path.startswith("src/") or not Path(path).exists():
                continue
            for node in (source.get("ast") or {}).get("nodes", []):
                if node.get("nodeType") != "ContractDefinition":
                    continue
                entry = (
                    node["name"],
                    bool(node.get("abstract")),
                    node.get("contractKind"),
                )
                if entry not in found[path]:
                    found[path].append(entry)
    return found


def networks(declared: dict[str, list[tuple[str, bool, str]]]) -> set[str]:
    """Every network, read from the tree twice over rather than written down.

    By POSITION - a directory under src/aggregators/ is where a network's formulas live. And by
    CONTENT - a directory under src/ holding a contract that ends in the directory's own name, which
    nothing but a deployable does. The second is not redundant: a network that extends the abstract
    bases directly has no formulas and so no src/aggregators/<net>/ to be found in, and monad is
    exactly that. Deriving from position alone would let its deployables go unchecked.
    """
    found = (
        {d.name for d in AGGREGATORS.iterdir() if d.is_dir()}
        if AGGREGATORS.is_dir()
        else set()
    )
    for directory in sorted(
        d for d in SRC.iterdir() if d.is_dir() and d != AGGREGATORS
    ):
        for path, contracts in declared.items():
            if Path(path).parent == directory and any(
                n.endswith(f"_{directory.name}") for n, _, _ in contracts
            ):
                found.add(directory.name)
                break
    return found


def violations(
    declared: dict[str, list[tuple[str, bool, str]]], nets: set[str]
) -> list[str]:
    def ends_with_a_network(name: str) -> str | None:
        return next((n for n in nets if name.endswith(f"_{n}")), None)

    found = []
    for path in sorted(declared):
        parent = Path(path).parent
        stem = Path(path).stem
        contracts = declared[path]

        if contracts and not any(name == stem for name, _, _ in contracts):
            found.append(
                f"{path} declares no {stem}: a file is named for what it declares"
            )

        for name, is_abstract, kind in contracts:
            network = ends_with_a_network(name)
            if parent == AGGREGATORS:
                if kind == "contract" and not is_abstract:
                    found.append(
                        f"{path}: {name} is concrete, so it belongs under src/<network-of-its-feeds>/"
                    )
                if network:
                    found.append(
                        f"{path}: {name} ends _{network}, which is a deployable's mark"
                    )
            elif parent.parent == AGGREGATORS and parent.name in nets:
                if is_abstract:
                    found.append(
                        f"{path}: {name} is abstract, so it belongs at src/aggregators/"
                    )
                if network:
                    found.append(
                        f"{path}: {name} ends _{network}, so it belongs in src/{network}/"
                    )
            elif parent.name in nets and parent.parent == SRC:
                if not name.endswith(f"_{parent.name}"):
                    found.append(f"{path}: {name} does not end _{parent.name}")
    return found


def main() -> int:
    build_info = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("out/build-info")
    if not build_info.is_dir() or not any(build_info.glob("*.json")):
        # Never silently pass: with nothing to read, every rule holds vacuously.
        print(
            f"no build-info in {build_info} - run `forge build --build-info` first",
            file=sys.stderr,
        )
        return 1

    declared = declarations(build_info)
    if not declared:
        print(
            f"{build_info} describes no src/ contract - nothing was checked",
            file=sys.stderr,
        )
        return 1

    found = violations(declared, networks(declared))
    for line in found:
        print(line)
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
