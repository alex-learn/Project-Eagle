require "net/http"
require "net/https"

class Reservation < ActiveRecord::Base
  
  DEFAULT_CC_NUM = "4217639662603493"  
  DEFAULT_CC_YEAR = "15"
  DEFAULT_CC_MONTH = "11"

  
  belongs_to :course
  belongs_to :user

  validates_numericality_of :golfers, :greater_than => 1, :less_than => 5, :message => "Invalid number of golfers"
  
  Reservation::BOOKING_CANCEL_STATUS_CODE   = 0
  Reservation::BOOKING_SUCCESS_STATUS_CODE  = 1  
  
  # Book reservation record, creates a Reservation record, connects to user
  # INPUT:   
  # OUTPUT:   

  def self.book_tee_time(email, course_id, golfers, time, date)
    reservation_info = {:course_id=>course_id, :golfers=>golfers, :time=>time, :date=>date}
    
    # Make the API reservation call here
    u = User.find_by_email(email)
    booking = book_time_via_api(reservation_info,u)
    if XmlSimple.xml_in(booking.body).has_key?("confirmation")
      confirmation_code = XmlSimple.xml_in(booking.body)["confirmation"][0]
      
      logger.info "Confirmation Code: "+confirmation_code 
    else
      return nil
    end    
    #
    
    if booking
      u = User.find_by_email(email)
      if u 
        r = Reservation.create(reservation_info.merge({:booking_type=>u.device_name,:confirmation_code=>confirmation_code,:user=>u}))
        #r.booking_type = u.device_name
        #r.confirmation_code = confirmation_code
        #r.user = u
        #r.save
      else 
        logger.info "Did not find a user record with the email #{email}"
        return nil 
      end
    
      if r.save; return r else return nil end
    else
      logger.info "Did not successfully book reservation via API"
      return nil
    end  
  end 
  
  # Book reservation through course's reservation system via corresponding API, as defined in Course model
  # INPUT: http://dump-them.appspot.com/cgi-bin/bk.pl?CourseID=1&Date=2011-12-19&Time=06:08&Email=arjun.vasan@gmail.com&Quantity=2&AffiliateID=029f2fw&Password=eagle  
  # OUTPUT:  
  
  def self.book_time_via_api(reservation_info,u)
    
    case reservation_info[:course_id]

    
    when Course::DEEP_CLIFF_COURSE_ID
      puts "Course ID:" + reservation_info[:course_id]
      puts "Course ID 2:" + Course::DEEP_CLIFF_COURSE_ID
      logger.info "Returning Booking Response"
      return book_time_via_fore_reservations_api(reservation_info,u)
    when Course::SOME_OTHER_COURSE_ID 
      puts "Course ID:" + reservation_info[:course_id]
      puts "Course ID 2:" + Course::DEEP_CLIFF_COURSE_ID
      # Call function corresponding to the courses API
    else
      puts "Course ID:" + reservation_info[:course_id]
      puts "Course ID 2:" + Course::DEEP_CLIFF_COURSE_ID
      logger.info "Did not find a valid course with specified course_id in book_time_via_api function"
      return nil
    end      
    
  end  
  
  #IMPLEMENT: Move this to a separate module file for all Fore API calls.  Every API should have it's own module
  #SAMPLE: response = http.post("http://dump-them.appspot.com/cgi-bin/bk.pl?CourseID=1&Date=2011-12-19&Time=06:08&Email=arjun.vasan@gmail.com&Quantity=2&AffiliateID=029f2fw&Password=eagle", headers)
  
  def self.book_time_via_fore_reservations_api(reservation_info,u)
    uri = "#{Course::DEEP_CLIFF_API_URL}?CourseID=#{reservation_info[:course_id]}&Date=#{reservation_info[:date]}&Time=#{reservation_info[:time]}&EMail=pressteex@gmail.com&FirstName=#{u[:f_name]}&LastName=#{u[:l_name]}&ExpMnth=#{DEFAULT_CC_MONTH}&ExpYear=#{DEFAULT_CC_YEAR}&CreditCard=#{DEFAULT_CC_NUM}&Phone=5628884454&Quantity=#{reservation_info[:golfers]}&AffiliateID=#{Course::DEEP_CLIFF_API_AFFILIATE_ID}&Password=#{Course::DEEP_CLIFF_API_PASSWORD}"
    puts uri
    url = URI.parse(Course::DEEP_CLIFF_API_HOST)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    headers = {}

    begin
      response = http.get(uri, headers)
    rescue
      return nil
    end
    
    if response; return response else return nil end    
  end
     
end
