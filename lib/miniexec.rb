# frozen_string_literal: true

# Main class
module MiniExec
  class MiniExec
    require 'logger'
    require 'docker-api'
    require 'json'
    require 'tempfile'
    require 'yaml'
    require 'git'
    require_relative './util'
    # Class instance variables
    @project_path = '.'
    @workflow_file = '.gitlab-ci.yml'

    class << self
      attr_accessor :project_path, :workflow_file
    end

    def self.config(project_path: @project_path, workflow_file: @workflow_file)
      @project_path = project_path
      @workflow_file = workflow_file
      self
    end

    attr_accessor :script
    attr_reader :runlog

    def initialize(job,
                   project_path: self.class.project_path,
                   docker_url: nil,
                   binds: [],
                   env: {},
                   mount_cwd: true)
      @job_name = job
      @project_path = project_path
      @workflow = YAML.load(File.read("#{@project_path}/#{MiniExec.workflow_file}"))
      @job = @workflow[job]
      @job['name'] = job
      @default_image = @workflow['image'] || 'debian:buster-slim'
      @image = set_job_image
      @entrypoint = set_job_entrypoint
      @binds = binds
      @mount_cwd = mount_cwd
      @env = {}
      [
        env,
        gitlab_env,
        @workflow['variables'],
        @job['variables']
      ].each do |var_set|
        @env.merge!(var_set.transform_values { |v| Util.expand_var(v.to_s, @env) }) if var_set
      end
      @script = compile_script
      @runlog = []
      configure_logger
      Docker.options[:read_timeout] = 6000
      Docker.url = docker_url if docker_url
    end

    def run_job
      script_path = "/tmp/#{@job['name']}.sh"
      @logger.info "Fetching image #{@image}"
      Docker::Image.create(fromImage: @image)
      @logger.info 'Image fetched'

      config = Docker::Image.get(@image).info['Config']
      working_dir = if config['WorkingDir'].empty?
                      '/gitlab'
                    else
                      config['WorkingDir']
                    end
      binds = @binds
      binds.push "#{ENV['PWD']}:#{working_dir}" if @mount_cwd
      Dir.chdir(@project_path) do
        @logger.info 'Creating container'
        container = Docker::Container.create(
          Image: @image,
          Cmd: ['/usr/bin/env', 'bash', script_path],
          WorkingDir: working_dir,
          Entrypoint: @entrypoint,
          Volumes: binds.map { |b| { b => { path_parent: 'rw' } } }.inject(:merge),
          Env: @env.map { |k, v| "#{k}=#{v}" }
        )
        container.store_file(script_path, @script)
        container.start({ Binds: [@binds] })
        container.tap(&:start).attach { |_, chunk| puts chunk; @runlog.push chunk}
        @logger.info 'Job finished. Removing container.'
        # After running, we want to remove the container.
        container.remove
        @logger.info 'Container removed.'
      end
    end

    private

    def set_job_image
      if @job['image']
        image = @job['image'] if @job['image'].instance_of?(String)
        image = @job['image']['name'] if @job['image'].instance_of?(Hash)
      end

      image || @default_image
    end

    def set_job_entrypoint
      @job['image']['entrypoint'] if @job['image'].instance_of?(Hash)
    end

    # Set gitlab's predefined env vars as per
    # https://docs.gitlab.com/ee/ci/variables/predefined_variables.html
    def gitlab_env
      g = Git.open(@project_path)
      commit = g.gcommit 'HEAD'
      tag = g.tags.find { |t| t.objectish == commit.sha }
      commit_branch = g.branch.name
      if tag.nil?
        ref_name = g.branch.name
        commit_tag = nil
      else
        ref_name = tag.name
        commit_tag = ref_name
      end
      {
        'CI': true,
        'CI_COMMIT_REF_SHA': commit.sha,
        'CI_COMMIT_SHORT_SHA': commit.sha[0, 8],
        'CI_COMMIT_REF_NAME': ref_name,
        'CI_COMMIT_BRANCH': commit_branch,
        'CI_COMMIT_TAG': commit_tag,
        'CI_COMMIT_MESSAGE': commit.message,
        'CI_COMMIT_REF_PROTECTED': false,
        'CI_COMMIT_TIMESTAMP': commit.date.strftime('%FT%T')
      }.transform_keys(&:to_s)
    end

    def variables
      globals = @workflow['variables'] || {}
      job_locals = @job['variables'] || {}
      globals.merge job_locals
    end

    def configure_logger
      @logger = Logger.new($stdout)
      @logger.formatter = proc do |severity, _, _, msg|
        "[#{severity}]: #{msg}\n"
      end
      @logger.level = ENV['LOGLEVEL'] || Logger::INFO
    end

    def compile_script
      before_script = @job['before_script'] || ''
      script = @job['script'] || ''
      after_script = @job['after_script'] || ''
      [before_script, script, after_script].flatten.join("\n").strip
    end
  end
end
