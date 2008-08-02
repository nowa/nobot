# 为brain提供预设命令支持

module Jabber
  
  module Nobot
    
    module Command
      # Say 'puts foo' or 'p foo' and 'foo' will be written to $stdout.
      #   # The bot will also respond with "'foo' written to $stdout."
      #   add_command(
      #     :command     => 'puts',
      #     :syntax      => 'puts <string>',
      #     :description => 'Write something to $stdout',
      #     :regex       => /^puts\s+.+$/,
      #     :alias       => [ :command => 'p', :syntax => 'p <string>', :regex => /^p\s+.+$/ ]
      #   ) do |body, sender, message|
      #     puts "#{sender} says #{message}."
      #     "'#{message}' written to $stdout."
      #   end
      # 
      #   # 'puts!' is a non-responding version of 'puts', and has two aliases,
      #   # 'p!' and '!'
      #   add_command(
      #     :command     => 'puts!',
      #     :syntax      => 'puts! <string>',
      #     :description => 'Write something to $stdout (without response)',
      #     :regex       => /^puts!\s+.+$/,
      #     :alias       => [ 
      #       { :command => 'p!', :syntax => 'p! <string>', :regex => /^p!\s+.+$/ },
      #       { :command => '!', :syntax => '! <string>', :regex => /^!\s+/.+$/ }
      #     ]
      #   ) do |body, sender, message|
      #     puts "#{sender} says #{message}."
      #     nil
      #   end
      def add_command(command, &callback)
        name = command[:command]

        # Add the command meta - used in the 'help' command response.
        add_command_meta(name, command)

        # Add the command spec - used for parsing incoming commands.
        add_command_spec(command, callback)

        # Add any command aliases to the command meta and spec
        unless command[:alias].nil?
          command[:alias].each { |a| add_command_alias(name, a, callback) }
        end
      end

      # Returns an Array of masters
      def master
        @config[:master]
      end

      # Returns +true+ if the given Jabber id is a master, +false+ otherwise.
      def master?(jabber_id)
        @config[:master].include? jabber_id
      end

      private

        # Extract the command name from the given syntax
        def command_name(syntax)
          if syntax.include? ' '
            syntax.sub(/^(\S+).*/, '\1')
          else
            syntax
          end
        end

        # Add a command alias for the given original +command_name+
        def add_command_alias(command_name, alias_command, callback) #:nodoc:
          original_command = @commands[:meta][command_name]
          original_command[:syntax] << alias_command[:syntax]

          alias_name = alias_command[:command]

          add_command_meta(alias_name, original_command, true)
          add_command_spec(alias_command, callback)
        end

        # Add a command meta
        def add_command_meta(name, command, is_alias=false) #:nodoc:
          syntax = command[:syntax]

          @commands[:meta][name] = {
            :syntax      => syntax.is_a?(Array) ? syntax : [syntax],
            :description => command[:description],
            :is_alias    => is_alias
          }
        end

        # Add a command spec
        def add_command_spec(command, callback) #:nodoc:
          @commands[:spec] << {
            :regex     => command[:regex],
            :callback  => callback
          }
        end

        # Returns the default help message describing the bot's command repertoire.
        # Commands are sorted alphabetically by name, and are displayed according
        # to the bot's and the commands's _public_ attribute.
        def help_message(body, sender, command_name) #:nodoc:
          if command_name.nil? or command_name.length == 0
            # Display help for all commands
            help_message = "我可以执行以下预设命令:\n\n"

            @commands[:meta].sort.each do |command|
              # Thank you, Hash.sort
              command = command[1]

              if !command[:is_alias]
                # command[:syntax].each { |syntax| help_message += "#{syntax}\t" }
                help_message += command[:syntax].join("\n")
                help_message += "\t #{command[:description]}\n"
              end
            end
          else
            # Display help for the given command
            command = @commands[:meta][command_name]

            if command.nil?
              help_message = "'#{command_name}' 不是预设的命令，你可以尝试跟我说" +
                  " 'help' 来获得所有预设命令。"
            else
              help_message = ''
              command[:syntax].each { |syntax| help_message += "#{syntax}\n" }
              help_message += "  #{command[:description]} "
            end
          end

          help_message
        end

        # Parses the given command message for the presence of a known command by
        # testing it against each known command's regex. If a known command is
        # found, the command parameters are passed on to the callback block, minus
        # the command trigger. If a String result is present it is delivered to the
        # sender.
        #
        # If the bot has not been made public, commands from anyone other than the
        # bot master(s) will be silently ignored.
        def parse_command(sender, message) #:nodoc:
          is_master = master? sender

          # 退出处理
          if message.strip == 'exit!' && is_master
            @body.say(sender, 'Exiting...')
            @body.net.wakeup
            return
          end

          @commands[:spec].each do |command|
            # if command[:is_public] or is_master
              unless (message.strip =~ command[:regex]).nil?
                params = nil

                if message.include? ' '
                  params = message.sub(/^\S+\s+(.*)$/, '\1')
                end

                response = command[:callback].call(@body, sender, params)
                @body.say(sender, response) unless response.nil?

                return
              end
            # end
          end
          
          cmd_name = command_name(message)
          if @commands[:meta][cmd_name]
            begin
              @body.say(sender, "那个，你给我的指令格式貌似不对，正确的好像是这样的：\n\n" + @commands[:meta][cmd_name][:syntax].first + "\n" + @commands[:meta][cmd_name][:description])
            rescue Exception => e
              Logger.p "#{e}"
            end
            return
          end

          response = "'#{message.strip}' 不是预设的命令，你可以尝试跟我说" +
              " 'help' 来获得所有预设命令。"
          @body.say(sender, response)
        end
    end
    
  end
  
end