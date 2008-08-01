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
  :description => '获取指定url的http头',
  :regex       => /^curl\s+.+$/,
}) { |body, sender, message| `curl -I #{message}` }

nowa.preset_command({
  :syntax      => 'cstatus <string>',
  :description => '更改机器人的签名',
  :regex       => /^cstatus\s+.+$/,
}) { |body, sender, message| 
  body.status = message
  body.say(body.config[:master], "#{sender}把我的签名改成了：#{message}")
}

nowa.connect