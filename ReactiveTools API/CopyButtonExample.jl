# CopyButtonExample

using Stipple, Stipple.ReactiveTools
using StippleUI
import Stipple.opts

# Defining a simple copy button component
@app VueCopyButton begin
    @out copied = false
end

@methods VueCopyButton [
    :handleCopy => js"""function () {
        const text = typeof this.text === 'function' ? this.text() : this.text;
        Quasar.copyToClipboard(text).then(() => {
          this.copied = true;
          setTimeout(() => {
            this.copied = false;
          }, 700);
        });
      }
    """
]

@props VueCopyButton opts(
    text = opts(
        type = [js"String", js"Function"],
        required = true
    )
)

@template VueCopyButton btn(
    style = "height: 30px; width: 30px;",
    color = "blue-8",
    icon = R"this.copied ? 'check' : 'content_copy'",
    aria__label = R"this.copied ? 'Copied!' : 'Copy to clipboard'",
    flat = false, size = "sm",
    @click("this.handleCopy")
)


copybutton(text, args...; kwargs...) = vue(:copy__button, args...; text, kwargs...)

# defining a simple app with a copy button
@app MyApp begin
    @in text1 = "Copy this text"
    @in text2 = "Quid pro quo"
    @in text3 = "Lorem Ipsum"

    @in text = ""
end

# Registering the VueCopyButton component in MyApp
@components MyApp VueCopyButton

ui() = row(cell(row(gutter = "md", [
    cell(@gutter :md [
        row([
            textfield(col = 0, "Text 1", :text1)
            copybutton(col = "auto", :text1, class = "q-ml-md")
        ])

        row([
            textfield(col = 0, "Text 3", :text3)
            copybutton(col = "auto", :text3, class = "q-ml-md self-center", style = "height: 20px", color = "green")
        ])

            
        row([
            textfield(col = 0, "Text 2", :text2)
            copybutton(col = "auto", :text2, flat = true, class = "q-ml-md self-center", style = "height: 40px", color = "red")
        ])
    ])

    cell(textfield("Demo Paste area", :text, filled = true, rows = 10, type = "textarea",))
]), class = "st-module"))

@page("/", ui, core_theme = true, model = MyApp)

up(open_browser = true)
