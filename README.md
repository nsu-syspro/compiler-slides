# Presentations for NSU Sys.Pro course "Compiler implementation"

Rendered presentations are located in directory [publish](publish):

- Course introduction ([pdf](publish/intro.pdf?raw=true), [md](src/intro.md))

## Building

Following command builds presentations into `.pdf`:

```
make
```

## Publishing

To "publish" the final `.pdf` you can use the following command which builds and copies `src/*.pdf` into `publish/*.pdf`
which can then be committed to the repo:

```
make publish
```
