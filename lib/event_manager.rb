require 'csv'

require 'google/apis/civicinfo_v2'

require 'erb'

require 'time'



puts 'Event Manager Initialized!'

# declare global variables for most active hours

$most_active_hours = {}



def clean_zipcode(zipcode)

  zipcode.to_s.rjust(5, '0')[0..4]

end



def legislators_by_zipcode(zip)

  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new

  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'



  begin

    legislators = civic_info.representative_info_by_address(address: zip, levels: 'country',

                                                            roles: %w[legislatorUpperBody legislatorLowerBody])

    legislators = legislators.officials

    legislator_names = legislators.map(&:name)

    legislator_names.join(', ')

  rescue StandardError

    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'

  end

end



def save_thank_you_letter(id, form_letter)

  Dir.mkdir('output') unless Dir.exist?('output')

  file_name = "output/thanks_#{id}.html"



  File.open(file_name, 'w') do |file|

    file.puts(form_letter)

  end

end



def clean_phone_number(phone_number)

  phone_number = phone_number.gsub!(/[a-zA-Z()+,.-]/, '') if phone_number.match?(/[a-zA-Z()+,.-]/)

  phone_number = phone_number.delete(' ')

  phone_number = phone_number.ljust(10, '0') if phone_number.length < 10

  phone_number = phone_number[1..10] if phone_number.length == 11 && phone_number[0] == '1'

  phone_number = phone_number[0..9] if phone_number.length == 11 && phone_number[0] != '1' || phone_number.length > 11

  phone_number

end



def get_active_hours(time)

  acive_time = time.hour

  if $most_active_hours[acive_time].nil?

    $most_active_hours[acive_time] = 1

  else

    $most_active_hours[acive_time] += 1

  end

end



class DateTimeExtractor

  @@active_hours = {}

  @@active_days = {}



  def self.get_active_hours(time)

    active_time = time.hour

    if @@active_hours[active_time].nil?

      @@active_hours[active_time] = 1

    else

      @@active_hours[active_time] += 1

    end

  end



  def self.get_active_weekdays(date)

    acive_day = date.strftime('%a')

    if @@active_days[acive_day].nil?

      @@active_days[acive_day] = 1

    else

      @@active_days[acive_day] += 1

    end

  end



  def self.most_active_hours

    max_value = @@active_hours.values.max

    puts max_value

    most_active_hours = Hash[@@active_hours.select { |_k, v| v == max_value }]

    puts "Most active hours are #{most_active_hours.keys}"

    most_active_hours

  end



  def self.most_active_weekdays

    max_value = @@active_days.values.max

    puts max_value

    most_active_weekdays = Hash[@@active_days.select { |_k, v| v == max_value }]

    puts "Most active hours are #{most_active_weekdays.keys}"

    most_active_weekdays

  end

end

template_letter = File.read('form_letter.html')

erb_template = ERB.new template_letter



# Read the file line by line

lines = CSV.open('event_attendees.csv',

                 headers: true,

                 header_converters: :symbol)

lines.each do |row|

  # name = row[:first_name]

  # zipcode = clean_zipcode(row[:zipcode])



  # legislators = legislators_by_zipcode(zipcode)



  # form_letter = erb_template.result(binding)



  # save_thank_you_letter(id, form_letter)

  # puts form_letter

  # clean the phone number

  # phone_number = clean_phone_number(row[:homephone])



  date_time = row[:regdate].split(' ')

  date_array = date_time[0].split('/')



  date_array[2] = '20' + date_array[2]

  date = Date.strptime(date_array.join('-'), '%m-%d-%Y')

  time = Time.parse(date_time[1])



  DateTimeExtractor.get_active_hours(time)

  DateTimeExtractor.get_active_weekdays(date)

end



puts DateTimeExtractor.most_active_hours

puts DateTimeExtractor.most_active_weekdays

