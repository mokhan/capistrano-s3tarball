require "capistrano/scm/plugin"

module Capistrano
  class S3Plugin < ::Capistrano::SCM::Plugin
    def set_defaults
      set :current_revision, ENV.fetch('BUILD_VERSION', `git ls-remote #{fetch(:git_repo)} #{fetch(:git_branch)}`)[0...7]
      set :git_repo, ''
      set :aws_profile, 'default'
      set :git_branch, ENV['BRANCH']
      set :bucket_name, ''
    end

    def define_tasks
      eval_rakefile File.expand_path("../tasks/s3.rake", __FILE__)
    end

    def register_hooks
      after "deploy:new_release_path", "s3:create_release"
      before "deploy:check", "s3:check"
    end

    def test
      backend.test " [ -f #{repo_path}/#{tarball} ] "
    end

    def check
      s3 "ls s3://#{fetch(:bucket_name)}/#{fetch(:application)}/#{tarball}"
    end

    def clone
      backend.execute(:mkdir, '-p', repo_path)
    end

    def update
      source = "s3://#{fetch(:bucket_name)}/#{fetch(:application)}/#{tarball}"
      destination = "#{repo_path}/#{tarball}"
      s3 "cp #{source} #{destination}"
    end

    def release
      path = "#{repo_path}/#{tarball}"
      strip = "--strip-components=1"
      backend.execute(:tar, "-xvzf", path, strip, "-C", release_path)
    end

    def s3(*args)
      args.unshift "--profile #{fetch(:aws_profile)}"
      args.unshift :s3
      args.unshift :aws
      backend.execute(*args)
    end

    def tarball
      "#{fetch(:application)}-#{fetch(:current_revision)}.tar.gz"
    end
  end
end

