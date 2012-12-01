sinatra-gcm
===========

Google Cloud Messaging based-on Sinatra framework. This small app lets you manage GCM message via a web interface. This app is also designed to easily deploy and running on heroku

Deploy on Heroku
==========
	
	* Clone this repo
		g clone git@github.com:kureikain/sinatra-gcm.git
	* Create a heroku app.
		cd sinatra-gcm
		heroku apps:create		
			Creating young-reaches-1763... done, stack is cedar
			http://young-reaches-1763.herokuapp.com/ | git@heroku.com:young-reaches-1763.git
			
	* Add MongoLab add-on to your app.
		
		heroku addons:add mongolab:starter
		
	* Register for a Google API Console on. 
		
		https://code.google.com/apis/console/b/0/?pli=1#project:908851335951
		
	* Open welcome.rb, replace your key with my key
		
		set :AUTHORIZE_KEY => 'AIzaSyAU1_3EdDZyKdo8oRY3vWdq3_B2iUblNGg' 
	
	* Commit your change& deploy
		g add welcome.rb
		g commit -m "Update API KEY"
		g push heroku master
	
	* That's it.
		
Using
==========

On your Android code, when handling response from Goole GCM server with registration data, you have to POST to yourapp.heroku.com/register with data in this format {:regId => registration_id_of_device}

Then, on your webui, you can create& send notification to all those devices

		


