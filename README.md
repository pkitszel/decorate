# Usage

## Add logging code
`./decorate-driver-code.sh path1.c [path-2.c ...]`

## Remove logging code
`./undecorate-driver-code.sh path1.c [path-2.c ...]`

### Misc
stack-tip.cpp could be used to display just current stack content:

`make stack-tip; dmesg | ./stack-tip`
