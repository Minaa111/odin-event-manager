require 'time'
time = DateTime.strptime('11/25/08 19:21', '%m/%d/%y %H:%M')
day = time.strftime('%A')
puts day
