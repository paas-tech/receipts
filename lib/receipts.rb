require "receipts/version"
require "open-uri"
require "prawn"
require "prawn/table"
require "bidi"
require "arabic-letter-connector"

module Receipts
  autoload :Base, "receipts/base"
  autoload :Invoice, "receipts/invoice"
  autoload :Receipt, "receipts/receipt"
  autoload :Statement, "receipts/statement"

  @@default_font = nil

  # Customize the default font hash
  # default_font = {
  #   bold: "path/to/font",
  #   normal: "path/to/font",
  # }
  def self.default_font=(path)
    @@default_font = path
  end

  def self.default_font
    @@default_font
  end
end
