#!/usr/bin/env ruby
require 'rubygems'
require 'jabber/bot'

# Create a public Jabber::Bot
bot = Jabber::Bot.new(
  :jabber_id => 'nowa.robot@gmail.com', 
  :password  => 'nfish677266', 
  :master    => 'nowazhu@gmail.com',
  :is_public => true
)

# Give your bot a public command
bot.add_command(
  :syntax      => 'rand',
  :description => 'Produce a random number from 0 to 10',
  :regex       => /^rand$/,
  :is_public   => true
) { rand(10).to_s }

# Give your bot a private command with an alias
bot.add_command(
  :syntax      => 'puts <string>',
  :description => 'Write something to $stdout',
  :regex       => /^puts\s+.+$/,
  :alias       => [ 
      :syntax => 'p <string>', 
      :regex => /^p\s+.+$/
  ]
) do |sender, message|
  puts message
  "'#{message}' written to $stdout"
end

# Bring your new bot to life
bot.connect