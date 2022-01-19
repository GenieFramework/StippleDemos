cd(@__DIR__)

using Test, SafeTestsets
using Playwright

# @safetestset "IrisClustering UI Components Tests" begin
@testset "Slider Test" begin
  @uitest p begin
    browser = p.firefox.launch(headless=false, slow_mo=100)
    page = browser.new_page()
    try
      page.goto("http://127.0.0.1:9000/")
    catch e
      "Failed goto"
    end

    # x_feature = page.query_selector("xpath=//html/body/div[1]/div[1]/div[3]/label/div/div")
    # y_feature = page.query_selector("xpath=//html/body/div[1]/div[1]/div[4]/label/div/div")

    # xbox = x_feature.bounding_box()
    # xbox_middle_x = xbox["x"] + xbox["width"] / 2
    # xbox_middle_y = xbox["y"] + xbox["height"] / 2
    # page.mouse.click(xbox_middle_x, xbox_middle_y)
    # page.mouse.click(xbox_middle_x+50, xbox_middle_y+50)
    

    # ybox = y_feature.bounding_box()
    # ybox_middle_x = ybox["x"] + ybox["width"] / 2
    # ybox_middle_y = ybox["y"] + ybox["height"] / 2
    # page.mouse.click(ybox_middle_x, ybox_middle_y)
    # page.mouse.click(ybox_middle_x+100, ybox_middle_y+100)

    sliders = page.query_selector_all("_vue=QSlider")
    @info typeof(sliders[1])
    sliders[1].click()
    sliders[2].click()
    # table.click()
    
    # sliders2 = page.locator("_vue=QSlider").count()
    
    # sliders[2].getproperty()

    # @info typeof(sliders[1])
    # @info typeof(sliders)
    # page.query_selector_all("_vue=QSlider")[1].getproperties()

    browser.close()
  end
end
# end

