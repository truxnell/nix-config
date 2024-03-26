## Why not recurse the module folder

Imports are special in NIX and its important that they are definet at runtime for lazy evaluation - if you do optional/coded imports not everything is avaliable for evaluating.
