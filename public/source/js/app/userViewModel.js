var userViewModel = function() {
	var self = this;
	self.sign_out = function() {
		var data = {};
		data.action = "Logout";
		ajax_post(data, function(returnedData) {
		    if(returnedData.success == true) {
	    		window.location.href = window.location.href;
		    }
		});
	};

	self.my_events = function() {

	}
};

ko.applyBindings(new userViewModel(), document.getElementById('header'));