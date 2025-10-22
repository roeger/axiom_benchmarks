#! /usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
from collections import defaultdict
import json
import os


HELP = "Convert a suite name to a list of domains."

_PREFIX = "suite_"


def suite_no_derived_predicates():
    return['acc-cc1-ghosh-etal',
           'doorexample-broken-ghosh-etal-noaxioms',
           'doorexample-fixed-ghosh-etal-noaxioms',
           'grid',
           'grid-cc1-ghosh-etal',
           'miconic',
           'optical-telegraphs-compiled',
           'philosophers-compiled',
           'psr-middle-compiled',
           'sokoban-opt08-strips',
           'sokoban-opt08-strips-nocost',
           ]


def suite_negated_occurrences():
    return ['acc-cc2-ghosh-etal',
            'blocks-axioms',
            'cats-horndl',
            'doorexample-broken-ghosh-etal',
            'doorexample-fixed-ghosh-etal',
            'elevator-horndl',
            'grid-cc2-ghosh-etal',
            'mincut',
            'muddy-child-kg',
            'muddy-children-kg',
            'optimal-telegraphs',
            'philosophers',
            'queens-horndl',
            'snowman-reachability',
            'social-planning',
            'sokoban-axioms',
            'taskassign-horndl',
            'trapping_game',
            'wordrooms-kg',
            ]


def suite_negated_occurrences_and_function_free():
    return ['acc-cc2-ghosh-etal',
            'blocks-axioms',
            'cats-horndl',
            'doorexample-broken-ghosh-etal',
            'doorexample-fixed-ghosh-etal',
            'elevator-horndl',
            'grid-cc2-ghosh-etal',
            'muddy-child-kg',
            'muddy-children-kg',
            'optimal-telegraphs',
            'philosophers',
            'queens-horndl',
            'snowman-reachability',
            'social-planning',
            'sokoban-axioms',
            'taskassign-horndl',
            'trapping_game',
            'wordrooms-kg',
            ]


def suite_only_positive_occurrences():
    return ['collab-and-comm-kg',
            'drones-horndl',
            'ged1',
            'ged1c',
            'grid-axioms',
            'miconic-axioms',
            'psr-large',
            'psr-middle',
            'psr-middle-noce',
            'robot-horndl',
            'robotConj-horndl',
            'sum-kg',
            'tpsa-horndl',
            'vta-horndl',
            'vta-roles-horndl',
            ]


def suite_derived_predicates():
    return sorted(suite_negated_occurrences() +
                  suite_only_positive_occurrences())


def suite_all():
    return sorted(
        suite_derived_predicates() + suite_no_derived_predicates())


def get_suite_names():
    return [
        name[len(_PREFIX):] for name in sorted(globals().keys())
        if name.startswith(_PREFIX)]


def get_suite(name):
    suite_func = globals()[_PREFIX + name]
    return suite_func()


def _parse_args():
    parser = argparse.ArgumentParser(description=HELP)
    parser.add_argument("suite", choices=get_suite_names(), help="suite name")
    return parser.parse_args()


def main():
    args = _parse_args()
    suite = get_suite(args.suite)
    # Use json module to print double-quote strings.
    #print(json.dumps(suite))
    for d in suite:
        print(d)


if __name__ == "__main__":
    main()
