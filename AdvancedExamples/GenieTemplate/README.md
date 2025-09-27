# GenieTemplate

### A draft for a new Genie template

This template showcases
- a self-starting precompilable app
- self-hosting of Material Icons and Material Symbols of the latest version
- no core_theme (if you run into styling problems)
- dynamic layout with toolbar and drawer

The purpose of this template is to develop a new App template and perhaps a layout/template gallery. When this template proves to be reasonable stable and performant, we will think about simplifications in code style.

We are thankful for any feedback!

### Starting of the App

Inside of Julia
```julia-repl
julia> cd("path/to/GenieTemplate")
(@v1.11) pkg> activate .
julia> using GenieTemplate
```
or for measurement of startup time (displayed at the REPL)
```julia-repl
julia> using GenieTemplate; GenieTemplate.Genie.Server.openbrowser("http://localhost:8000")
```
or outside of Julia via
```sh
julia --project=path/to/GenieTemplate -e "using GenieTemplate; wait(Condition())"
```
![Docs](docs/GenieTemplate.png)

### Acknowledgement
The Layout of the app was copied with only minor changes from Quasar's [Layout Template Gallery](https://quasar.dev/layout/gallery/)

The material fonts are from [Google's icon pages](https://developers.google.com/fonts/docs/material_symbols)
