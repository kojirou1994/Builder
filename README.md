
## Examples

Build harfbuzz and freetype
```
build-cli build harfbuzz -l shared
build-cli build freetype --ignore-tag --with-harfbuzz -l shared --dependency-level 1 --rebuild-level package
```

## Requirements
rustup installed
pyenv with non system python

## Package name rules
1. use official git repo name

## Todo
auto generate package's dependencies/conflictions doc
