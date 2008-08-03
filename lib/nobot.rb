require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster'
require "rexml/document"
require 'yaml'
require 'cgi'
require 'iconv'

Jabber::debug = false

module Jabber

  module Nobot
  
    class Logger
      @@debug = true
      
      def Logger.p(log)
        puts log if @@debug
      end
    end
    
    require 'lib/brain'
    require 'lib/net'
    require 'lib/contact'
    
    module DictSpec
      def add_dict_spec(word=nil, mean=nil, sender=nil)
        return unless word or mean
        return [false, "你不是主人，不能覆盖已经存在的词条！"] if @dict_spec["dict_spec"]["#{word}"] and !@config[:master].include?(sender)
        @dict_spec["dict_spec"]["#{word}"] = mean
        dump_dict_spec
        return [true, "添加成功"]
      end
      
      def dump_dict_spec(to='config/dict_spec.yml')
        File.open(to, "w") { |f| YAML.dump(@dict_spec, f)}
      end
    end
  
    class Bot
      include DictSpec
      
      attr_reader :net
      attr_reader :config
      attr_reader :dict_spec
      attr_reader :contacts
      
      def initialize(config)
        @config = config || {}
        if @config[:name].nil? or @config[:name].length == 0
          @config[:name] = @config[:jabber_id].sub(/@.+$/, '')
        end
      
        unless @config[:master].is_a?(Array)
          @config[:master] = [@config[:master]]
        end
      
        @contacts = Contacts.new
        @brain = Brain.new({
          :master => @config[:master]
        })
        @net = Net.new({
          :jabber_id => @config[:jabber_id], 
          :password => @config[:password],
          :presence => @config[:presence],
          :priority => @config[:priority],
          :status => @config[:status],
          :master => @config[:master]
        })
        @net.brain = @brain
        @brain.body = self
        
        @dict_spec = YAML::load( File.open('config/dict_spec.yml') )
        load_config
      end
    
      def born
        @net.connect
      end
    
      def sleep
        @net.disconnect
      end
      
      def reborn
        @net.need_reconnect = true
        @net.wakeup
      end
      
      def load_config
        conf = YAML::load(File.open('config/robot.yml'))
        if conf["robot"]["status"]
          @config[:status] = conf["robot"]["status"]
          self.status = conf["robot"]["status"]
        end
        
        if conf["robot"]["presence"]
          @config[:presence] = conf["robot"]["presence"]
          self.presence = conf["robot"]["presence"]
        end
        
        if conf["robot"]["master"]
          @config[:master] = conf["robot"]["master"].is_a?(Array) ? conf["robot"]["master"] : conf["robot"]["master"].split(',')
        end
        
        if conf["robot"]["name"]
          @config[:name] = conf["robot"]["name"]
        end
      end
      
      def dump_config(to='config/robot.yml')
        File.open(to, "w") { |f| YAML.dump(@config, f)}
      end
      
      def say(to, msg)
        @net.deliver(to, msg)
        return nil
      end
      
      def report(msg)
        @net.deliver(@config[:master], msg)
      end
      
      def preset_command(command, &callback)
        @brain.add_command(command, &callback)
      end
    
      # Sets the bot presence. If you need to set more than just the presence,
      # use presence() instead.
      #
      # Available values for presence are:
      #
      #   * nil   : online
      #   * :chat : free for chat
      #   * :away : away from the computer
      #   * :dnd  : do not disturb
      #   * :xa   : extended away
      #
      def presence=(presence)
        @net.presence(presence, @config[:status], @config[:priority])
      end
    
      # Set the bot priority. Priority is an integer from -127 to 127. If you need
      # to set more than just the priority, use presence() instead.
      def priority=(priority)
        @net.presence(@config[:presence], @config[:status], priority)
      end
    
      # Set the status message. A status message is just a String, e.g. 'I am
      # here.' or 'Out to lunch.' If you need to set more than just the status
      # message, use presence() instead.
      def status=(status)
        @net.presence(@config[:presence], status, @config[:priority])
      end
    end
  
  end

end