function assertElementExists(selector) {
	if($("iframe#test").contents().find(selector).length == 0) {
		console.log(new Error("Element not found. Selector = " + selector));
	}
}

function wait(milliseconds) {
	return new Promise((resolve, reject) => {
		setTimeout(function() {
			resolve();
		}, milliseconds);
	});
}

var TestSuite = function() {
	var self = this;
	self.iFrameDOM = $("iframe#test").contents();

	self.run = function() {
		self.log_in().then(() => {
			//TODO: Teardown
		});
	};

	self.log_in = function() {
		return new Promise((resolve, reject) => {
			$(self.iFrameDOM.find("input")[0]).sendkeys("a");
			$(self.iFrameDOM.find("input")[1]).sendkeys("a");

			wait(1).then(() => {
				$(self.iFrameDOM.find("button")[1]).click();
				return wait(1000);
			}).then(() => {
				assertElementExists("[data-bind='click: sign_out']");
				resolve();
			});
		});
	}
};

function iframeLoaded() {
	var suite = new TestSuite();
	suite.run();
}

$("#test").attr("src", "/");
