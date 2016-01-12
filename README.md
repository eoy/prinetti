Prinetti
================

Getting Started
---------------

- Install with `rails generate prinetti`
- Configure config/initializers/prinetti.rb

Usage
------------

```ruby
# Initialize a new prinetti instance
prinetti = Prinetti::Label.new(order: Order.find(params[:id]))

# Get the pdf url
prinetti.pdf_url
# => "https://echannel.prinetti.net/getPdf.php?key=bc15630115c6715de5426c36c04792b9"
```

Credits
------------

Agency Leroy

- Joakim Runeberg

Tests
------------

- You're out of luck
