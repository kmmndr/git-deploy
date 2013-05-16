module GitDeploy
  module SSHMethods
    private
    SHELLS = [{ name: 'bash', command: 'bash -i -l' }]


    def sudo_cmd
      "sudo -p 'sudo password: '"
    end

    def system(*args)
      puts "[local] $ " + args.join(' ').gsub(' && ', " && \\\n  ")
      super unless options.noop?
    end

    def run_with_env(cmd = nil, shell = SHELLS[0][:name], &block)
      run cmd, shell, &block
    end

    def run_quietly(command = nil, shell = nil, opts = {})
      run(command, shell, opts.merge(:silent => true))
    end

    def run(command = nil, shell = nil, opts = {})
      cmds = command.is_a?(Array) ? command : [command]
      cmds = yield(cmds) if block_given?
      cmd = cmds.compact.join(' && ')

      puts "[#{options[:remote]}] $ " + cmd.gsub(' && ', " && \\\n  ") unless opts[:silent]

      unless options.noop?
        #status, output = ssh_exec cmd do |ch, stream, data|
        status, output = ssh_exec cmd, shell do |ch, stream, data|
          case stream
          when :stdout then $stdout.print data unless opts[:silent]
          when :stderr then $stderr.print data unless opts[:silent]
          end
          ch.send_data(askpass) if data =~ /^sudo password: /
        end
        output
      end
    end

    def run_test(cmd)
      status, output = ssh_exec(cmd) { }
      status == 0
    end

    def ssh_exec(cmd, shell=nil, &block)
      status = nil
      output = ''

      shell_idx = SHELLS.index { |sh| sh[:name] == shell }
      real_cmd = shell.nil? || shell_idx.nil? ? cmd : SHELLS[shell_idx][:command]

      #real_cmd = (shell.nil? ? cmd : shell)

      channel = ssh_connection.open_channel do |chan|
        chan.exec(real_cmd) do |ch, success|
          raise "command failed: #{real_cmd.inspect}" unless success
          #ch.request_pty
          unless shell_idx.nil?
            #ch.send_data "export TERM=vt100\n"

            # Output each command as if they were entered on the command line
            #[cmd].flatten.each do |command|
            #  ch.send_data "#{command}\n"
            #end
            # Output command as if it was entered on the command line
            ch.send_data "#{cmd}\n"

            # Remember to exit or we'll hang!
            ch.send_data "exit\n"
          end


          ch.on_data do |c, data|
            output << data
            yield(c, :stdout, data)
          end

          ch.on_extended_data do |c, type, data|
            output << data
            yield(c, :stderr, data)
          end

          ch.on_request "exit-status" do |ch, data|
            status = data.read_long
          end
        end
      end

      channel.wait
      [status, output]
    end

    # TODO: use Highline for cross-platform support
    def askpass
      tty_state = `stty -g`
      system 'stty raw -echo -icanon isig' if $?.success?
      pass = ''
      while char = $stdin.getbyte and not (char == 13 or char == 10)
        if char == 127 or char == 8
          pass[-1,1] = '' unless pass.empty?
        else
          pass << char.chr
        end
      end
      pass
    ensure
      system "stty #{tty_state}" unless tty_state.empty?
    end

    def scp_upload(files)
      channels = []
      files.each do |local, remote|
        puts "FILE: [local] #{local.sub(LOCAL_DIR + '/', '')}  ->  [#{options[:remote]}] #{remote}"
        #channels << ssh_connection.scp.upload(local, remote) unless options.noop?
        channels << ssh_connection.scp.upload(local, remote, :recursive => true) unless options.noop?
      end
      channels.each { |c| c.wait }
    end

    def ssh_connection
      @ssh ||= begin
        begin
          ssh = Net::SSH.start(host, remote_user, :port => remote_port)
          at_exit { ssh.close }
        rescue Net::SSH::AuthenticationFailed
          puts "You need to have an ssh key for #{remote_user}@#{host}:#{remote_port}"
          exit
        end

        ssh
      end
    end
  end
end
