#!/usr/bin/env ruby

require "pathname"
require "uri"

root = Pathname.new(__dir__).parent.realpath
failures = []

root.glob("**/*.md").sort.each do |document|
  relative_document = document.relative_path_from(root)
  document.read.scan(/\[[^\]]*\]\(([^)]+)\)/).flatten.each do |raw_target|
    target = raw_target.strip.delete_prefix("<").delete_suffix(">")
    next if target.empty?
    next if target.start_with?("#")
    next if target.match?(/\A(?:https?|mailto):/i)

    path_part = target.split("#", 2).first.split("?", 2).first
    decoded = URI.decode_www_form_component(path_part)
    resolved = document.dirname.join(decoded).cleanpath
    next if resolved.exist?

    failures << "#{relative_document}: missing local link target #{target}"
  end
end

if failures.any?
  warn failures.join("\n")
  exit 1
end

puts "Local Markdown link targets passed."
