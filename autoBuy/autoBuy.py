from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
import time

# Step 1: Set up WebDriver (Ensure you have the correct driver for your browser)
driver = webdriver.Safari()

# Step 2: Login to the website
def login():
    driver.get("https://sukoshimart.com/account/login?return_url=%2Faccount")
    time.sleep(2)  # Wait for the page to load
    driver.find_element(By.ID, "username").send_keys("your_email@example.com")
    driver.find_element(By.ID, "password").send_keys("your_password", Keys.RETURN)
    time.sleep(2)

# Step 3: Monitor product availability
def monitor_product(url):
    driver.get(url)
    while True:
        try:
            add_to_cart_button = driver.find_element(By.ID, "add-to-cart")
            if add_to_cart_button.is_enabled():
                add_to_cart_button.click()
                print("Item added to cart!")
                return
        except Exception as e:
            print("Item not available yet. Retrying...")
            time.sleep(1)  # Adjust polling frequency
            driver.refresh()

# Step 4: Automate checkout
def checkout():
    driver.find_element(By.ID, "proceed-to-checkout").click()
    time.sleep(2)
    driver.find_element(By.ID, "shipping-address").send_keys("5310 Wilderness Trail, Mississauga")
    driver.find_element(By.ID, "payment-method").send_keys("4111111111111111")
    driver.find_element(By.ID, "place-order").click()
    print("Order placed successfully!")

# Main Script
try:
    login()
    monitor_product("https://www.example.com/product-page")
    checkout()
finally:
    driver.quit()
