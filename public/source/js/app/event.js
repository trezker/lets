var EventViewModel = function() {
	var self = this;

	self.map = null;
	self.marker = null;
	self.infowindow = null;
	self.messagewindow = null;

	self.events = ko.observableArray([]);
	self.markers = [];

	self.newEvent = {
		title: "asd",
		description: "sdf",
		createdTime: "",
		startTime: "",
		endTime: "",
		location: {
			latitude: 0,
			longitude: 0
		}
	};

	self.event = ko.mapping.fromJS(self.newEvent);

	self.initMap = function () {
		var california = {lat: 37.4419, lng: -122.1419};
		self.map = new google.maps.Map(document.getElementById('map'), {
			center: california,
			zoom: 13
		});

		/*
		self.infowindow = new google.maps.InfoWindow({
			content: document.getElementById('form')
		});
		*/
		self.messagewindow = new google.maps.InfoWindow({
			content: document.getElementById('message')
		});

		google.maps.event.addListener(self.map, 'click', function(event) {
			if(self.marker) {
				self.marker.setPosition(event.latLng);
			}
			else {
				self.marker = new google.maps.Marker({
					position: event.latLng,
					map: self.map,
					draggable: true
				});
			}

			google.maps.event.addListener(self.marker, 'click', function() {
				$('#exampleModal').modal('show');
				//self.infowindow.open(self.map, self.marker);
			});
		});

		var input = document.getElementById('search');

		var autocomplete = new google.maps.places.Autocomplete(input);

		autocomplete.addListener('place_changed', function() {
			var place = autocomplete.getPlace();
			if (!place.geometry) {
				// User entered the name of a Place that was not suggested and
				// pressed the Enter key, or the Place Details request failed.
				window.alert("No details available for input: '" + place.name + "'");
				return;
			}

			// If the place has a geometry, then present it on a map.
			if (place.geometry.viewport) {
				self.map.fitBounds(place.geometry.viewport);
			} else {
				self.map.setCenter(place.geometry.location);
				self.map.setZoom(17);  // Why 17? Because it looks good.
			}
		});

		var input = {
			"action": "MyEvents"
		};
		ajax_post(input, function(data) {
			if(data.success == true) {
				self.events(data.events);
				for(n in self.events()) {
					self.markers.push(new google.maps.Marker({
						position: {
							"lat": self.events()[n].location.latitude, 
							"lng": self.events()[n].location.longitude
						},
						map: self.map,
						draggable: true
					}));
				}
			}
		});
	}

	self.createEvent = function() {
		var unmapped = ko.mapping.toJS(self.event);
		console.log(unmapped);
		var data = {
			"action": "CreateEvent",
			"title": unmapped.title,
			"description": unmapped.description,
			"startTime": unmapped.startTime,
			"endTime": unmapped.endTime,
			"location": {
				"latitude": self.marker.position.lat(),
				"longitude": self.marker.position.lng()
			}
		};
		ajax_post(data, function(returnedData) {
			console.log(returnedData);
			if(returnedData.success == true) {
			}
		});

		$('#exampleModal').modal('hide');
		//self.infowindow.close();
		self.messagewindow.open(self.map, self.marker);
	};

	self.goToEvent = function(event) {
		self.map.setCenter({
			"lat": event.location.latitude, 
			"lng": event.location.longitude
		});
		self.map.setZoom(17);
	};
};

var eventViewModel = new EventViewModel()
ko.applyBindings(eventViewModel, document.getElementById('content'));

var initMap = function() {
	eventViewModel.initMap();
}

ajax_text('/source/text/googleapikey.txt').done(function(data) {
	$("body").append('<script async defer src="https://maps.googleapis.com/maps/api/js?key=' + data + '&libraries=places&callback=initMap"></script>');
});

	
