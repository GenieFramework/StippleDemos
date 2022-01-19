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
    sliders[1].click()
    sliders[2].click()

    selects = page.query_selector_all("_vue=QSelect")
    selects[1].click()
    menu = selects.querySelector("_vue=QMenu")

    
    selects[2].click()

    browser.close()
  end
end
# end

