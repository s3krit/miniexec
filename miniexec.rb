#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'logger'
require 'docker-api'
require 'json'
require 'tempfile'
require 'yaml'
require 'optparse'

# a
class MiniExec
  # Class instance variables
  @project_path = '.'
  @workflow_file = '.gitlab-ci.yml'

  class << self
    attr_accessor :project_path, :workflow_file
  end

  def self.config(project_path: @project_path, workflow_file: @workflow_file)
    @project_path = project_path
    @class = workflow_file
    self
  end

  attr_accessor :script

  def initialize(job,
                 project_path: self.class.project_path,
                 workflow_file: self.class.workflow_file,
                 docker_url: nil,
                 binds: [])
    @job_name = job
    @project_path = project_path
    workflow = YAML.load(File.read("#{@project_path}/#{workflow_file}"))
    @job = workflow[job]
    @job['name'] = job
    @default_image = workflow['image'] || 'debian:buster-slim'
    @image = set_job_image
    @script = compile_script
    @binds = binds

    @logger = Logger.new($stdout)
    @logger.level = ENV['LOGLEVEL'] || Logger::WARN
    Docker.options[:read_timeout] = 6000
    Docker.url = docker_url if docker_url
  end

  def run_job
    script_path = "/tmp/#{@job['name']}.sh"
    @logger.debug "Fetching image #{@image}"
    Docker::Image.create(fromImage: @image)
    @logger.debug 'Image fetched'
    Dir.chdir(@project_path) do
      @logger.debug 'Creating container'
      container = Docker::Container.create(
        #Cmd: ['/bin/bash', script_path],
        Cmd: ['sleep', '6000'],
        Image: @image,
        Binds: ['/home/x/parity/code/polkadot/:/builds/']
      )
      container.store_file(script_path, @script)
      binding.pry
      container.start
      container.tap(&:start).attach { |_, chunk| @logger.info chunk }
    end
  end

  private

  def set_job_image
    return @job['image'] if @job['image']

    @default_image
  end

  def compile_script
    before_script = @job['before_script'] || []
    script = @job['script'] || []
    after_script = @job['after_script'] || []
    (before_script + script + after_script).flatten.join("\n")
  end
end

options = {
  binds: []
}

OptionParser.new do |opts|
  opts.banner = 'Usage: miniexec.rb [options]'
  opts.separator ''
  opts.separator 'specific options:'

  opts.on('-p', '--path PATH', 'Path to the repository containing a valid .gitlab-ci.yml') do |path|
    options[:path] = path
  end

  opts.on('-j', '--job JOBNAME', 'Specify the gitlab job to run') do |job|
    options[:job] = job
  end

  opts.on('-b', '--bind BIND', 'Specify a bind mapping',
          'Example: /some/local/dir:/mapping/in/container') do |bind|
    options[:binds].push bind
  end
end.parse!

raise OptionParser::MissingArgument, 'Specify a job with -j' if options[:job].nil?
raise OptionParser::MissingArgument, 'Specify a job with -p' if options[:path].nil?

MiniExec.config(project_path: options[:path])
exec = MiniExec.new options[:job],
                    docker_url: 'unix:///var/run/user/1000/podman/podman.sock',
                    binds: options[:binds]

exec.run_job
