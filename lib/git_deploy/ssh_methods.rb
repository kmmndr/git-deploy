class GitDeploy
  module SSHMethods
    private

    def sudo_cmd
      "sudo -p 'sudo password: '"
    end

    def system(*args)
      puts "[local] $ " + args.join(' ').gsub(' && ', " && \\\n  ")
      super unless options.noop?
    end

    def run(cmd = nil)
      cmd = yield(cmd) if block_given?
      cmd = cmd.join(' && ') if Array === cmd
      puts "[#{options[:remote]}] $ " + cmd.gsub(' && ', " && \\\n  ")

      unless options.noop?
        #status, output = ssh_exec cmd do |ch, stream, data|
        status, output = ssh_shell_exec cmd do |ch, stream, data|
          case stream
          when :stdout then $stdout.print data
          when :stderr then $stderr.print data
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

    def ssh_shell_exec(cmd, shell='bash', &block)
      ssh_exec(cmd, "bash -i -l", &block)
    end

    def ssh_exec(cmd, shell=nil, &block)
      status = nil
      output = ''

      real_cmd = (shell.nil? ? cmd : shell)

      channel = ssh_connection.open_channel do |chan|
        chan.exec(real_cmd) do |ch, success|
          raise "command failed: #{real_cmd.inspect}" unless success
          ch.request_pty
          unless shell.nil?
puts "exporting TERM"
            ch.send_data "export TERM=vt100\n"

            # Output each command as if they were entered on the command line
            #[cmd].flatten.each do |command|
            #  ch.send_data "#{command}\n"
            #end
            # Output command as if it was entered on the command line
puts "executing CMD"
            ch.send_data "#{cmd}\n"

            # Remember to exit or we'll hang!
puts "exiting"
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
        ssh = Net::SSH.start(host, remote_user, :port => remote_port)
        at_exit { ssh.close }
        ssh
      end
    end
  end
end
