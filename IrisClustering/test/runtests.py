from playwright.sync_api import sync_playwright

with sync_playwright() as p:
  browser = p.firefox.launch(headless=False, slow_mo=1000)
  page = browser.new_page()
  page.goto("http://127.0.0.1:9000/")
  sliders = page.query_selector_all("_vue=QSlider")
  # sliders[0].click()
  # sliders[1].click()

  # print(type(sliders[0].getproperties()))
  # print(sliders[0].get_property("model"))

  selects = page.query_selector_all("_vue=QSelect")
  selects[0].click()

  menu = page.query_selector("_vue=QItem >> nth=0")
  menu.click()

  selects = page.query_selector_all("_vue=QSelect")
  selects[1].click()

  menu = page.query_selector("_vue=QItem >> nth=2")
  menu.click()

  aslider = page.locator("_vue=QSlider >> nth=0")
  aslider.click()

  value = aslider.evaluate("""myVueEnabledDOMElement => {
    let elementVueInstance = myVueEnabledDOMElement.__vue__;
    let checkedPropertyValue = elementVueInstance.value;
    return checkedPropertyValue == 11;
  }""")
  print(value)
  browser.close()