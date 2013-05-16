require 'thor'
require 'net/ssh'
require 'net/scp'
require 'pathname'

module GitDeploy
  LOCAL_DIR = File.expand_path('..', __FILE__)

  class Deployer < Thor
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

    desc "template", "Install language/service template on remote"
    method_option :list, :aliases => '-l', :type => :boolean #, :default => true
    method_option :remote_list, :aliases => '-L' #, :required => true
    method_option :detect, :aliases => '-d' #, :required => true
    method_option :init, :aliases => '-i' #, :required => true
    method_option :compile, :aliases => '-c' #, :required => true
    def template
      lang = options[:language]
      detect = options[:detect]
      init = options[:init]
      compile = options[:compile]
      list = options[:list] || !(options[:init] && options[:detect] && options[:compile])
      remote_list = options[:remote_list]
      summary = []

      local_template_dir = File.join(LOCAL_DIR, 'templates')
      local_detect_dir = File.join(local_template_dir, 'detect')
      local_init_dir = File.join(local_template_dir, 'init')
      local_compile_dir = File.join(local_template_dir, 'compile')

      remote_bin_dir = "#{deploy_to}/.git/bin"
      #remote_detect_dir = "#{remote_bin_dir}/detect"
      #remote_init_dir = "#{remote_bin_dir}/init"
      #remote_compile_dir = "#{remote_bin_dir}/compile"

      detect_pattern = detect.nil? ? '*' : "#{detect}*"
      init_pattern = init.nil? ? '*' : "#{init}*"
      compile_pattern = compile.nil? ? '*' : "#{compile}*"

      puts "LANGUAGE #{lang} --> #{detect_pattern} #{init_pattern}"
      puts "list #{options[:list]} #{list}"

#      Dir.glob("#{local_detect_dir}/#{detect_pattern}").each do |file|
#        puts "detect : #{file}" if list
#        scp_upload file => File.join(remote_detect_dir,File.basename(file)) if detect
#      end
#
#      Dir.glob("#{local_init_dir}/#{init_pattern}").each do |file|
#        puts "init : #{file}" if list
#        scp_upload file => File.join(remote_init_dir,File.basename(file)) if init
#      end

      scripts = {
        :detect => "#{local_detect_dir}/#{detect_pattern}",
        :init => "#{local_init_dir}/#{init_pattern}",
        :compile => "#{local_compile_dir}/#{compile_pattern}"
      }
      scripts.each do |k,v|
        if list || options[k]
          summary << "local #{k}"
          local_template_pathname = Pathname.new local_template_dir
          Dir.glob("#{v}").each do |file|
            file_pathname = Pathname.new file
            relative = file_pathname.relative_path_from local_template_pathname
puts "relative #{relative}"
            file_base = File.basename(file)
            summary << "  - #{relative}"
            if options[k]
puts "#{file} --> #{file_base}"
              remote_key_dir = File.dirname(File.join(remote_bin_dir,relative))
              run "mkdir -p #{remote_key_dir}"
              scp_upload file => File.join(remote_bin_dir,relative)
              #add_param("#{k.upcase}=#{file_base}")
              add_param("#{k.upcase}=#{relative}")
            end
          end
        end
        if remote_list
          summary << "remote #{k}"
          remote_scripts = []
          remote_key_dir = File.join(remote_bin_dir, k.to_s)
          remote_scripts = run_quietly("ls #{remote_key_dir}").split("\n") if run_test("test -d #{remote_key_dir}")
          remote_scripts.each do |scr|
            summary << "  - #{scr}"
          end
        end
        summary << ''
      end

      puts summary.join("\n")
    end


    desc "version", "Return GitDeploy Version"
    def version
      # OPTIMIZE : test local and remote version, invoke hook in case of incompatibility
      require 'git_deploy/version'
      puts GitDeploy::VERSION
    end

    desc "setup", "Create the remote git repository and install push hooks for it"
    method_option :shared, :aliases => '-g', :type => :boolean, :default => true
    method_option :sudo, :aliases => '-s', :type => :boolean, :default => false
    def setup
      sudo = options.sudo? ? "#{sudo_cmd} " : ''

      puts "Checking for project folder on remote ..."
      unless run_test("test -x #{deploy_to}")
        run ["#{sudo}mkdir -p #{deploy_to}"] do |cmd|
          cmd << "#{sudo}chown $USER #{deploy_to}" if options.sudo?
          cmd
        end
      end

      puts "Initializing Git repository on remote ..."
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
      puts "Installing Git Hooks on remote ..."
      hooks_dir = File.join(LOCAL_DIR, 'hooks')
      local_bin_dir = File.join(LOCAL_DIR, 'bin')
      remote_dir = "#{deploy_to}/.git/hooks"
      remote_bin_dir = "#{deploy_to}/.git/bin"

      scp_upload "#{hooks_dir}/post-receive.sh" => "#{remote_dir}/post-receive"
      #scp_upload "#{hooks_dir}/pre-receive.sh" => "#{remote_dir}/pre-receive"
      #run "chmod +x #{remote_dir}/post-receive #{remote_dir}/pre-receive"
      run "chmod +x #{remote_dir}/post-receive"
      #run "rm -rf #{remote_bin_dir}"
      run "mkdir -p #{remote_bin_dir}"
      run "mkdir -p #{remote_bin_dir}/detect"
      run "mkdir -p #{remote_bin_dir}/init"
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
    def rake
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
    def config
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

#      run [] do |cmd|
#        cmd << "cd #{deploy_to}"
#        cmd << "#{remote_bin_dir}/params.sh #{config_opts}"
#      end
      set_param(config_opts)
    end

    no_tasks do
      def set_param(param_cmd = nil)
        remote_bin_dir = "#{deploy_to}/.git/bin"
        run do |cmd|
          cmd << "cd #{deploy_to}"
          cmd << "#{remote_bin_dir}/params.sh #{param_cmd}"
        end
      end

      def add_param(param)
        set_param "add #{param}"
      end

      def load_rbenv(rails_env)
        run "export RAILS_ENV=#{rails_env}; env"
        run "env"
      end
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
