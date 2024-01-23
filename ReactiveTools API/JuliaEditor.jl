using OhMyREPL
using ANSIColoredPrinters
using JuliaSyntax
using JuliaFormatter
using Stipple, Stipple.ReactiveTools
using StippleUI
using StippleUI.StippleUIParser.EzXML


let x = read(joinpath(dirname(dirname(pathof(ANSIColoredPrinters))), "docs", "src", "assets", "default.css"), String)
    global css
    css() = [style(x)]
end

add_css(css)

function OhMyREPL.test_passes(io::IO, rpc::OhMyREPL.PassHandler, str::Union{String, IOBuffer}, cursorpos::Int = 1, cursormovement::Bool = false; indent::Int)
    b = IOBuffer()
    tokens = tokenize(str)
    OhMyREPL.apply_passes!(rpc, tokens, str, cursorpos, cursormovement)
    OhMyREPL.untokenize_with_ANSI(io, rpc.accum_crayons, tokens, str, indent)
end

function editor2code(editor)
    isempty(editor) && return ""

    ed = replace(editor, "<br></div>" => "</div>")
    ed = replace(ed, "</div><div>" => "\n")
    ed = replace(ed, "</pre><pre>" => "\n")
    ed = replace(ed, "<br>" => "\n")

    root =parsehtml(ed).root
    root === nothing ? "" : root.content
end

function code2html(str::String = OhMyREPL.TEST_STR, rpc::OhMyREPL.PassHandler = OhMyREPL.PASS_HANDLER)
    io = IOBuffer()
    OhMyREPL.test_passes(io, rpc, str, 0, false, indent = 0)
    printer = HTMLPrinter(io)
    io2 = IOBuffer()
    show(io2, "text/html", printer)
    # print(io2, "hh")
    String(take!(io2))
end

@app Editor begin
    @in editor = OhMyREPL.TEST_STR |> code2html
    @in new_editor = ""
    @in code = ""
    @in cursor = Stipple.opts(code = OhMyREPL.TEST_STR, position = 0)
    @in highlight = false
    @in format = false
    @in auto_highlight = true
    @in dark = false
    @in colorscheme = "GitHubLight"
    @in colorscheme_options = OhMyREPL.Passes.SyntaxHighlighter.SYNTAX_HIGHLIGHTER_SETTINGS.schemes |> keys

    @onchange new_editor begin
        code = new_editor |> editor2code
        editor = code |> code2html
    end

    @onbutton highlight begin
        code = editor |> editor2code
        editor = code |> code2html
    end

    @onbutton format begin
        editor = editor |> editor2code |> format_text |> code2html
    end
    
    @onchange colorscheme begin
        colorscheme!(colorscheme)
        auto_highlight || return
        editor = editor |> editor2code |> format_text |> code2html
    end
end

@methods Editor [
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
        const range = this.\$refs.editor.caret.range
    
        // Iterate through the nodes until the range is reached
        while ((currentNode = treeWalker.nextNode())) {
            if (range && currentNode === range.startContainer) { rangeReached = true }
            if (currentNode.nodeType === Node.TEXT_NODE) {
                new_text = currentNode.nodeValue
            } else if (currentNode.tagName === 'BR') {
                new_text = '\\n'; // Insert a newline character for each <br> node
            } else if (currentNode.tagName === 'PRE') {
                pre += 1
                if (pre == 1) { continue }
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
                    // console.log(next_node)
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
                new_text = '\\n'; // Insert a newline character for each <br> node
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
    
        // If the text is not found, you might want to handle it accordingly
        console.log('Text not found in contentEditable:', text);
    }"
]

@watch Editor [
    :editor => "function() {
        x = this
        // console.log('editor changed')
        setTimeout(function() {
            c = x.getCursor()
            cursorText = c.code.substring(0, c.position)
            // console.log(cursorText + ':')
            if (c.code != x.cursor.code) {
                // console.log('code changed')
                // console.log('c: ', c.position, ', old: ', x.cursor.position)
                x.cursor = c
                x.new_editor = x.editor
            } else {
                // console.log('resetting cursor')
                // console.log(cursorText + ':')
                setTimeout(() => { x.setCaretAtEndOfText(cursorText) }, 50)
            }
        }, 10)
    }"
]



ui() = [
    h1("Julia Editor")
    row(cell(class = "st-module", [
        editor(:editor, id = "ed", ref = "editor", dark = :dark, toolbar = []) |> cell
        btn("highlight", @click(:highlight), @if("(!auto_highlight)"))
        btn("format", @click(:format))
        toggle("auto highlight", :auto_highlight)
        toggle("dark", :dark)
        Stipple.select(style = "max-width: 20em", :colorscheme, options = :colorscheme_options, "", :dense, :optionsdense, :filled)
    ]))
]

route("/") do
    colorscheme!("GitHubLight")
    global model = @init Editor
    page(model, ui, debounce = 0) |> html
end

up(open_browser = true)
