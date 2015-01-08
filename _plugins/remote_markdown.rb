require 'net/http'

module Jekyll

  class RemoteMarkdownTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
		super

		text.strip!
		if not text =~ URI::regexp(['http','https','ftp','ftps'])
			raise "remote_markdown: invalid URI given #{text}" 
		end
		uri = URI(text)

		mdexts = [".markdown",".mkdown",".mkdn",".mkd",".md"]
		if not mdexts.include?(File.extname(uri.path))
			raise "remote_markdown: URI file extension not in #{mdexts.to_s}"
		end

        res = Net::HTTP.get_response(uri)
		raise "resource unavailable" if not res.is_a?(Net::HTTPSuccess)

		@content = res.body
    end

    def render(context)
	  @content
    end
  end
end

Liquid::Template.register_tag('remote_markdown', Jekyll::RemoteMarkdownTag)
