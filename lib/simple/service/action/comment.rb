# returns the comment for an action
class ::Simple::Service::Action::Comment # @private
  attr_reader :short
  attr_reader :full

  def self.extract(action:)
    file, line = action.source_location
    lines = Extractor.extract_comment_lines(file: file, before_line: line)
    full = lines[2..-1].join("\n") if lines.length >= 2
    new short: lines[0], full: full
  end

  def initialize(short:, full:)
    @short, @full = short, full
  end

  module Extractor
    extend self

    # reads the source \a file and turns each non-comment into :code and each comment
    # into a string without the leading comment markup.
    def parse_source(file)
      @parsed_sources ||= {}
      @parsed_sources[file] = _parse_source(file)
    end

    def _parse_source(file)
      File.readlines(file).map do |line|
        case line
        when /^\s*# ?(.*)$/ then $1
        when /^\s*end/ then :end
        end
      end
    end

    def extract_comment_lines(file:, before_line:)
      parsed_source = parse_source(file)

      # go down from before_line until we see a line which is either a comment
      # or an :end. Note that the line at before_line-1 should be the first
      # line of the method definition in question.
      last_line = before_line - 1
      last_line -= 1 while last_line >= 0 && !parsed_source[last_line]

      first_line = last_line
      first_line -= 1 while first_line >= 0 && parsed_source[first_line]
      first_line += 1

      comments = parsed_source[first_line..last_line]
      if comments.include?(:end)
        []
      else
        parsed_source[first_line..last_line]
      end
    end
  end
end
