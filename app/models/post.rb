class Post
  POSTS_DIR = Rails.root.join("content", "posts")

  attr_reader :slug, :title, :date, :published, :summary, :raw_content

  def initialize(attributes = {})
    @slug = attributes[:slug]
    @title = attributes[:title] || "Sem título"
    @date = attributes[:date] ? Date.parse(attributes[:date].to_s) : Date.today
    @published = attributes.fetch(:published, true)
    @summary = attributes[:summary]
    @raw_content = attributes[:raw_content] || ""
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
          hardbreaks: true,
          syntax_highlighter: "theme"
        }
      }
      Commonmarker.to_html(raw_content, options: options)
    end
  end

  def table_of_contents
    @table_of_contents ||= begin
      doc = Nokogiri::HTML::DocumentFragment.parse(content_html)
      doc.css("a.anchor").remove
      doc.css("h2, h3").map do |heading|
        text = heading.text.strip
        heading_id = heading["id"] || text.parameterize
        { title: text, id: heading_id }
      end
    end
  end

  class << self
    def all
      return [] unless Dir.exist?(POSTS_DIR)

      Dir.glob(POSTS_DIR.join("*.md")).map do |file_path|
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
      loader = FrontMatterParser::Loader::Yaml.new(allowlist_classes: [ Date, Time ])
      parsed = FrontMatterParser::Parser.new(:md, loader: loader).call(File.read(file_path))
      front_matter = parsed.front_matter
      filename = File.basename(file_path, ".md")

      # Extrai slug removendo data do nome do arquivo se presente (ex: 2026-05-21-threads-em-ruby -> threads-em-ruby)
      extracted_slug = front_matter["slug"] || filename.sub(/\A\d{4}-\d{2}-\d{2}-/, "")

      new(
        slug: extracted_slug,
        title: front_matter["title"],
        date: front_matter["date"],
        published: front_matter.fetch("published", true),
        summary: front_matter["summary"],
        raw_content: parsed.content
      )
    end
  end
end
