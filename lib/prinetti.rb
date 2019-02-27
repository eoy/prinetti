require 'digest'
require 'httparty'
require 'prinetti/version'
require 'prinetti/railtie' if defined?(Rails::VERSION)

module Prinetti

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :address_method, :customer_method, :debug, :account, :contract,
                  :key, :source, :sender_name, :sender_street, :sender_postcode,
                  :sender_city, :sender_country, :sender_phone, :sender_vatcode
  end

  class Label

    # Logic
    include HTTParty
    base_uri 'https://echannel.prinetti.net'

    def initialize(args)
      raise "Please pass an order to the Prinetti service in the format of `order: Order`" unless args[:order]
      @debug      = false
      @order      = args[:order]
      @account    = Prinetti.configuration.account || ENV["PRINETTI_ACCOUNT"]
      @contract   = Prinetti.configuration.contract || ENV["PRINETTI_CONTRACT"]
      @id         = args[:order].identifier.tr('-', '')
      @key        = Prinetti.configuration.key || ENV["PRINETTI_KEY"]
      @mode       = "0" # 1=testimode, 0 ei-testimode, saadaan asetuksista
      @name       = "Tilaus #{@id}"
      @source     = Prinetti.configuration.source ||ENV["PRINETTI_SOURCE"]
      @target     = "1"
      @time       = Time.now.to_formatted_s(:number)
      @version    = "2.3"

      # Generate a MD5 encoded key
      @md5_key = md5_key(@account, @id, @key)
    end

    def pdf_url
      self.call
    end

    def call
      xml = {
        "ROUTING": authentication,
        Shipment: shipment
      }.to_xml(root: "eChannel").sub("<Consignment.Parcel>", "<Consignment.Parcel type='normal'>")

      puts "\nSending: \n \n #{xml}" if @debug.eql?(true)

      response = self.class.post(
        '/import.php',
        headers: {'Content-type' => 'text/xml'},
        body: xml
      )

      # Parse the response data with HTTParty as xml
      parsed_response = Parser.new(response, :xml).parse["Response"]

      puts "\nReceiving: \n\n #{response}" if @debug.eql?(true)

      if parsed_response["response.message"].eql?("OK")
        # Success
        reference    = parsed_response["response.reference"]
        trackingcode = parsed_response["response.trackingcode"]

        puts "\n ** #{trackingcode}" if @debug.eql?(true)
        puts "\n ** #{reference}" if @debug.eql?(true)
      else
        # Failure
        raise StandardError, parsed_response["response.message"]
      end

      # Send request for pdf based on tracking code, returns response
      pdf_response = request_pdf(trackingcode, reference)

      # Parse pdf response
      parsed_response = Parser.new(pdf_response, :xml).parse["Response"]

      if parsed_response["response.message"].eql?("OK")
        # Success
        parsed_response["response.link"]
      else
        # Failure
        raise StandardError, parsed_response["response.message"]
      end
    end

    def request_pdf(trackingcode, reference)
      xml = {
        "ROUTING": authentication,
        "PrintLabel": {
          "Reference": reference,
          "TrackingCode": trackingcode
        }
      }.to_xml(root: "eChannel").sub("<PrintLabel>", "<PrintLabel responseFormat='link'>")

      puts "\nSending: \n \n #{xml}" if @debug.eql?(true)

      response = self.class.post(
        '/returnPdf.php',
        headers: {'Content-type' => 'text/xml'},
        body: xml
      )
    end

    private

    def authentication
      {
        "Routing.Target":  @target,
        "Routing.Source":  @source,
        "Routing.Account": @account,
        "Routing.Key":     @md5_key,
        "Routing.Id":      @id,
        "Routing.Name":    @name,
        "Routing.Time":    @time,
        "Routing.Version": @version,
        "Routing.Mode":    @mode,
        "Routing.Comment": "Something here"
      }
    end

    def shipment
      {
        "Shipment.Sender": {
          "Sender.Contractid": @contract,
          "Sender.Name1": Prinetti.configuration.sender_name,
          "Sender.Addr1": Prinetti.configuration.sender_street,
          "Sender.Postcode": Prinetti.configuration.sender_postcode, # TODO: Change
          "Sender.City": Prinetti.configuration.sender_city,
          "Sender.Country": Prinetti.configuration.sender_country,
          "Sender.Phone": Prinetti.configuration.sender_phone, # TODO: Change
          "Sender.Vatcode": Prinetti.configuration.sender_vatcode
        },
        "Shipment.Recipient": {
          "Recipient": {
            "Recipient.Code":     @order.send(Prinetti.configuration.customer_method).id,
            "Recipient.Email":    @order.send(Prinetti.configuration.customer_method).try(:email) || "",
            "Recipient.Name1":    @order.send(Prinetti.configuration.address_method).firstname,
            "Recipient.Name2":    @order.send(Prinetti.configuration.address_method).lastname,
            "Recipient.Addr1":    @order.send(Prinetti.configuration.address_method).address,
            "Recipient.Postcode": @order.send(Prinetti.configuration.address_method).zipcode,
            "Recipient.City":     @order.send(Prinetti.configuration.address_method).city,
            "Recipient.Country":  @order.send(Prinetti.configuration.address_method).country,
            "Recipient.Phone":    @order.send(Prinetti.configuration.address_method).phone,
            "Recipient.Vatcode":  nil
          }
        },
        "Shipment.Consignment": {
          "Consignment.Product": "2103", # Package 16, TODO: Change to appropriate product code from http://www.posti.fi/liitteet-yrityksille/muut/prinetin-integraatiorajapintakuvaus.pdf
          "Consignment.Reference": @id,
          "Consignment.Parcel": {
            "Parcel.Packagetype": "PC",
            "Parcel.Reference": @id,
            # "Parcel.Weight": "0.1",
            # "Parcel.Volumne": "0.1",
            # "Parcel.Infocode": "12345",
            "Parcel.Contents": "Nuotistoja"
          }
        }
      }
    end

    def md5_key(account, id, key)
      md5 = Digest::MD5.hexdigest "#{account}#{id}#{key}"
    end
  end
end
