module Receipts
  class Base < Prawn::Document
    attr_accessor :title, :company

    class << self
      attr_reader :title
    end

    def initialize(attributes = {})
      super(page_size: attributes.delete(:page_size) || "LETTER")
      setup_fonts attributes.fetch(:font, Receipts.default_font)

      @title = attributes.fetch(:title, self.class.title)
      @bidi = Bidi.new

      generate_from(attributes)
    end

    def generate_from(attributes)
      return if attributes.empty?

      company = attributes.fetch(:company)
      header company: company, height: attributes.fetch(:logo_height, 16)
      render_details attributes.fetch(:details)
      render_billing_details company: company, recipient: attributes.fetch(:recipient)
      render_line_items(
        line_items: attributes.fetch(:line_items),
        column_widths: attributes[:column_widths]
      )
      render_footer attributes.fetch(:footer, default_message(company: company))
    end

    def setup_fonts(custom_font = nil)
      if !!custom_font
        font_families.update "Primary" => custom_font
        font "Primary"
      end

      font_size 8
    end

    def load_image(logo)
      if logo.is_a? String
        logo.start_with?("http") ? URI.parse(logo).open : File.open(logo)
      else
        logo
      end
    end

    def header(company: {}, height: 16)
      logo = company[:logo]

      if logo.nil?
        text company.fetch(:name), align: :left, style: :bold, size: 16, color: "4b5563"
      else
        image load_image(logo), height: height, position: :left
      end

      move_up height
      text localize(title), style: :bold, size: 16, align: :right
    end

    def render_details(details, margin_top: 16)
      rtl_details = details.map { |detail| localize(detail.reverse) }

      move_down margin_top
      table(rtl_details, position: :right, cell_style: {borders: [], inline_format: true, padding: [0, 0, 2, 8], align: :right})
    end

    def render_billing_details(company:, recipient:, margin_top: 16, display_values: nil)
      move_down margin_top

      display_values ||= company.fetch(:display, [:address, :phone, :email])
      company_details = company.values_at(*display_values).compact.join("\n")

      line_items = [
        [
          {content: localize(Array(recipient).join("\n")), padding: [0, 0, 0, 12]},
          {content: "<b>#{localize(company.fetch(:name))}</b>\n#{localize(company_details)}", padding: [0, 0, 0, 12]}
        ]
      ]
      table(line_items, width: bounds.width, cell_style: {borders: [], inline_format: true, overflow: :expand, align: :right})
    end

    def render_line_items(line_items:, margin_top: 30, column_widths: nil)
      move_down margin_top

      borders = line_items.length - 2

      table_options = {
        width: bounds.width,
        cell_style: {border_color: "eeeeee", inline_format: true, align: :right},
        column_widths: column_widths
      }.compact

      rtl_line_items = line_items.map { |line_item| localize(line_item.reverse) }

      table(rtl_line_items, table_options) do
        cells.padding = 6
        cells.borders = []
        row(0..borders).borders = [:bottom]
      end
    end

    def render_footer(message, margin_top: 30)
      move_down margin_top
      text localize(message), inline_format: true, align: :right
    end

    def default_message(company:)
      "<color rgb='326d92'><link href='mailto:#{company.fetch(:email)}?subject=لدي سؤال بخصوص فاتورة'><b>#{company.fetch(:email)}</b></link></color> #{localize("اذا كان لديكم أسئلة، اتصلوا بنا في أي وقت عن طريق الايميل ")}"
    end

    def localize(text)
      if text.is_a?(Array)
        text.map { |t| process_bidi_with_tags(t) }
      else
        return unless text

        process_bidi_with_tags(text)
      end
    end

    def process_bidi_with_tags(text)
      parsed_text = Nokogiri::HTML.fragment(text)

      parsed_text.traverse do |node|
        if node.text?
          node.content = @bidi.to_visual(node.text.connect_arabic_letters)
        end
      end

      parsed_text.to_html
    end
  end
end
