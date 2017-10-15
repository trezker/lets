var EventViewModel = function() {
	var self = this;

	self.map = null;
	self.marker = null;
	self.infowindow = null;
	self.messagewindow = null;

	self.initMap = function () {
		var california = {lat: 37.4419, lng: -122.1419};
		self.map = new google.maps.Map(document.getElementById('map'), {
			center: california,
			zoom: 13
		});

		self.infowindow = new google.maps.InfoWindow({
			content: document.getElementById('form')
		});

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
				self.infowindow.open(self.map, self.marker);
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
	}

	self.saveData = function () {
		var name = escape(document.getElementById('name').value);
		var address = escape(document.getElementById('address').value);
		var type = document.getElementById('type').value;
		var latlng = self.marker.getPosition();
		var url = 'phpsqlinfo_addrow.php?name=' + name + '&address=' + address +
		'&type=' + type + '&lat=' + latlng.lat() + '&lng=' + latlng.lng();

		self.infowindow.close();
		self.messagewindow.open(self.map, self.marker);
	}
};

var eventViewModel = new EventViewModel()
ko.applyBindings(eventViewModel, document.getElementById('content'));

var initMap = function() {
	eventViewModel.initMap();
}

ajax_text('/source/text/googleapikey.txt').done(function(data) {
	$("body").append('<script async defer src="https://maps.googleapis.com/maps/api/js?key=' + data + '&libraries=places&callback=initMap"></script>');
});

	
