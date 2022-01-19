from playwright.sync_api import sync_playwright

with sync_playwright() as p:
  browser = p.firefox.launch(headless=False, slow_mo=100)
  page = browser.new_page()
  page.goto("http://127.0.0.1:9000/")
  sliders = page.query_selector_all("_vue=QSlider")
  sliders[0].click()
  sliders[1].click()

  # print(type(sliders[0].getproperties()))
  print(sliders[0].get_property("model"))
  browser.close()