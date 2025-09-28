module GenieTemplate

using Stipple, Stipple.ReactiveTools
using StippleUI
using Dates

import Stipple.opts
import Genie.Router.Route
import Genie.Generator.Logging
import Genie.Assets.asset_path
import Genie.Server.openbrowser

export openbrowser, @wait

function openbrowser()
    if ! parse(Bool, get(ENV, "DOCKER", "false"))
        port = Genie.config.server_port
        url = "http://localhost:$(port)"
        openbrowser(url)
    end
end

macro wait()
    :(Base.wait(Val(Genie), exit_msg = "$($__module__) stopped."))
end

macro wait(exit_msg)
    :(Base.wait(Val(Genie), exit_msg = $exit_msg))
end

macro wait(start_msg, exit_msg)
    :(Base.wait(Val(Genie), start_msg = $start_msg, exit_msg = $exit_msg))
end

function Base.wait(::Val{Genie}; start_msg::String="Press Ctrl/Cmd+C to interrupt.", exit_msg::String="Genie stopped.")
    Base.isinteractive() && "serve" ∉ ARGS || "noserve" ∈ ARGS && return
    
    Base.exit_on_sigint(false)   # don’t kill process immediately on Ctrl-C
    try
        isempty(start_msg) || println("\n$start_msg")
        Base.isinteractive() ? wait(Condition()) : while true
            sleep(0.5)  # interruptible version for non-interactive sessions
        end
    catch e
        if e isa InterruptException
            isempty(exit_msg) || println("\n$exit_msg\n")
        else
            rethrow()
        end
    finally
        Base.exit_on_sigint(! Base.isinteractive())  # restore default behavior
    end
end

t_startup::DateTime = DateTime(0)

@app MyApp begin
    @in x = 1.0
    @in search = ""
    @in storage = 0.26

    @onchange isready begin
        global t_startup
        if t_startup != DateTime(0)
            @info "Startup time: $(now() - t_startup)"
            t_startup = DateTime(0)
        end
    end
end

function myheader()
    header(elevated = "", class = "bg-white text-grey-8", var"height-hint" = "64", 
        toolbar(class = "GPL__toolbar", style = "height: 64px", [
            btn(flat = "", dense = "", round = "", @click("toggleLeftDrawer"), var"aria-label" = "Menu", icon = "menu", class = "q-mx-md"),
            toolbartitle(@if("\$q.screen.gt.sm"), shrink = "", class = "row items-center no-wrap", [
                img(src = "https://cdn.quasar.dev/img/layout-gallery/logo-google.svg"),
                span(class = "q-ml-sm", 
                    "Photos"
                )
            ]),
            space(),
            textfield("", :search, class = "GPL__toolbar-input", dense = "", standout = "bg-primary", placeholder = "Search", [
                template(var"v-slot:prepend" = "", [
                    icon("search", @if("search === ''")),
                    icon("clear", @else(), class = "cursor-pointer", @click("search = ''"))
                ])
            ]),
            btn("Create", @if("\$q.screen.gt.xs"), flat = "", dense = "", nowrap = "", color = "primary", icon = "add", nocaps = "", class = "q-ml-sm q-px-md", [
                menu(anchor = "top end", self = "top end", 
                    list(class = "text-grey-8", style = "min-width: 100px", [
                        item(var"aria-hidden" = "true", 
                            itemsection(class = "text-uppercase text-grey-7", style = "font-size: 0.7rem", 
                                "Create New"
                            )
                        ),
                        item(@for("menu in createMenu"), key = R"menu.text", clickable = "", vclosepopup = "", var"aria-hidden" = "true", [
                            itemsection(avatar = "", 
                                icon(R"menu.icon")
                            ),
                            itemsection(
                                "{{ menu.text }}"
                            )
                        ])
                    ])
                )
            ]),
            btn("Upload", @if("\$q.screen.gt.xs"), flat = "", dense = "", nowrap = "", color = "primary", icon = "cloud_upload", nocaps = "", class = "q-ml-sm q-px-md"),
            space(),
            htmldiv(class = "q-gutter-sm row items-center no-wrap", [
                btn(round = "", dense = "", flat = "", color = "text-grey-7", icon = "apps", [
                    tooltip("Google Apps")
                ]),
                btn(round = "", dense = "", flat = "", color = "grey-8", icon = "notifications", [
                    badge(color = "red", textcolor = "white", floating = "", "2"),
                    tooltip("Notifications")
                ]),
                btn(round = "", flat = "", [
                    avatar(size = "26px", img(src = "https://cdn.quasar.dev/img/boy-avatar.png")),
                    tooltip("Account"
                    )
                ])
            ])
        ])
    )
