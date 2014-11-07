# encoding: utf-8

require 'yaml'
require 'ostruct'
require 'htmlentities'

# FontAwesome class
class FontAwesome
  attr_reader :icons

  ICONS = YAML.load_file(File.expand_path('./icons.yml'))['icons']

  # FontAwesome::Icon class
  class Icon
    attr_reader :id, :unicode

    def initialize(id)
      @id = id
      unicode = find_unicode_from_id(id)
      @unicode = unicode ? unicode : find_unicode_from_aliases(id)
    end

    def find_unicode_from_id(id)
      found_icon = ICONS.find { |icon| icon['id'] == id }
      found_icon ? found_icon['unicode'] : nil
    end

    def find_unicode_from_aliases(id)
      found_icon = ICONS.find do |icon|
        icon['aliases'].include?(id) if icon['aliases']
      end
      found_icon ? found_icon['unicode'] : nil
    end
  end

  def self.argv(argv)
    split_argv = argv[0].chomp.split('|||')
    os = OpenStruct.new
    os.icon_id = split_argv[0]
    os.icon_unicode = split_argv[1]
    os
  end

  def self.css_class_name(icon_id)
    "fa-#{icon_id}"
  end

  def self.character_reference(icon_unicode)
    HTMLEntities.new.decode("&#x#{icon_unicode};")
  end

  def self.url(icon_id)
    "http://fontawesome.io/icon/#{icon_id}/"
  end

  def initialize(queries = [])
    icon_filenames = glob_icon_filenames
    @icons = icon_filenames.map { |name| Icon.new(name) }
    select!(queries)
  end

  def select!(queries, icons = @icons)
    queries.each do |q|
      # use reject! for ruby 1.8 compatible
      icons.reject! { |icon| icon.id.index(q.downcase) ? false : true }
    end

    icons
  end

  def item_hash(icon)
    {
      :uid => icon.id,
      :title => icon.id,
      :subtitle => "Paste class name: fa-#{icon.id}",
      :arg => "#{icon.id}|||#{icon.unicode}",
      :icon => { :type => 'default', :name => "./icons/fa-#{icon.id}.png" },
      :valid => 'yes',
    }
  end

  def item_xml(options = {})
    <<-XML
<item arg="#{options[:arg]}" uid="#{Time.new.to_i}-#{options[:uid]}">
<title>#{options[:title]}</title>
<subtitle>#{options[:subtitle]}</subtitle>
<icon>#{options[:icon][:name]}</icon>
</item>
    XML
  end

  def to_alfred
    item_xml = @icons.map { |icon| item_xml(item_hash(icon)) }.join
    item_xml.gsub!(/(\r\n|\r|\n)/, '')
    puts xml = "<?xml version='1.0'?><items>#{item_xml}</items>"
    xml
  end

  private

  def glob_icon_filenames
    Dir.glob(File.expand_path('./icons/fa-*.png')).map do |path|
      md = /\/fa-(.+)\.png/.match(path)
      md && md[1] ? md[1] : nil
    end.compact.uniq.sort
  end
end
