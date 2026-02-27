#!/usr/bin/env ruby
# frozen_string_literal: true

require "rbconfig"

root = File.expand_path("..", __dir__)
main = File.join(root, "linguatrain.rb")

exec(RbConfig.ruby, main, *ARGV)