end

function mydrawer()
    drawer(fieldname = "leftDrawerOpen", bordered = "", behavior = "mobile", @click("leftDrawerOpen = false"), 
        scrollarea(class = "fit", [
            toolbar(class = "GPL__toolbar", 
                toolbartitle(class = "row items-center text-grey-8", [
                    img(class = "q-pl-md", src = "https://www.gstatic.com/images/branding/googlelogo/svg/googlelogo_clr_74x24px.svg"),
                    span(class = "q-ml-sm", "Photos")
                ])
            ),
            list(padding = "", [
                item(@for("link in links1"), key = R"link.text", clickable = "", class = "GPL__drawer-item", [
                    itemsection(avatar = "", icon(R"link.icon")),
                    itemsection(itemlabel("{{ link.text }}"))
                ]),
                separator(class = "q-my-md"),
                item(@for("link in links2"), key = R"link.text", clickable = "", class = "GPL__drawer-item", [
                    itemsection(avatar = "", icon(R"link.icon")),
                    itemsection(itemlabel("{{ link.text }}"))
                ]),
                separator(class = "q-my-md"),
                item(@for("link in links3"), key = R"link.text", clickable = "", class = "GPL__drawer-item", [
                    itemsection(avatar = "", icon(R"link.icon")),
                    itemsection(itemlabel("{{ link.text }}"))
                ]),
                separator(class = "q-my-md"),
                item(clickable = "", class = "GPL__drawer-item GPL__drawer-item--storage", [
                    itemsection(avatar = "", icon("cloud")),
                    itemsection(top = "", [
                        itemlabel("Storage"),
                        quasar(:linear__progress, value = :storage, class = "q-my-sm"),
                        itemlabel(caption = "", "2.6 GB of 15 GB")
                    ])
                ])
            ])
        ])
    )
end

function leftMenu()
    page_sticky(@if("\$q.screen.gt.sm"), class = "q-mt-xl", expand = "", position = "left", 
        htmldiv(class = "fit q-pt-md q-px-sm column", [
            btn(round = "", flat = "", color = "grey-8", stacked = "", nocaps = "", size = "26px", class = "GPL__side-btn", [
                icon("photo", size = "22px"),
                htmldiv(class = "GPL__side-btn__label", 
                    "Photos"
                )
            ]),
            btn(round = "", flat = "", color = "grey-8", stacked = "", nocaps = "", size = "26px", class = "GPL__side-btn", [
                icon("collections_bookmark", size = "22px"),
                htmldiv(class = "GPL__side-btn__label", 
                    "Albums"
                )
            ]),
            btn(round = "", flat = "", color = "grey-8", stacked = "", nocaps = "", size = "26px", class = "GPL__side-btn", [
                icon("assistant", size = "22px"),
                htmldiv(class = "GPL__side-btn__label", 
                    "Assistant"
                ),
                badge(floating = "", color = "red", textcolor = "white", style = "top: 8px; right: 16px", 
                    "1"
                )
            ]),
            btn(round = "", flat = "", color = "grey-8", stacked = "", nocaps = "", size = "26px", class = "GPL__side-btn", [
                icon("group", size = "22px"),
                htmldiv(class = "GPL__side-btn__label", 
                    "Sharing"
                )
            ]),
            btn(round = "", flat = "", color = "grey-8", stacked = "", nocaps = "", size = "26px", class = "GPL__side-btn", [
                icon("import_contacts", size = "22px"),
                htmldiv(class = "GPL__side-btn__label", 
                    "Photo books"
                )
            ])
        ])
    )
end

