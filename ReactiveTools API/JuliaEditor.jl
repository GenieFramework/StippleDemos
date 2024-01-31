using OhMyREPL
using ANSIColoredPrinters
using JuliaSyntax
using JuliaFormatter

using Stipple, Stipple.ReactiveTools
using StippleUI
using StippleUI.StippleUIParser.EzXML

options = Stipple.opts


let x = read(joinpath(dirname(dirname(pathof(ANSIColoredPrinters))), "docs", "src", "assets", "default.css"), String)
    x *= """
    .no-pre-margin .q-editor__content pre {
        margin: 0
    }
    """
    global css
    css() = [style(x)]
end

add_css(css)

function OhMyREPL.test_passes(io::IO, rpc::OhMyREPL.PassHandler, str::Union{String, IOBuffer}, cursorpos::Int = 1, cursormovement::Bool = false; indent::Int)
    tokens = tokenize(str)
    OhMyREPL.apply_passes!(rpc, tokens, str, cursorpos, cursormovement)
    OhMyREPL.untokenize_with_ANSI(io, rpc.accum_crayons, tokens, str, indent)
end

function editor2code(editor)
    isempty(editor) && return ""

    ed = replace(editor, "<br></span>" => "</span><br>")
    ed = replace(ed, "<br></div><div>" => "\n")
    ed = replace(ed, "</div><div>" => "\n")
    ed = replace(ed, "<br></pre><pre>" => "\n")
    ed = replace(ed, "</pre><pre>" => "\n")
    ed = replace(ed, "<br>" => "\n")

    root = parsehtml(ed).root
    root === nothing ? "" : root.content
end

function code2html(str::String = OhMyREPL.TEST_STR, rpc::OhMyREPL.PassHandler = OhMyREPL.PASS_HANDLER)
    io = IOBuffer()
    OhMyREPL.test_passes(io, rpc, str, 0, false, indent = 0)
    printer = HTMLPrinter(io)
    io2 = IOBuffer()
    show(io2, "text/html", printer)
    String(take!(io2))
end

@app Editor begin
    @in editor = String(lstrip(OhMyREPL.TEST_STR)) |> code2html
    @in update_editor = ""
    @in code = "" # only for debugging
    @in cursor = Stipple.opts(code = lstrip(OhMyREPL.TEST_STR), position = 0)
    @in update = false
    @in undo_mode = true
    @in highlight = false
    @in format = false
    @in auto_highlight = true
    @in dark = false
    @in colorscheme = "GitHubLight"
    @in colorscheme_options = OhMyREPL.Passes.SyntaxHighlighter.SYNTAX_HIGHLIGHTER_SETTINGS.schemes |> keys

    @onchange isready notify(colorscheme)

    @onbutton update begin
        # println("'", cursor[:code][cursor[:position]-10:cursor[:position]], "'")
        auto_highlight || return
        code = editor |> editor2code
        update_editor = code |> code2html
        # update_editor = cursor[:code] |> code2html
    end

    @onbutton highlight begin
        run(__model__, "this.cursor = this.getCursor()")
        code = editor |> editor2code
        update_editor = code |> code2html
    end

    @onbutton format begin
        run(__model__, "this.cursor = this.getCursor()")
         code = editor |> editor2code
         update_editor = code |> format_text |> code2html
    end
    
    @onchange colorscheme begin
        colorscheme!(colorscheme)
        auto_highlight || return
        run(__model__, "this.cursor = this.getCursor()")
        update_editor = editor |> editor2code |> code2html
    end
end

