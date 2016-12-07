#!/usr/bin/env ruby

f = open("./MarkdownLiks.txt", 'w')

File.open("./oneTabExport.txt").readlines.map(&:strip).each do |line|
  
  values = line.split(" | ", 2)
  # split the srting by first " | " -> 2 values
  # values.first = link
  # values.last = description
  desc = values.last
  link = values.first
  if values.first[0] == "-"
    link = values.first[2..-1]
  end
  f.puts "    - " + "[" + desc + "](" + link + ")"
end