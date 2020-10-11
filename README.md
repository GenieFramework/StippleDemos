# Demos for Stipple

This repository includes a collection of Stipple demo application.

## Set up the required packages

1. Download or clone demos repo

2. Open a Julia REPL (Start Julia from Start menu, app launcher, terminal, Applications folder, etc)

3. `cd` to the demos folder. Ex: `julia> cd("<path_to_demos_folder_>")

4. Go into package management mode and run `pkg> activate .` and `pkg> instantiate` (type `julia> ]` to enter `pkg` mode)

## Instructions to run the demos

### In a Julia REPL

1. Open a Julia REPL (Start Julia from Start menu, app launcher, terminal, Applications folder, etc)

2. `cd` to the demos folder. Ex: `julia> cd("<path_to_demos_folder_>")

3. activate the environment - press `]` to go into `pkg> ` mode and run

```julia
pkg> activate .
```

then exit `pkg> ` mode (via Ctrl+C or backspace until the cursor changes from `pkg> ` to `julia> `)

5. run

```julia
julia> using Revise
julia> includet("GermanCredits.jl") # swap "GermanCredits.jl" with any other demo
julia> up(rand((8000:9000)), open_browser=true)
```

### At the terminal

In order to run the demos in the terminal you need to have `julia` in your `PATH` or pass the full path to the `julia` binary.

1. `cd` into the demos folder

2. run `$ julia run.jl <name_of_file>`. For example `$ julia run.jl GermanCredits.jl`

### In Visual Studio Code

In order to run the demos in Visual Studio Code you will need to install the `Julia` (Julia Language Support) extension.

1. Open demos folder in Visual Studio Code

2. Start a Julia REPL. Ex: Shift+Ctrl+P to show the command palette then `Julia: Start REPL`

3. In the REPL run:

```julia
julia> using Revise
julia> includet("GermanCredits.jl") # swap "GermanCredits.jl" with any other demo
julia> up(rand((8000:9000)), open_browser=true)
```

## Hack on

The above commands should start the Stipple demo application on a random port between 8000 and 9000 and automatically open a browser window with the app. While the app is running you can edit the source code and the app will automatically reload the window to show you the changes.
