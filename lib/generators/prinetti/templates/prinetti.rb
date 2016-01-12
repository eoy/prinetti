Prinetti.configure do |config|
  # Print out requests and responses in the log
  config.debug           = true

  # How the address/customer is attached to the Order class
  config.address_method  = "address"
  config.customer_method = "customer"

  # Sender
  config.sender_name = "Agency Leroy"
  config.sender_street      = "Eteläranta 6"
  config.sender_postcode    = "00120"
  config.sender_city        = "Helsinki"
  config.sender_country     = "FI"
  config.sender_phone       = "050 540 8656"
  config.sender_vatcode     = "1001001-1"

  # Credentials
  config.account         = ENV["PRINETTI_ACCOUNT"]
  config.source          = ENV["PRINETTI_SOURCE"]
  config.key             = ENV["PRINETTI_KEY"]
  config.contract        = ENV["PRINETTI_CONTRACT"]
end