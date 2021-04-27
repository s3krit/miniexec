# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'miniexec'
  s.version = '0.0.9'
  s.summary = 'exec a gitlab job'
  s.description = 'A minimal interpretor/executor for .gitlab-ci.yml'
  s.authors = ['Martin Pugh']
  s.email = 'pugh@s3kr.it'
  s.files = ['lib/miniexec.rb', 'bin/miniexec']
  s.executables << 'miniexec'
  s.homepage = 'https://github.com/s3krit/miniexec'
  s.license = 'AGPL-3.0-or-later'
  s.required_ruby_version = '>= 2.0'
end
