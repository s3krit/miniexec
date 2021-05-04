# frozen_string_literal: true

module MiniExec
  module Util
    # Given a string and an env, replace any instance of shell-style variables
    # with their value in the env. NOT POSIX COMPLIANT, just mostly hacky so
    # I can get gitlab-ci.yml parsing to work properly. Required in MiniExec
    # because of https://docs.gitlab.com/ee/ci/variables/where_variables_can_be_used.html#gitlab-internal-variable-expansion-mechanism
    def self.expand_var(string, env)
      # Match group 1 = the text to replace
      # Match group 2 = the key from env we want to replace it with
      regex = /(\${?(\w+)}?)/
      string.scan(regex).uniq.each do |match|
        string.gsub! match[0], env[match[1]].to_s
      end
      string
    end
  end
end
