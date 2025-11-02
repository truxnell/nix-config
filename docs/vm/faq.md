## Why not recurse the module folder

Imports are special in NIX and its important that they are defined at runtime for lazy evaluation - if you do optional/coded imports not everything is available for evaluating.
