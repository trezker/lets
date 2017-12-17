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

	self.log_in = function() {
		$(self.iFrameDOM.find("input")[0]).sendkeys("a");
		$(self.iFrameDOM.find("input")[1]).sendkeys("a");

		wait(1).then(() => {
			$(self.iFrameDOM.find("button")[1]).click();
			wait(1000).then(() => {
				assertElementExists("[data-bind='click: sign_out']");
			});
		});
	}
};

function iframeLoaded() {
	var suite = new TestSuite();
	suite.log_in();
}

$("#test").attr("src", "/");
