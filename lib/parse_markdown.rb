# frozen_string_literal: true

require 'date'
require 'commonmarker'
require 'front_matter_parser'
require 'nokogiri'
require 'rouge'

class ParseMarkdown 
  class RetroTheme < Rouge::Themes::Base16
    name 'retro_terminal'

    palette base00: '#000000'
    palette base01: '#111827'
    palette base02: '#374151'
    palette base03: '#6b7280' # Comments: Slate Gray
    palette base04: '#9ca3af'
    palette base05: '#d1d5db' # Text: Soft Gray
    palette base06: '#e5e7eb'
    palette base07: '#ffffff' # Pure White
    palette base08: '#f43f5e' # Numbers / Symbols: Bright Magenta/Rose
    palette base09: '#f43f5e'
    palette base0A: '#ffffff' # Classes / Constants: Pure White
    palette base0B: '#4ade80' # Strings: Phosphor Matrix Green
    palette base0C: '#38bdf8' # Functions / Regex: Bright Cyan
    palette base0D: '#38bdf8'
    palette base0E: '#fbbf24' # Keywords: Amber Yellow
    palette base0F: '#ab7967'

    style Text, fg: :base05
    style Keyword, fg: :base0E, bold: true
    style Keyword::Declaration, fg: :base0E, bold: true
    style Keyword::Type, fg: :base0E, bold: true
    style Keyword::Constant, fg: :base0E, bold: true
    style Name::Function, Name::Builtin, Name::Builtin::Pseudo, fg: :base0D
    style Name::Class, Name::Constant, Name::Namespace, fg: :base0A, bold: true
    style Literal::String, fg: :base0B
    style Literal::Number, fg: :base08
    style Comment, fg: :base03, italic: true
    style Operator, fg: :base08
  end

  ROUGE_FORMATTER = Rouge::Formatters::HTMLInline.new(RetroTheme.new)
  POSTS_DIR = File.expand_path('../content/posts', __dir__)

  attr_reader :slug, :title, :date, :published, :summary, :raw_content

  def initialize(attributes = {})
    @slug = attributes[:slug]
    @title = attributes[:title] || 'Sem título'
    @date = attributes[:date] ? Date.parse(attributes[:date].to_s) : Date.today
    @published = attributes.fetch(:published, true)
    @summary = attributes[:summary]
    @raw_content = attributes[:raw_content] || ''
  end

  def year
    date.year
  end

  def formatted_date
    "<#{date.strftime('%d/%m')}>"
  end

  def content_html
    @content_html ||= begin
      options = {
        render: {
          hardbreaks: true
        }
      }
      plugins = {
        syntax_highlighter: nil
      }
      html = Commonmarker.to_html(raw_content, options: options, plugins: plugins)
      highlight_code_blocks(html)
    end
  end

  def table_of_contents
    @table_of_contents ||= begin
      doc = Nokogiri::HTML::DocumentFragment.parse(content_html)
      doc.css('a.anchor').remove
      doc.css('h2, h3').map do |heading|
        text = heading.text.strip
        heading_id = heading['id'] || text.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')
        { title: text, id: heading_id }
      end
    end
  end

  private

  def highlight_code_blocks(html)
    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css('pre').each do |pre|
      code_node = pre.at_css('code')
      next unless code_node

      raw_code = code_node.text
      lang = (pre['lang'] || '').strip
      if lang.empty? && code_node['class'] =~ /language-([^\s]+)/
        lang = Regexp.last_match(1)
      end

      lexer = Rouge::Lexer.find_fancy(lang, raw_code) || Rouge::Lexers::PlainText.new
      code_node.inner_html = ROUGE_FORMATTER.format(lexer.lex(raw_code))
    end
    doc.to_html
  end

  class << self
    def all
      return [] unless Dir.exist?(POSTS_DIR)

      Dir.glob(File.join(POSTS_DIR, '*.md')).map do |file_path|
        from_file(file_path)
      end.select(&:published).sort_by(&:date).reverse
    end

    def all_by_year
      all.group_by(&:year)
    end

    def find_by_slug(slug)
      all.find { |post| post.slug == slug }
    end

    def from_file(file_path)
      loader = FrontMatterParser::Loader::Yaml.new(allowlist_classes: [Date, Time])
      parsed = FrontMatterParser::Parser.new(:md, loader: loader).call(File.read(file_path, encoding: 'utf-8'))
      front_matter = parsed.front_matter
      filename = File.basename(file_path, '.md')

      extracted_slug = front_matter['slug'] || filename.sub(/\A\d{4}-\d{2}-\d{2}-/, '')

      new(
        slug: extracted_slug,
        title: front_matter['title'],
        date: front_matter['date'],
        published: front_matter.fetch('published', true),
        summary: front_matter['summary'],
        raw_content: parsed.content
      )
    end
  end
end
