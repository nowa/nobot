#!/usr/bin/ruby

require 'cgi'
require 'iconv'

converter = Iconv.new('UTF-8', 'GBK')
source = converter.iconv(`curl http://www.imobile.com.cn/search.php?searchkeyword=15858212127&searchcategory=号码地区`)
match = /class="title_txt_pi_none">([0-9\+]+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>/i.match(source)
puts "#{match[1]} #{match[3]} #{match[5]}"