UI::Vector{Genie.Renderer.Html.ParsedHTMLString} = [
    StippleUI.layout(view = "lHh Lpr fff", class = "bg-grey-1", [
        myheader(),
        mydrawer(),
        page_container(class = "GPL__page-container", [
            leftMenu(),
            htmldiv(class = "q-pt-md q-page q-layout-padding", [
                htmldiv(class = "text-h3 text-blue-4", "Iconsets"),
                separator(class = "q-my-md"),
                row(@gutter :lg [
                    card([
                        cardsection("Material Icons")
                        cardsection(icon("home"),)
                    ]),
                    card([
                        cardsection("Material Symbols Outline"),
                        cardsection(icon("sym_o_home", style = R"`font-variation-settings: 'FILL' ${x}; transition: font-variation-settings 0.5s ease;`"),)
                    ]),
                    card([
                        cardsection("Material Symbols Rounded"),
                        cardsection(icon("sym_r_home", style = R"`font-variation-settings: 'FILL' ${x}; transition: font-variation-settings 0.5s ease;`"),)
                    ]),
                    card([
                        cardsection("Material Symbols Sharp"),
                        cardsection(icon("sym_s_home", style = R"`font-variation-settings: 'FILL' ${x}; transition: font-variation-settings 0.5s ease;`"),)
                    ]),
                ]),

                row(class = "q-mt-md",
                    btn("Toggle Fill", @click("this.x = 1 - this.x"))
                ),
            ])
        ])
    ])
]

@methods MyApp [
    :toggleLeftDrawer => js"""function () {
        this.leftDrawerOpen = !this.leftDrawerOpen
    }
    """
]

Stipple.client_data(::MyApp) = client_data(
    leftDrawerOpen = false,
    links1 = [
        opts(icon = "photo", text = "Photos"),
        opts(icon = "photo_album", text = "Albums"),
        opts(icon = "assistant", text = "Assistant"),
        opts(icon = "people", text = "Sharing"),
        opts(icon = "book", text = "Photo books")
    ],
    links2 = [
        opts(icon = "archive", text = "Archive"),
        opts(icon = "delete", text = "Trash")
    ],
    links3 = [
        opts(icon = "settings", text = "Settings"),
        opts(icon = "help", text = "Help"),
        opts(icon = "get_app", text = "App Downloads")
    ],
    createMenu = [
        opts(icon = "photo_album", text = "Album"),
        opts(icon = "people", text = "Shared"),
        opts(icon = "movie", text = "Movie"),
        opts(icon = "library_books", text = "Animation"),
        opts(icon = "dashboard", text = "Collage"),
        opts(icon = "book", text = "Photo books")
    ]
)

local_material_fonts() = (stylesheet("/iconsets/material/font/material.css"),)

# add_css(googlefonts_css)
add_css(local_material_fonts)
ui() = UI

home::Route = route("/") do
    core_theme = false
    global model = @init(MyApp; core_theme)
    
    page(model, ui; core_theme) |> html
end

gpl_css() = [style("""
.GPL__toolbar {
  height: 64px;
}

.GPL__toolbar-input {
  width: 35%;
}

.GPL__drawer-item {
  line-height: 24px;
  border-radius: 0 24px 24px 0;
  margin-right: 12px;
}

.GPL__drawer-item .q-item__section--avatar {
  padding-left: 12px;
}

.GPL__drawer-item .q-item__section--avatar .q-icon {
  color: #5f6368;
}

.GPL__drawer-item .q-item__label:not(.q-item__label--caption) {
  color: #3c4043;
  letter-spacing: .01785714em;
  font-size: .875rem;
  font-weight: 500;
  line-height: 1.25rem;
}

.GPL__drawer-item--storage {
  border-radius: 0;
  margin-right: 0;
  padding-top: 24px;
  padding-bottom: 24px;
}

.GPL__side-btn__label {
  font-size: 12px;
  line-height: 24px;
  letter-spacing: .01785714em;
  font-weight: 500;
}

@media (min-width: 1024px) {
  .GPL__page-container {
    padding-left: 94px;
  }
}""")
]

# -----------  app init -------------

function __init__()
    global t_startup = now()
    cd(@project_path)
    Genie.config.path_build = @project_path "build"
    Genie.Loader.loadenv(; context = @__MODULE__)
    
    up()

    add_css(gpl_css)
    add_css(local_material_fonts)

    route(home)
    @wait
end

# -----------  precompilation -------------

import Stipple: Genie.Assets.asset_path

@stipple_precompile begin
    context = @__MODULE__
    Genie.config.path_build = @project_path "build"
    let showbanner = parse(Bool, get!(ENV, "GENIE_BANNER", "true"))
        ENV["GENIE_BANNER"] = false
        Genie.Loader.loadenv(; context)
        ENV["GENIE_BANNER"] = showbanner
    end

    @init(MyApp; core_theme = false)
    route(home)
    precompile_get("/")
    precompile_get(asset_path(MyApp))
end

end # module