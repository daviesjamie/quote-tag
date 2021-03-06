# coding: utf-8
require "octopress-quote-tag/version"
require "octopress-quote-tag/utils"
require "jekyll"

module Octopress
  module Tags
    module Quote
      class Tag < Liquid::Block
        FullCiteWithTitle = /(\S.*)\s+(https?:\/\/)(\S+)\s+(.+)/i
        FullCite = /(\S.*)\s+(https?:\/\/)(\S+)/i
        AuthorTitle = /([^,]+),([^,]+)/
        Author =  /(.+)/

        def initialize(tag_name, markup, tokens)
          super

          if tag_name.strip == 'blockquote'
            @options = parse_legacy_markup(markup)
          else
            @options = parse_markup(%w{author title url}, markup)
          end
        end

        # Parse string into hash object
        def parse_markup(keys, markup)
          options = {}
          keys.each do |k|
            value = extract(markup, /\s*#{k}:\s*(("(.+?)")|('(.+?)')|(\S+))/i, [3, 5, 6])
            options[k] = value
          end
          options
        end

        def extract(input, regexp, indices_to_try = [1], default = nil)
          thing = input.match(regexp)
          if thing.nil?
            default
          else
            indices_to_try.each do |index|
              return thing[index] if thing[index]
            end
          end
        end

        # Use legacy regex matching to parse markup
        def parse_legacy_markup(markup)
          options = {}
          if markup =~ FullCiteWithTitle
            options['author'] = $1
            options['url'] = $2 + $3
            options['title'] = $4.strip
          elsif markup =~ FullCite
            options['author'] = $1
            options['url'] = $2 + $3
          elsif markup =~ AuthorTitle
            options['author'] = $1
            options['title'] = $2.strip
          elsif markup =~ Author
            options['author'] = $1
          end
          options
        end

        def render(context)
          quote = "<blockquote>#{Utils.parse_content(super, context).strip}</blockquote>"
          if cap = figcaption
            quote = "<figure class='quote'>#{quote}#{cap}</figure>"
          end
          quote
        end

        def figcaption
          if @options['author'] || @options['url'] || @options['title']
            "<figcaption class='quote-source'>#{author || ''}#{title || ''}</figcaption>"
          end
        end

        def author
          if @options['author']
            if !@options['title']
              text = link(@options['author'])
            else
              text = @options['author']
            end
            "<span class='quote-author'>#{text}</span>"
          end
        end

        def link(text)
          if @options['url']
            "<a class='quote-link' href='#{@options['url']}'>#{text}</a>"
          else
            text
          end
        end

        def title
          if @options['title']
            t = "<cite class='quote-title'>#{link(@options['title'])}</cite>"
            t = " #{t}" if author
            t
          end
        end

        def trim_url(full_url)
          parts = []
          short_url = full_url.match(/https?:\/\/(.+)/)[1][0..30]
          short_url << '…' unless short_url == full_url
          short_url
        end
      end
    end
  end
end


Liquid::Template.register_tag('blockquote', Octopress::Tags::Quote::Tag)
Liquid::Template.register_tag('quote', Octopress::Tags::Quote::Tag)

if defined? Octopress::Docs
  Octopress::Docs.add({
    name:        "Octopress Quote Tag",
    gem:         "octopress-quote-tag",
    description: "Easy HTML5 blockquotes for Jekyll sites",
    path:        File.expand_path(File.join(File.dirname(__FILE__), "../")),
    source_url:  "https://github.com/octopress/quote-tag",
    version:     Octopress::Tags::Quote::VERSION
  })
end
