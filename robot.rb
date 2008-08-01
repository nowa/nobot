#!/usr/bin/ruby

require 'lib/nobot'

nowa = Jabber::Nobot::Bot.new({
  :name      => 'nowa.robot',
  :jabber_id => 'nowa.robot@gmail.com',
  :password  => 'nfish677266',
  :master    => ['nowazhu@gmail.com'],
  :presence  => :chat,
  :priority  => 5,
  :status    => 'nowa是我的主人'
})

nowa.preset_command({
  :syntax      => 'curl <url>',
  :description => 'sniffer a server',
  :regex       => /^curl\s+.+$/,
}) { |sender, message| `curl -I #{message}` }

nowa.connect