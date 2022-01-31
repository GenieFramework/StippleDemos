cd(@__DIR__)

using Test, SafeTestsets
using Playwright

# @safetestset "IrisClustering UI Components Tests" begin
@testset "Slider Test" begin
  @uitest p begin
    browser = p.firefox.launch(headless=false, slow_mo=1000)
    page = browser.new_page()
    try
      page.goto("http://127.0.0.1:9000/")
    catch e
      "Failed goto"
    end

    sliders = page.query_selector_all("_vue=QSlider")
    sliders[2].click()

    aslider = page.locator("_vue=QSlider >> nth=0")
    aslider.click()

    value = aslider.evaluate("""myVueEnabledDOMElement => {
      let elementVueInstance = myVueEnabledDOMElement.__vue__;
      let checkedPropertyValue = elementVueInstance.value;
      return checkedPropertyValue;
    }""")

    @test value == 11
        
    selects = page.query_selector_all("_vue=QSelect")
    selects[1].click()
  
    menu = page.query_selector("_vue=QItem >> nth=0")
    menu.click()

    select_value = selects[1].evaluate("""myVueEnabledDOMElement => {
      let elementVueInstance = myVueEnabledDOMElement.__vue__;
      let checkedPropertyValue = elementVueInstance.value;
      return checkedPropertyValue;
    }""")

    @test select_value == "SepalLength"
  
    selects = page.query_selector_all("_vue=QSelect")
    selects[2].click()
  
    menu = page.query_selector("_vue=QItem >> nth=2")
    menu.click()

    table_button = page.locator("_vue=QBtn >> nth=2")
    table_button.click()
    
    browser.close()
  end
end