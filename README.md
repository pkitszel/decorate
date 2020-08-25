# Usage

## Add logging code
`./c4-decorate-driver-code.sh sciezka-do-pliku.c [sciezka-2.c ...]`
## Remove logging code
`./c4-undecorate-driver-code.sh sciezka-do-pliku.c [sciezka-2.c ...]`

### Misc
stack-tip.cpp could be used to display just current stack content:

`make stack-tip; dmesg | ./stack-tip`
