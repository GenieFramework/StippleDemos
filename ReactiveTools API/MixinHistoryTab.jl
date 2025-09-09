# Mixin / HistoryTab

using Stipple, Stipple.ReactiveTools, StippleUI

Stipple.enable_model_storage(false)

@app_mixin HistoryTab begin
    @in var"" = "home"
    @in _navigate = ""

    @onchange isready begin
        isready || return
        notify(var"")
    end
    
    @onchange _navigate begin
        if _navigate != ""
            var""[!] = _navigate
            @push :var""
        end
    end

    @onchange var"" begin
        @info "$(:var"") changed to '$(var"")'"
        # empty _navigate to make sure, it is executed the next time a non-empty value is set
        _navigate = ""
        @run """
        this['_index_'] = this['_index_'] + 1 || 0;
        state = {field: '$(:var"")', value: '$(var"")', index: this['_index_']}
        console.log('push state: ', state)
        history.pushState(state, '', '#' + this['_index_']);
        """
    end
end

@mounted HistoryTab js"""
    const i = this['_index_'] || -1;
    const state = {field: undefined, value: undefined, index: i}
    console.log('rplace state: ', state)
    history.replaceState(state, '', '#' + i);
    window.addEventListener('popstate',
        (event) => {
            if (event.state && event.state.field) {
                console.log('new state: ', event.state)
                if (this[event.state.field] == event.state.value) {
                    old_index = this['_index_'];
                    this['_index_'] = event.state.index;
                    if ((old_index >= event.state.index) && (event.state.index > 0)) {
                        history.back();
                    } else {
                        history.forward();
                    }
                } else {
                    this[event.state.field + '_navigate'] = event.state.value
                    this['_index_'] = event.state.index
                }
            }
        }
    );
    """

@methods HistoryTab [
    :_hello => js"""
    function () {
        console.log('The current tab is: \'' + this. + '\'')
        console.log('The tab\'s variable name is: \'' + 'this. '.slice(5, -1) + '\'')
        console.log('Last navigation was to: \'' + this._navigate + '\'')
    }
    """,
    js"hello_everyone" => js"""
    function () {
        console.log('Tab-independent greeting!')
    }
    """
]

@app_mixin MyApp begin
    @in i = 1
    @mixin tab1::HistoryTab
    @mixin tab2::HistoryTab

    @onchange i begin
       println("i: ", i)
    end
end

@mounted MyApp [
    js"""
    console.log('isready: ', this.isready)
    """
]

function ui()
    row(class = "st-module", cell(class = "q-pa-md q-ma-md", [
        tabgroup(:tab1, [
            tab(label = "Home 1", name = "home"),
            tab(label = "About 1", name = "about"),
            tab(label = "Contact 1", name = "contact")
        ])

        tabgroup(:tab2, [
            tab(label = "Home 2", name = "home"),
            tab(label = "About 2", name = "about"),
            tab(label = "Contact 2", name = "contact")
        ])
    ]))
end

@page("/", ui, model = MyApp)

up(open_browser = true)


