# frozen_string_literal: true

# TODO: Add in tests for the actual containers... maybe docker-api already has
# some we can pinch

require 'rspec/autorun'
require_relative 'lib/miniexec'

describe MiniExec do
  it 'parses basic jobs' do
    exec = MiniExec.new 'basic-test'
    expect(exec.script).to eq("echo 'hello'\necho 'goodbye'")
  end

  it 'uses the correct image' do
    exec1 = MiniExec.new 'basic-test'
    exec2 = MiniExec.new 'no-image-test'
    expect(exec1.instance_variable_get(:@image)).to eq('ubuntu:latest')
    expect(exec2.instance_variable_get(:@image)).to eq('debian:latest')
  end

  it 'compiles scripts correctly' do
    exec = MiniExec.new 'before-after-script-test'
    expect(exec.script).to eq("one\ntwo\nthree\n\nfour")
  end

  it 'handles anchors in .gitlab-ci.yml' do
    exec = MiniExec.new 'anchor-test'
    expect(exec.script).to eq("one\ntwo\nthree")
  end
end
