require_relative './../cm_challenge/api.rb'

class HomeController < ApplicationController
  
  def initialize
    # Created a variable that return the absences array and the members array
    @dbData = CmChallenge::Api.new().singleton_class
    @allAbsences = @dbData.absences
    @allMembers = @dbData.members

    #Creating instance of the class that converts the events to the iCal file
    @toIcal = CmChallenge::Absences.new()

    # Variables to select the vacation absences and the sickness absences
    @vacation = filterArray(@allAbsences, "vacation")
    @sickness = filterArray(@allAbsences, "sickness")

    #Creating a variable to be used in the single page employee
    #the first item in the array is the data about the employee and the second is the absences that he/she had
    @singleEmployee = []

    #Variable to select wich absences are in the period passed by the user
    @rangeDateAbsences = []
    #Variable with the range date passed by the user, to show in the range date page
    @selectedDates = []

    # Throwing an exception when ther parameters are not permitted
    ActionController::Parameters.action_on_unpermitted_parameters = :raise
    super
  end

  # Main page
  def index
    begin
      # Checking the params
      # If some param is not permitted, then an exception is thrown and handled below
      readParams = params.permit(:userId, [:startDate, :endDate]) #the parameter are optional, so require is not necessary
      # If the params is equal to 0, that means that the user went to localhost:3000 only
      if readParams.to_hash.size == 0
        download_ical #Download the file
      else
        # Checking if the param is the userId
        if readParams.include?(:userId)
          ## Call the method to select the data of the specific employee
          if selectOneEmployee(params[:userId]) # If the user is found
            render 'single-employee-page'       # Render the page
          end
        # If one of the date params were passed, then both must be passed  
        elsif params.include?(:startDate) && params.include?(:endDate)
          if selectRangeDate(params[:startDate], params[:endDate]) #if the dates are valid
            render 'range-date-page'  #render the range-date-page
          end
        else  #if only one of the dates params were passed, then render the home page
          render 'home' 
        end
      end
    rescue
      # the exception is handle here
      # with an alert
      render html: "<script>alert('No parameters found')</script>".html_safe #warning to the user in case of no match found for that id 
    end 
  end

  def home
  end

  # Method to send the ical file to the user
  def download_ical
    # Method inside the class Absences that generates the ical file, based on the absences
    @toIcal.to_ical(@allAbsences, @allMembers)
    # Sending the file that was generated by the method above
    send_file "#{Rails.root}/public/docs/ical.icb", content_type: 'text/icb',x_sendfile: true
  end

  #Method to select the absences of a specific employee
  def selectOneEmployee (id)
    #Finding the member data
    memberAuxiliar = @allMembers.select do |item|
      item[:user_id].to_s == id.to_s
    end
    # If no member has the id passed, then the count method will return 0
    if memberAuxiliar.count > 0 # will enter only if a member was found
      @singleEmployee.push(memberAuxiliar.first) #saving the member data in the first item of the array

      #Finding the absences of that member
      absenceAuxiliar = @allAbsences.select do |absence|
        absence[:user_id].to_s == id.to_s
      end
      ## Adding the array data of absences of that user found, in the variable that will be displayed in the single-employee-page
      @singleEmployee.push(absenceAuxiliar)
      true 
    else 
      render html: "<script>alert('No match to the user Id')</script>".html_safe #warning to the user in case of no match found for that id 
      false 
    end
  end

  # This method will return true if the absence date is within the range that was passed by the user
  def selectRangeDate (start, endD)
    begin
      #parsing the dates
      startDateParsed = d(start)
      endDateParsed = d(endD)
      # If there is an error in parsing the dates, an exception is thrown
      if startDateParsed > endDateParsed #not possible, because startDate has to be older than endDate
        render html: "<script>alert('Range date is invalid, startDate newer than endDate')</script>".html_safe #warning to the user in case of the dates were inverted
        false #return false
      else 
        # Since the dates are valid, then continue the code to verify the range date, and select the correct absences
        @selectedDates = [start,endD] #Save the start_date and the end_date in this variable, to be displayed in the range-date-page
        @rangeDateAbsences = @allAbsences.select do |item|
          startDateParsed < d(item[:start_date]) && d(item[:start_date]) < endDateParsed && d(item[:end_date]) < endDateParsed #the method d is below
        end
        true #return true
      end
    rescue #Handling the exception, in case Date.parse fails
      render html: "<script>alert('The dates are not valid')</script>".html_safe #warning to the user in case of no match found for that id 
      false #returning false
    end 
  end

  #method create to decrease the length of the line in the previous method, but only returns the date parsed
  def d (date)
    Date.parse(date)
  end

  # Method to avoid code duplication, can be used to return a array with the :type speficied
  def filterArray (array_absences, type_absence)
    array_absences.select do |absence|
      absence[:type] == type_absence.to_s
    end
  end
end