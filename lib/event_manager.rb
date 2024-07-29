require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.split('')
  digits = ('0'..'9')
  clean_phone_number = ''

  phone_number.each do |character|
    clean_phone_number += character if digits.include? character
  end

  if clean_phone_number.length == 10
    clean_phone_number
  elsif clean_phone_number.length == 11 && clean_phone_number[0] == '1'
    clean_phone_number[1..-1]
  else
    clean_phone_number + ' (invalid phone number)'
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def peak_reg_hour(reg_dates)
  reg_per_hour = Hash.new(0)

  reg_dates.each do |reg_date|
    time = DateTime.strptime(reg_date, '%m/%d/%y %H:%M')
    hour = time.hour
    reg_per_hour[hour] += 1
  end

  reg_per_hour.max_by { |_key, value| value }
end

def peak_reg_day(reg_dates)
  reg_per_day = Hash.new(0)

  reg_dates.each do |reg_date|
    time = DateTime.strptime(reg_date, '%m/%d/%y %H:%M')
    day = time.strftime('%A')
    reg_per_day[day] += 1
  end

  reg_per_day.max_by { |_key, value| value }
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

reg_dates = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  reg_dates << row[:regdate]

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
peak_reg_hour = peak_reg_hour(reg_dates)
peak_reg_day = peak_reg_day(reg_dates)
puts "Peak registration hour was around #{peak_reg_hour[0]}:00 with #{peak_reg_hour[1]} registrations."
puts "Peak registration day was #{peak_reg_day[0]} with #{peak_reg_day[1]} registrations."
