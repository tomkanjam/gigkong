class EventsController < ApplicationController
  # GET /events
  # GET /events.xml
  def index
    @events = Event.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
    end
  end

  def getEventsByIp
    songkick = Songkickr::Remote.new("DodBx8CUdmEW6vg8")
    if Rails.env.production?
      @sk = songkick.events(:location  => "ip:#{@request_ip}", :type => "concert", :page => "1", :per_page => "20") 
    else       
      @sk = songkick.events(:location  => "ip:66.130.248.88", :type => "concert", :page => "1", :per_page => "20")
    end 
  end

  def getEventsByLL(lat, lng)
    songkick = Songkickr::Remote.new("DodBx8CUdmEW6vg8")
    @sk = songkick.events(:location  => "geo:#{lat},#{lng}", :type => "concert", :page => "1", :per_page => "20")    
  end

  def getevents1
    @events = Event.where("city = ?", "Szczecin, Poland")
  end
  
  def getevents
	  @created_at = Time.now
    if request.remote_ip
     @request_ip = request.remote_ip
    else
      @request_ip = "66.130.248.88"
    end
    city = params[:city]
    @location = false


    nest = Nestling.new("SZWVLCI8NOX8MA1DG")
   
    #Check if a city was entered by the user
    if city
     songkick = Songkickr::Remote.new("DodBx8CUdmEW6vg8")
      city_results = songkick.location_search(:query => city).results
      if city_results != [] #Check if city search returned something
        city_results.each do |c|
          if c.lat != nil and c.lng != nil #Save first city result that has a longitude and latitude
            @location = true
            getEventsByLL(c.lat, c.lng)
            break
          end
        end
        if @location == false
          @err_message = "Sorry, we can't get gigs for that city yet but we're working on it"
          getEventsByIp
        end
      else
        @err_message = "Ooops we couldn't find that city"
        getEventsByIp
      end

    #City was not entered by user
    else 
      getEventsByIp   
    end

    @city_name = @sk.results.first.location.city

    @sk.results.each do |e|
      headliner = false
      other_performers_names = ""
      headliner_name = ""

      
      if Event.find_by_sk_id(e.id)
      else
        e.performances.each do |p|
          if headliner == false
			      headliner = true
            headliner_name = p.display_name.gsub(/\\/, '\&\&').gsub(/'/, "''")
          else
            other_performers_names << "#{p.display_name.gsub(/\\/, '\&\&').gsub(/'/, "''")}  "
          end
        end

        venue_name = e.venue.display_name.gsub(/\\/, '\&\&').gsub(/'/, "''")
        start_date = e.start
        sk_id = e.id
        
        begin
          video = nest.artist(headliner_name).video.first.url
        rescue
        end

        begin
          image = nest.artist(headliner_name).images.first.url
        rescue
        end

	      @event = Event.create(:headliner => headliner_name, :other_performers_names => other_performers_names, :start_date => start_date, :venue_name => venue_name, :video => video, :sk_id => e.id, :city => @city_name, :image => image)   
          
      end 
    end
    
    @events = Event.where("city = ? and start_date >= ?", @city_name, Time.now).limit(10)
	  

    #redirect_to "/"
	  #render 'pages/home'
  end

  # GET /events/1
  # GET /events/1.xml
  def show
    @event = Event.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/new
  # GET /events/new.xml
  def new
    @event = Event.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  # GET /events/1/edit
  def edit
    @event = Event.find(params[:id])
  end

  # POST /events
  # POST /events.xml
  def create
    @event = Event.new(params[:event])

    respond_to do |format|
      if @event.save
        format.html { redirect_to(@event, :notice => 'Event was successfully created.') }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /events/1
  # PUT /events/1.xml
  def update
    @event = Event.find(params[:id])

    respond_to do |format|
      if @event.update_attributes(params[:event])
        format.html { redirect_to(@event, :notice => 'Event was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.xml
  def destroy
    @event = Event.find(params[:id])
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
    end
  end
end
