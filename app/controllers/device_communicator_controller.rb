class DeviceCommunicatorController < ApplicationController

  def return_object

    @object = "return"
    respond_to do |format|

      if request.get?
        format.json { render :json => @object }
      else
        format.html
        format.xml { render :xml => @object }
      end

    end

  end

end
