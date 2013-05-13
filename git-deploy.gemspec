# encoding: utf-8
require File.expand_path('../lib/git_deploy/version', __FILE__)

Gem::Specification.new do |gem|
  gem.summary = "Simple git push-based application deployment"
  gem.description = "A tool to install useful git hooks on your remote repository to enable push-based, Heroku-like deployment on your host."
  gem.authors  = ['Mislav Marohnić','Stoyan Zhekov']
  gem.email    = 'zh@zhware.net'
  gem.homepage = 'https://github.com/zh/git-deploy'


  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.name          = 'git-deploy'
  gem.require_paths = ["lib"]
  gem.version       = GitDeploy::VERSION

  gem.add_dependency 'thor'
  gem.add_dependency 'net-ssh'
  gem.add_dependency 'net-scp'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rake-notes'
end
