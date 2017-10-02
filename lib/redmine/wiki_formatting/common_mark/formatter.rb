require "cgi/util"
require "commonmarker"

module Redmine
  module WikiFormatting
    module CommonMark
      class HTML < CommonMarker::HtmlRenderer
        include ActionView::Helpers::TagHelper
        include Redmine::Helpers::URL

        def link(node)
          return unless uri_with_safe_scheme?(node.url)

          out('<a href="', node.url.nil? ? '' : escape_href(node.url), '"')
          if node.title && !node.title.empty?
            out(' title="', escape_html(node.title), '"')
          end
          unless node.url && node.url.start_with?("/")
            out(' class="external"')
          end
          out('>', :children, '</a>')
        end

        def code_block(node)
          language = if node.fence_info && !node.fence_info.empty?
                       node.fence_info.split(/\s+/)[0]
                     else
                       nil
                     end
          html = if language.present? && Redmine::SyntaxHighlighting.language_supported?(language)
                   "<pre><code class=\"#{CGI.escapeHTML(language)} syntaxhl\">" +
                     Redmine::SyntaxHighlighting.highlight_by_language(code, language) +
                     "</code></pre>"
                 else
                   "<pre>" + CGI.escapeHTML(code) + "</pre>"
                 end
          out(html)
        end

        def image(node)
          out('<img src="', escape_href(node.url), '"')
          plain do
            out(' alt="', :children, '"')
          end
          if node.title && !node.title.empty?
            out(' title="', escape_html(node.title), '"')
          end
          out('>')
        end
      end

      class Formatter < Redmine::WikiFormatting::Markdown::Formatter
        private

        def formatter
          @@formater = Redmine::WikiFormatting::CommonMark::FormatterWrapper.new
        end
      end

      class FormatterWrapper
        EXTENSIONS = [:autolink, :table]

        def initialize
          @renderer = Redmine::WikiFormatting::CommonMark::HTML.new(extensions: EXTENSIONS)
        end

        def render(text)
          doc = CommonMarker.render_doc(text, :DEFAULT, EXTENSIONS)
          @renderer.render(doc)
        end
      end
    end
  end
end
