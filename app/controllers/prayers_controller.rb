class PrayersController < ApplicationController
  def index
    last = params[:last].blank? ? Time.now.utc + 1.second : Time.parse(params[:last])
    @prayers = Prayer.feed(last)

    respond_to do |format|
      format.js
      format.html # index.html.haml
    end
  end

  def create
    @email = Email.find_or_create_by(email: params[:prayer][:email])
    
    params[:prayer].delete :email
    
    email_me = params[:prayer][:email_me]
    params[:prayer].delete :email_me
    
    params[:prayer][:ip_address] = request.env['REMOTE_ADDR']
    
    @prayer = @email.prayers.build(params[:prayer])
    
    if @prayer.save
      if email_me
        PrayerMailer.permalink_email(@prayer).deliver
      end
    end
  end

  def show
    @prayer = Prayer.find(params[:id])
    @already_prayed_for = (session[:prayed_for] ||= []).include? params[:id]
    @already_reported = (session[:reported] ||= []).include? params[:id]
  end

  def report
    @prayer = Prayer.find(params[:id])
    
    if @prayer.reported >= 2
      @prayer.destroy
    else
      @prayer.inc(:reported, 1)
      if @prayer.save
        (session[:reported] ||= []) << params[:id]
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def prayed_for
    @prayer = Prayer.find(params[:id])
    
    @prayer.inc(:times_prayed_for, 1)
    
    if @prayer.save
      (session[:prayed_for] ||= []) << params[:id]
    end
    
    respond_to do |format|
      format.js
    end
  end
end