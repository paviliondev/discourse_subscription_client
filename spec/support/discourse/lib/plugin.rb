# frozen_string_literal: true

module Plugin
  class Metadata
    FIELDS ||= %i[name about version authors contact_emails url required_version transpile_js]
    attr_accessor(*FIELDS)

    def self.parse(text)
      metadata = new
      text.each_line { |line| break unless metadata.parse_line(line) }
      metadata
    end

    def parse_line(line)
      line = line.strip

      unless line.empty?
        return false unless line[0] == "#"

        attribute, *description = line[1..].split(":")

        description = description.join(":")
        attribute = attribute.strip.gsub(/ /, "_").to_sym

        public_send("#{attribute}=", description.strip) if FIELDS.include?(attribute)
      end

      true
    end
  end
end
