require 'lib/command'
require 'lib/propriety'

# 机器人的大脑
module Jabber
  
  module Nobot

    class Brain
      include Command
      include BuiltInCommand
      include Propriety
      attr_accessor :body
  
      def initialize(config)
        @config = config || {}
        @received = 'born'
        @sender = @config[:master]
  
        @commands = { :spec => [], :meta => {} }
        add_command(
          :command     => 'help',
          :syntax      => 'help [command]',
          :description => '返回指定命令的帮助信息或所有可用命令列表',
          :regex => /^help(\s+?.+?)?$/,
          :alias => [ {:command => '?', :syntax => '? [command]', :regex  => /^\?(\s+?.+?)?$/}, {:command => '？', :syntax => '？ [command]', :regex  => /^？(\s+?.+?)?$/} ]
        ) { |body, sender, message| help_message(body, sender, message) }
      end

      def dispatch
        parse_command(@sender, @received)
      end
      
      def saw(pres)
        if pres.type == :unavailable
          @body.contacts.remove(pres.from.to_s.sub(/\/.+$/, ''))
        else
          @body.contacts.add(pres)
          when_saw(pres)
        end
      end

      def hear(msg, from)
        Logger.p "#{from}: #{msg}"
        @received = msg
        @sender = from
        # @body.say(from, 'I heard.')

        dispatch
      end
    end
    
  end
  
end