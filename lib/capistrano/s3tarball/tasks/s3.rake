strategy = self

namespace :s3 do
  desc 'Check that the repository is reachable'
  task :check => 's3:set_current_revision' do
    on roles(:all) do
      strategy.check
    end
  end

  desc 'Clone the repo to the cache'
  task :clone do
    on roles(:all) do
      if strategy.test
        info t(:mirror_exists, at: repo_path)
      else
        within deploy_path do
          strategy.clone
        end
      end
    end
  end

  desc 'Update the repo mirror to reflect the origin state'
  task :update => 's3:clone' do
    on roles(:all) do
      within repo_path do
        strategy.update
      end
    end
  end

  desc 'Copy repo to releases'
  task :create_release => 's3:update' do
    on roles(:all) do
      within repo_path do
        execute :mkdir, '-p', release_path
        strategy.release
      end
    end
  end

  desc "Determine the revision that will be deployed"
  task :set_current_revision do
    set :current_revision, strategy.fetch_revision
  end
end
