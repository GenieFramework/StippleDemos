# Demo for downloading or copying data from a DataTable
# decimal separator can be chosen
# decimal separators in headers can be converted

# This demo also shows correct placement of customer css in case that some
# property of stipplecore.css shall be overwritten and 
# correct placement of other css or js references

# Two methods of triggering downloads are shown;
# a simple one that calls an ad-hoc js function on the client and
# an advanced one that installs a listener that calls pushDonwload upon change of
# downloadtext and uninstalls itself.

using Stipple, StippleUI
using Colors

import StippleUI.table

function add_css(css::Function; update = true)
    update && deleteat!(Stipple.Layout.THEMES, nameof.(Stipple.Layout.THEMES) .== nameof(css)) 
    push!(Stipple.Layout.THEMES, css)
end

function js_requestpushdownload()
    # java script functions to facilitate the download of simulation data from front-end to local storage
    # add to your model the following Reactive components:
    #     download::R{Bool} = false
    #     downloadfilename::R{String} = "download.txt"
    #     downloadtext::R{String} = ""
    raw"""
    requestDownload: function(what = true) {
        this.downloadtext = '';
        this.download = what;
        this.unwatch = this.$watch(function () {return this.downloadtext}, this.pushDownload);
    },

    pushDownload: function(newvalue) {
        if (newvalue == '') { return }

        var element = document.createElement('a');
        element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(newvalue));
        element.setAttribute('download', this.downloadfilename);
        element.style.display = 'none';
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);

        if (this.unwatch) { this.unwatch(); this.unwatch = null };
        this.downloadtext = '';
        this.download = '';
    },

    """
end

# there's also a Quasar method to copy to clipboard, which can be brought into scope
# by `js_mounted()`
function js_copytoclipboard()
    js"""
    copyToClipboard: function(str) {
        const el = document.createElement('textarea');  // Create a <textarea> element
        el.value = str;                                 // Set its value to the string that you want copied
        el.setAttribute('readonly', '');                // Make it readonly to be tamper-proof
        el.style.position = 'absolute';                 
        el.style.left = '-9999px';                      // Move outside the screen to make it invisible
        document.body.appendChild(el);                  // Append the <textarea> element to the HTML document
        const selected =            
            document.getSelection().rangeCount > 0        // Check if there is any content selected previously
            ? document.getSelection().getRangeAt(0)     // Store selection if found
            : false;                                    // Mark as false to know no selection existed before
        el.select();                                    // Select the <textarea> content
        document.execCommand('copy');                   // Copy - only works as a result of a user action (e.g. click events)
        document.body.removeChild(el);                  // Remove the <textarea> element
        if (selected) {                                 // If a selection existed before copying
            document.getSelection().removeAllRanges();    // Unselect everything on the HTML document
            document.getSelection().addRange(selected);   // Restore the original selection
        }
    }
"""
end

function df_to_csv(df; decimal::Union{String, Char} = '.', replace_header::Bool = false, delim::Union{Nothing, String, Char} = nothing, kwargs...)
    io = IOBuffer()
    decimal = decimal isa Char ? decimal : get(decimal, 1, '.')
    replace_header && decimal != '.' && (df = rename(df, replace.(names(df), '.' => decimal)))
    delim = isnothing(delim) ? (decimal == '.' ? "," : ";") : string(delim)
    CSV.write(io, df; decimal, delim, kwargs...)
    String(take!(io))
end

# -----------------------------

mycss() = [
    style("""
    .stipple-core .q-toggle__thumb:after {
        box-shadow: 0 3px 1px -2px rgba(0,0,0,0.2),0 2px 2px 0 rgba(0,0,0,0.14),0 1px 5px 0 rgba(0,0,0,0.12);
    }
    """),
    style(csscolors(:mycolor, [RGB(1, 0, 0), RGB(0, 1, 0), RGB(0, 0, 1)]))
]

add_css(mycss)

@reactive! mutable struct TableDemo <: ReactiveModel 
    table::R{DataTable} = DataTable()
    
    downloadbutton::R{Bool} = false
    download::R{String} = ""
    downloadfilename::R{String} = "download.txt"
    downloadtext::R{String} = ""

    decimalseparator::R{String} = ","
    delimiter::R{String} = ","
    copytoclipboard::R{Bool} = false
end

Genie.Router.delete!(:TableDemo)

Stipple.js_methods(::TableDemo) = join([
    js_requestpushdownload(),
    js_copytoclipboard()
])


function ui(model)
    page(model, 
        append = link(href="iconsets/@mdi/font/css/materialdesignicons.min.css", rel="stylesheet", type="text/css"),
        
        [
            heading("Download and Clipboard")

            row(cell(class = "st-module", [
                btn("Download Table", @click(:downloadbutton), 
                    color = "mycolor-1", loading = :downloadbutton,
                    "no-caps", style="margin: 5px;"
                )

                btn("Download Table", @click("""requestDownload("csv")"""), 
                    color = "mycolor-1", loading = R"download == 'csv'",
                    "no-caps", style="margin: 5px;"
                )

                toggle("", :decimalseparator, tooltip("decimal separator"), :keep__color, color = "mycolor-2",
                    true__value = ",", false__value = ".",
                    unchecked__icon = "mdi-square-medium", checked__icon = "mdi-comma"
                )

                btn("", icon = "mdi-clipboard-text-multiple", @click(:copytoclipboard),
                    color = "mycolor-3", "no-caps", style = "margin: 5px;", [tooltip("copy data to clipboard")]
                )

                cell(table(:table, "", :dense))
            ]))
        ])
end
  
#== server ==#

route("/") do
    model = init(TableDemo, debounce = 0) |> handlers
    
    df = DataFrame("time" => [1, 2, 3], "1.23" => [1.23, 3.45, 4.56], "2.34" => [12.3, 34.5, 45.6])
    model.table[!] = DataTable(df)

    ui(model) |> html
end

function handlers(model)

    on(model.isready) do isready
        isready || return
        push!(model)
    end

    onbutton(model.downloadbutton) do
        isempty(model.table.data) && return
        
        model.downloadfilename[] = "table.csv"
        model.downloadtext[] = df_to_csv(model.table.data, decimal = model.decimalseparator[], replace_header = true)
        run(model, "this.pushDownload(this.downloadtext)")

        @async begin
            sleep(1)
            model.downloadtext[!] = ""
        end
    end

    # advanced download section, suited for handling different downloads
    # by supplying a keyword, e.g. "csv"
    on(model.download) do download
        isempty(download) && return

        # some output on the browser's console
        run(model, "console.log('download: $download')")

        # in case you have different places for download you can distinguish them here
        if download == "csv"
            model.downloadfilename[] = "table.csv"
            text = df_to_csv(model.table.data, decimal = model.decimalseparator[], replace_header = true)
        end
        
        @info "downloading $(model.downloadfilename[]) ..."
        
        # the following line will trigger the download as we have installed a js listener
        model.downloadtext[] = text

        # empty field `download` in case of error after 1s
        @async begin
            sleep(1)
            model.download[!] = ""
        end
    end

    onbutton(model.copytoclipboard) do
        isempty(model.table.data) && return

        model.downloadtext[] = df_to_csv(model.table.data, decimal = model.decimalseparator[], replace_header = true, delim ='\t')
        run(model, "this.copyToClipboard(this.downloadtext)")

        @async begin
            sleep(1)
            model.downloadtext[!] = ""
        end
    end

    model
end

up()