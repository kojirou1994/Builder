# Builder

A description of this package.

## Examples

Build harfbuzz and freetype
```
build-cli build harfbuzz -l shared
build-cli build freetype --ignore-tag --with-harfbuzz -l shared --dependency-level 1 --rebuild-level package
```
