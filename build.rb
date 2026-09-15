#!/usr/bin/ruby
# Build a single self-contained dist/index.html (Three.js + game inlined).
root = File.dirname(__FILE__)
html = File.read(File.join(root, 'index.html'))
three = File.read(File.join(root, 'lib', 'three.module.js'))

# drop the single consolidated export statement, keep the exported names
names = nil
three = three.sub(/^export \{([^}]*)\};\n?/) { names = $1; '' }
raise 'three.js export block not found' unless names

game = html[/<script type="module">\nimport \* as THREE from '\.\/lib\/three\.module\.js';\n(.*)\n<\/script>/m, 1]
raise 'game script not found in index.html' unless game

Dir.mkdir(File.join(root, 'dist')) unless Dir.exist?(File.join(root, 'dist'))
out = html.sub(/<script type="module">.*<\/script>/m) do
  "<script>\n(() => {\n'use strict';\n#{three}\nconst THREE = {#{names}};\n#{game}\n})();\n</script>"
end
File.write(File.join(root, 'dist', 'index.html'), out)
puts "wrote dist/index.html (#{File.size(File.join(root, 'dist', 'index.html'))} bytes)"
