var EventViewModel = function() {
	var self = this;

	self.map = null;
	self.marker = null;
	self.infowindow = null;
	self.messagewindow = null;

	self.events = ko.observableArray([]);
	self.markers = [];

	self.newEvent = {
		userId: "",
		title: "",
		description: "",
		createdTime: "",
		startTime: new Date(),
		endTime: new Date(),
		location: {
			latitude: 0,
			longitude: 0
		}
	};

	self.event = ko.mapping.fromJS(self.newEvent);

	self.isEditing = ko.computed(function() {
		return self.event.userId().length > 0;
	}, self);

	self.initMap = function () {
		var california = {lat: 37.4419, lng: -122.1419};
		self.map = new google.maps.Map(document.getElementById('map'), {
			center: california,
			zoom: 13
		});

		self.messagewindow = new google.maps.InfoWindow({
			content: document.getElementById('message')
		});
		
		$('#exampleModal').on('hidden.bs.modal', function () {
			if(!self.isEditing()) {
				self.marker.setMap(null);
				self.marker = null;
			}
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
				google.maps.event.addListener(self.marker, 'click', function() {
					ko.mapping.fromJS(self.newEvent, self.event);
					$('#exampleModal').modal('show');
				});
			}
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
				self.map.setZoom(13);
			}
		});

		self.loadMyEvents();
	}

	self.loadMyEvents = function() {
		for (var i = 0; i < self.markers.length; i++) {
			self.markers[i].setMap(null);
		}
		self.markers = [];

		var input = {
			"action": "MyEvents"
		};
		ajax_post(input).done(function(data) {
			if(data.success == true) {
				self.events(data.events);
				for(n in self.events()) {
					var marker = new google.maps.Marker({
						label: self.events()[n].title,
						position: {
							"lat": self.events()[n].location.latitude, 
							"lng": self.events()[n].location.longitude
						},
						map: self.map,
						draggable: true,
						event: self.events()[n]
					});
					self.markers.push(marker);
					google.maps.event.addListener(marker, 'click', function() {
						ko.mapping.fromJS(this.event, self.event);
						$('#exampleModal').modal('show');
					});
				}
			}
		});
	}

	self.createEvent = function() {
		var unmapped = ko.mapping.toJS(self.event);
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
		ajax_post(data).done(function(returnedData) {
			if(returnedData.success == true) {
				self.loadMyEvents();
			}
		});

		$('#exampleModal').modal('hide');
		//self.infowindow.close();
		//self.message("Saved");
		self.messagewindow.open(self.map, self.marker);
	};

	self.updateEvent = function() {
		var unmapped = ko.mapping.toJS(self.event);
		var marker = self.markers.find(function(m) { return m.event._id == unmapped._id; });
		var data = {
			"action": "UpdateEvent",
			"_id": unmapped._id,
			"title": unmapped.title,
			"description": unmapped.description,
			"startTime": unmapped.startTime,
			"endTime": unmapped.endTime,
			"location": {
				"latitude": marker.position.lat(),
				"longitude": marker.position.lng()
			}
		};
		ajax_post(data).done(function(returnedData) {
			if(returnedData.success == true) {
				self.loadMyEvents();
			}
		});

		$('#exampleModal').modal('hide');
		//self.infowindow.close();
		//self.message("Saved");
		self.messagewindow.open(self.map, self.marker);
	};

	self.deleteEvent = function() {
		var unmapped = ko.mapping.toJS(self.event);
		var data = {
			"action": "DeleteEvent",
			"eventId": self.event._id()
		};
		
		ajax_post(data).done(function(returnedData) {
			if(returnedData.success == true) {
				$('#exampleModal').modal('hide');
				self.loadMyEvents();
			}
		});
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

	
