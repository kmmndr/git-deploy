require 'thor'
require 'net/ssh'
require 'net/scp'

class GitDeploy < Thor
  LOCAL_DIR = File.expand_path('..', __FILE__)

  require 'git_deploy/configuration'
  require 'git_deploy/ssh_methods'
  include Configuration
  include SSHMethods

  class_option :remote, :aliases => '-r', :type => :string, :default => 'origin'
  class_option :noop, :aliases => '-n', :type => :boolean, :default => false

  desc "init", "Generates deployment customization scripts for your app"
  def init
    require 'git_deploy/generator'
    Generator::start([])
  end

  desc "setup", "Create the remote git repository and install push hooks for it"
  method_option :shared, :aliases => '-g', :type => :boolean, :default => true
  method_option :sudo, :aliases => '-s', :type => :boolean, :default => false
  def setup
    sudo = options.sudo? ? "#{sudo_cmd} " : ''

    unless run_test("test -x #{deploy_to}")
      run ["#{sudo}mkdir -p #{deploy_to}"] do |cmd|
        cmd << "#{sudo}chown $USER #{deploy_to}" if options.sudo?
        cmd
      end
    end

    run [] do |cmd|
      cmd << "chmod g+ws #{deploy_to}" if options.shared?
      cmd << "cd #{deploy_to}"
      cmd << "git init #{options.shared? ? '--shared' : ''}"
      cmd << "sed -i'' -e 's/master/#{branch}/' .git/HEAD" unless branch == 'master'
      cmd << "git config --bool receive.denyNonFastForwards false" if options.shared?
      cmd << "git config receive.denyCurrentBranch ignore"
    end

    invoke :hooks
  end

  desc "hooks", "Installs git hooks to the remote repository"
  def hooks
    hooks_dir = File.join(LOCAL_DIR, 'hooks')
    local_bin_dir = File.join(LOCAL_DIR, 'bin')
    remote_dir = "#{deploy_to}/.git/hooks"
    remote_bin_dir = "#{deploy_to}/.git/bin"

    scp_upload "#{hooks_dir}/post-receive.sh" => "#{remote_dir}/post-receive"
    #scp_upload "#{hooks_dir}/pre-receive.sh" => "#{remote_dir}/pre-receive"
    #run "chmod +x #{remote_dir}/post-receive #{remote_dir}/pre-receive"
    run "chmod +x #{remote_dir}/post-receive"
    run "rm -rf #{remote_bin_dir}"
    run "mkdir -p #{remote_bin_dir}"
    #scp_upload "#{local_bin_dir}/functions.sh" => "#{remote_bin_dir}/functions.sh"
    #scp_upload "#{local_bin_dir}/detect.sh" => "#{remote_bin_dir}/detect.sh"
    #scp_upload "#{local_bin_dir}/init-ruby.sh" => "#{remote_bin_dir}/init-ruby.sh"

    #Dir.glob("lib/*.{rb,sh}").collect { |file| puts file.to_s }
    #Dir.glob("*.{rb,sh}").each do |file|
    Dir.new(local_bin_dir).each do |file|
      unless file == '.' || file == '..'
        scp_upload "#{local_bin_dir}/#{file}" => "#{remote_bin_dir}/#{file}"
        run "chmod +x #{remote_bin_dir}/#{file}" unless File.directory?("#{local_bin_dir}/#{file}")
      end
    end
    #run "chmod +x #{remote_bin_dir}/detect.sh"
    #run "chmod +x #{remote_bin_dir}/compile-ruby.sh"
  end
  
  desc "restart", "Restarts the application on the server"
  def restart
    run "cd #{deploy_to} && deploy/restart | tee -a log/deploy.log"
  end

  desc "rollback", "Rolls back the checkout to before the last push"
  def rollback
    run "cd #{deploy_to} && git reset --hard HEAD@{1}"
    if run_test("test -x #{deploy_to}/deploy/rollback")
      run "cd #{deploy_to} && deploy/rollback | tee -a log/deploy.log"
    else
      invoke :restart
    end
  end

  desc "log", "Shows the last part of the deploy log on the server"
  method_option :tail, :aliases => '-t', :type => :boolean, :default => false
  method_option :lines, :aliases => '-l', :type => :numeric, :default => 20
  def log(n = nil)
    tail_args = options.tail? ? '-f' : "-n#{n || options.lines}"
    run "tail #{tail_args} #{deploy_to}/log/deploy.log"
  end

  desc "upload <files>", "Copy local files to the remote app"
  def upload(*files)
    files = files.map { |f| Dir[f.strip] }.flatten
    abort "Error: Specify at least one file to upload" if files.empty?

    scp_upload files.inject({}) { |all, file|
      all[file] = File.join(deploy_to, file)
      all
    }
  end

  desc "rake", "Run rake command on server"
  method_option :task, :type => :array, :aliases => '-t', :required => true
  method_option :env, :aliases => '-e', :default => 'production'
  def rake(n = nil)
    task = options[:task]
    rails_env = options[:env]

    #load_rbenv(rails_env)
    run_with_env [] do |cmd|
      cmd << "cd #{deploy_to}"
      cmd << "RAILS_ENV=#{rails_env} rake #{task.join(' ')}"
    end
  end

  desc "config", "Setup config vars"
  method_option :add, :aliases => '-a' 
  method_option :del, :aliases => '-d' 
  def config(n = nil)
    add_param = options[:add]
    del_param = options[:del]
    remote_bin_dir = "#{deploy_to}/.git/bin"

    # by default, list all params
    config_opts = ""
    if add_param
      puts "Adding config vars: #{add_param}"
      config_opts = "add #{add_param}"
    end
    if del_param
      puts "Removing config vars: #{del_param}"
      config_opts = "del #{del_param}"
    end

    run [] do |cmd|
      cmd << "cd #{deploy_to}"
      cmd << "#{remote_bin_dir}/params.sh #{config_opts}"
    end
  end

  no_tasks do
    def load_rbenv(rails_env)
      run "export RAILS_ENV=#{rails_env}; env"
      run "env"
    end
  end
end

__END__
Multiple hosts:
# deploy:
  invoke :code
  command = ["cd #{deploy_to}"]
  command << ".git/hooks/post-reset `cat .git/ORIG_HEAD` HEAD 2>&1 | tee -a log/deploy.log"

# code:
command = ["cd #{deploy_to}"]
command << source.scm('fetch', remote, "+refs/heads/#{branch}:refs/remotes/origin/#{branch}")
command << source.scm('reset', '--hard', "origin/#{branch}")