@methods Editor [
    # retrieves the plain text of the editor and the cursor position therein 
    :getCursor => "function () {
        const startNode = this.\$refs.editor.getContentEl()
        const treeWalker = document.createTreeWalker(
            startNode,
            NodeFilter.SHOW_ALL,
        );
    
        let text = ''
        let n = 0
        let new_text = ''
        let currentNode
        let rangeReached = false
        let pre = 0
        let br = false
        const range = this.\$refs.editor.caret.range
    
        // Iterate through the nodes until the range is reached
        while ((currentNode = treeWalker.nextNode())) {
            if (range && currentNode === range.startContainer) { rangeReached = true }
            if (currentNode.nodeType === Node.TEXT_NODE) {
                new_text = currentNode.nodeValue
                br = false
            } else if (currentNode.tagName === 'BR') {
                new_text = '\\n'; // Insert a newline character for each <br> node
                br = true
            } else if (currentNode.tagName === 'PRE') {
                pre += 1
                if (pre == 1 || br){ continue }
                new_text = '\\n'; // Insert a newline character for each <br> node
            } else {
                continue
            }
            text += new_text
            if (rangeReached) {
                if (n == 0) { n = text.length - new_text.length + range.startOffset}

                // In Firefox we have the strange situation that the range is not updated upon entering of a newline.
                // Here we compensate for this by checking whether a <br> has been inserted right after the caret range.
                if (text.length == n) {
                    next_node = treeWalker.nextNode()
                    console.debug(next_node)
                    if ((pre > 0) && (next_node) && (next_node.tagName === 'BR')) {
                        n += 1
                        text += '\\n'
                    } else if (next_node) {
                        v = next_node.nodeValue
                        if (v) { text += v}
                    }
                }
            }
        }
    
        return { code: text, position: n };
    }"

    :setCaretAtEndOfText => "function (text) {
        const startNode = this.\$refs.editor.getContentEl()
        const treeWalker = document.createTreeWalker(
            startNode,
            NodeFilter.SHOW_ALL,
        );
    
        let foundText = '';
        let pre = 0;
        let len = 0;
        let currentNode;
    
        // Iterate through the nodes until the text is found
        while ((currentNode = treeWalker.nextNode())) {
            if (currentNode.nodeType === Node.TEXT_NODE) {
                new_text = currentNode.nodeValue
            } else if (currentNode.tagName === 'BR') {
                new_text = '\\n'; // Insert a newline character for each <br> node
            } else if (currentNode.tagName === 'PRE') {
                pre += 1
                if (pre == 1) { continue }
                new_text = '\\n'; // Insert a newline character for each <pre> node
            } else {
                continue
            }
            foundText += new_text
    
            // Check if the found text starts with the specified text
            if (foundText.startsWith(text)) {
                len = currentNode.nodeValue.length - (foundText.length - text.length)
                
                // Create a range and set caret position to the end of the found text
                const range = document.createRange();
                range.setStart(currentNode, len);
                collapsed = true
                
                startNode.focus();
                const selection = window.getSelection();
                selection.removeAllRanges();
                selection.addRange(range);
            
                return; // Break the loop after setting the caret
            }
        }
    
        // If the text is not found, leave a message ...
        console.debug('Text not found in contentEditable:', text);
    }"

    :insertHTML => "function (html) {
        if (!this.undo_mode) {
            this.editor = html
            return
        }
        // some string mangling in order to compensate for
        // the behaviour of the 'insertHTML' command
        // This may be browser-specific and, therefore, can be disabled
        // by setting undo_mode = false
        if (this.editor.startsWith('<pre>') && html.startsWith('<pre>')) {
            html = html.substring(5, html.length - 6)
        }
        if (html.endsWith('\\n')) {
            html = html.substring(0, html.length - 1)
        }
        ce = this.\$refs.editor
        ce.runCmd('selectAll'); ce.runCmd('insertHTML', html)
        if (html + '\\n' == this.editor) {
            this.isChrome = true
            //ce.runCmd('delete')
        }
    }"

    :insertText => "function (html) {
        ce = this.\$refs.editor
        ce.runCmd('selectAll'); ce.runCmd('insertText', html)
    }"
]

# immediate response to update the editor (no debounce)
@watch Editor [
    :update_editor => "function(update_editor) {
        this.insertHTML(update_editor);
        x = this
        cursorText = x.cursor.code.substring(0, x.cursor.position)
        setTimeout(() => {
            console.debug('resetting cursor to ', '\\'' + cursorText.substring(cursorText.length-10) + '\\'')
            x.setCaretAtEndOfText(cursorText)
        }, 50)
    }"
]

@mounted Editor "this.\$refs.editor.getContentEl().spellcheck = false"

@created Editor "this.\$watch('editor', _.debounce(function(editor) {
        x = this
        console.debug('editor changed')
        // some delay is necessary, for having an updated caret.range
        setTimeout(function() {
            c = x.getCursor()
            cursorText = x.cursor.code.substring(0, x.cursor.position)
            // if code has changed, save the cursor 
            if (c.code != x.cursor.code) {
                console.debug('code changed')
                x.cursor = c
                x.update = true
            } else {
                
            }
        }, 50)
    }, 500))"

ui() = [
    row(cell(class = "st-module", [
        h1("Julia Editor")

        editor(:editor, id = "ed", ref = "editor", class = "no-pre-margin", dark = :dark,
            toolbar__text__color="white",
            toolbar__toggle__color="yellow-8",
            toolbar__bg="primary",
            toolbar = [
                ["token"]
            ],
            [template(var"v-slot:token"=true, row(class = "text-white", [
                row(class = "", btntoggle(:dark, class = "q-mx-none", size = "sm", "",
                    options = [options(label = "dark", value = true), options(label = "light", value = false)],
                    :push, :glossy, toggle__color = "secondary"
                ))
                Stipple.select(style = "max-width: 20em; color: rgb(255, 255, 255)", :colorscheme, options = :colorscheme_options, "",
                    :dense, :options__dense, :filled, dark = true
                )
                toggle("auto highlight", :auto_highlight, dark = :dark, size = "sm", color = "secondary")
                btn("format", @click(:format), :glossy, size = "sm")
                btn("highlight", @click(:highlight), :glossy, @if("(!auto_highlight)"), size = "sm")
            ]))]
        ) |> cell

    ]))
]

route("/") do
    colorscheme!("GitHubLight")
    global model = @init Editor debounce = 50
    page(model, ui) |> html
end

up(open_browser = true)
